#!/usr/bin/env python3
"""
Run Vampire, E and Twee on TPTP Horn problems and translate each proof with Taelja.

Usage
  python eval.py <tptp_dir> [options]

  tptp_dir          TPTP directory (contains Problems/)
  --vampire PATH    Vampire binary
  --eprover PATH    E binary
  --twee PATH       Twee binary. Each prover is the path given, else
                    $TAELJA_VAMPIRE, $TAELJA_EPROVER or $TAELJA_TWEE, else
                    bin/<name> in this repository, else on the PATH. All three
                    are required.
  --output-dir DIR  output directory (default eval_out)
  --timeout SEC     per-prover timeout (default 60)
  --taelja-timeout SEC  Taelja timeout (default 60)
  --jobs N          parallel workers (default 2)
  --lean PATH       lean binary, to check each translated proof
  --skip-done       keep results where proof.tstp and taelja.txt exist. Taelja
                    timeouts, spent budgets and ok proofs without a Lean file
                    are translated again, and a missing no-fallback run or
                    Lean check (with --lean) is done.
  --list FILE       run the problems in FILE instead of the SPC scan for HNE,
                    HEQ and UEQ, one CATEGORY<TAB>Problems/DOM/NAME.p per line
                    as select_horn.py writes. May be repeated. Twee skips TFF.

A prover's proof.tstp is reused when present, unless the prover never started
or reported a proof it did not print. Each run writes to
<out>/<category>/<stem>/<prover>/ the files proof.tstp, taelja.txt and .err,
taelja.lean, taelja_nofallback.txt and .err (from taelja --no-fallback), and
lean.ok or lean.err. All rows go to <out>/results.csv, with columns
  prove       ok, timeout, fail, or tfail (a proof was found but not printed usably)
  taelja      ok, timeout, fail, nonhorn (the proof leaves the Horn fragment),
              unsupported, budget (the Twee budget was spent), or - if not run
  nofallback  the same for taelja --no-fallback
  lean        ok, fail, or - if not checked
"""

import argparse
import csv
import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SPC_PATTERNS = {
    'HNE': re.compile(r'\w+_UNS_\w+_NEQ_HRN'),    # Horn, no equality
    'HEQ': re.compile(r'\w+_UNS_\w+_[SP]EQ_HRN'), # Horn, with equality
    'UEQ': re.compile(r'\w+_UNS_\w+_PEQ_UEQ'),    # unit equality
}
CATEGORIES = ['HNE', 'HEQ', 'UEQ']
# every category of the evaluation, the CNF ones and the first-order ones
ALL_CATEGORIES = CATEGORIES + ['FOF', 'TFF']

SCRIPT_DIR = Path(__file__).parent


# Taelja's refusal of a proof with a non-Horn clause, which a prover's
# clausification can produce even for a Horn problem. It counts as out of
# scope, apart from other refusals.
NON_HORN_PROOF = re.compile(r'unsupported proof, clause \S+ is not Horn')


def classify_problem(p_file):
    """The CNF category a problem's SPC tag gives, or None."""
    try:
        with open(p_file) as f:
            for line in f:
                if not line.startswith('%') and line.strip():
                    break
                if 'SPC' in line:
                    for cat, pat in SPC_PATTERNS.items():
                        if pat.search(line):
                            return cat
    except OSError:
        pass
    return None


def find_prover(given, env_var, exe):
    """The path given, else the one env_var names, else bin/<exe> in this
    repository, else <exe> on the PATH."""
    import shutil
    candidates = [given, os.environ.get(env_var), str(SCRIPT_DIR.parent / 'bin' / exe)]
    for c in candidates:
        if c and Path(c).is_file():
            return str(Path(c).resolve())
    found = shutil.which(exe)
    return str(Path(found).resolve()) if found else None


def read_results(evaldir):
    """The rows of results.csv in an evaluation directory."""
    with open(Path(evaldir) / 'results.csv') as f:
        return list(csv.DictReader(f))


def find_taelja():
    """The binary of the current build, as cabal names it, else one on the PATH."""
    import shutil
    try:
        r = subprocess.run(['cabal', 'list-bin', 'taelja'], cwd=SCRIPT_DIR.parent,
                           capture_output=True, text=True, timeout=120)
        lines = r.stdout.split()
        if r.returncode == 0 and lines and Path(lines[-1]).exists():
            return lines[-1]
    except (OSError, subprocess.TimeoutExpired):
        pass
    return shutil.which('taelja')


PROVER_DIR = {'vampire': 'Vampire', 'e': 'E', 'twee': 'Twee'}


def lean_module(problem):
    """Lean module name of a problem, e.g. ALG018+1 -> Alg0181, since dots,
    dashes and pluses are not valid in Lean names."""
    return ''.join(p.capitalize() for p in re.split(r'[-_.+]', problem) if p)


def lean_namespace(category, prover, problem):
    """Namespace of a proof's Lean file, e.g. HeqVampireAna0092. Each proof
    needs its own so regen_lean_eval.py can import them all into one library."""
    return category.capitalize() + PROVER_DIR[prover] + lean_module(problem)

def taelja_project_root():
    """Project root where bin/twee lives, needed as cwd for Taelja."""
    return str(SCRIPT_DIR.parent)


def run(cmd, timeout=60, cwd=None, extra_env=None, stdin_text=None):
    """Run a command in its own process group, so a timeout stops everything it
    started. Returns the exit code (-1 on timeout, -2 when it cannot start),
    stdout and stderr."""
    import os
    import signal
    env = None
    if extra_env:
        env = os.environ.copy()
        env.update(extra_env)
    try:
        proc = subprocess.Popen(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, cwd=cwd, env=env,
            stdin=subprocess.PIPE if stdin_text else None,
            start_new_session=True,  # own process group, so killpg kills the whole tree
        )
        try:
            stdout, stderr = proc.communicate(input=stdin_text, timeout=timeout)
            return proc.returncode, stdout, stderr
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)
            proc.communicate()
            return -1, '', 'TIMEOUT'
    except Exception as e:
        return -2, '', str(e)


def prover_cmd(name, binary, p_file, tptp_dir):
    """The command line that runs a prover on a problem."""
    rel = str(p_file.relative_to(tptp_dir))
    if name == 'vampire':
        return [binary, '--proof', 'tptp', '--avatar', 'off', rel]
    if name == 'e':
        return [binary, '--auto', '--proof-object', '--tstp-format', rel]
    if name == 'twee':
        return [binary, '--tstp', '--formal-proof', '--multi',
                '--root', str(tptp_dir), str(p_file)]
    raise ValueError(f"Unknown prover: {name}")


def prover_env(name, tptp_dir):
    """The environment a prover needs, the TPTP directory for E's includes."""
    if name == 'e':
        return {'TPTP': str(tptp_dir)}
    return {}


OK_MARKERS = ['SZS status Theorem', 'SZS status Unsatisfiable',
              'Refutation found', 'Proof found', 'RESULT: Unsatisfiable']


def prover_succeeded(name, stdout):
    """Whether a prover's output reports a proof that has clauses."""
    if not any(m in stdout for m in OK_MARKERS):
        return False
    # Twee sometimes prints a success status with no proof clauses, which
    # leaves Taelja nothing to read.
    if name == 'twee' and not any(l.startswith('cnf(') or l.startswith('fof(')
                                  for l in stdout.splitlines()):
        return False
    return True


def strip_twee_preamble(output):
    """Remove Twee's human-readable preamble and keep only the TSTP block."""
    lines = output.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith('%') or line.startswith('cnf(') or line.startswith('fof('):
            # drop the non-TSTP RESULT line
            tstp_lines = [l for l in lines[i:]
                          if not l.startswith('RESULT:')]
            return ''.join(tstp_lines)
    return output


def launch_failed(out):
    """The cached prover run never started, so it says nothing about the
    problem and is redone."""
    err_file = out / 'prover.err'
    return err_file.exists() and err_file.read_text().startswith('[Errno')


def prover_emit_failed(stdout):
    """The prover reported a proof, which after a failed prover_succeeded
    means it printed no usable one."""
    return any(m in stdout for m in OK_MARKERS)


def _read_prove_status(out, prover_name):
    """The prove status of a cached run, for --skip-done."""
    tstp = (out / 'proof.tstp').read_text()
    if prover_succeeded(prover_name, tstp):
        return 'ok', tstp
    # A run killed mid-print may show a status marker in its partial output,
    # so a recorded timeout wins over tfail
    err_file = out / 'prover.err'
    if err_file.exists() and 'TIMEOUT' in err_file.read_text():
        return 'timeout', tstp
    if prover_emit_failed(tstp):
        return 'tfail', tstp
    return 'fail', tstp


def _has_empty_proof(txt):
    """Whether a lemma or goal has an empty proof."""
    import re
    return bool(re.search(r'Proof:\s*(?:Goal\b|Lemma\b|\Z)', txt, re.DOTALL))


def _only_warnings(err):
    """Whether stderr holds only [warn] lines and blank ones, so no error."""
    return all(line.startswith('[warn]') or not line.strip() for line in err.splitlines())


_FATAL_WARN_PATTERNS = (
    # a goal left unproved, which _has_empty_proof cannot always see
    'no unit found for goal',
    'no proof found for goal',
    'makeBlock: unit not in table',
    'makeBlock: cannot prove unnamed eq unit',
)


_GOAL_LINE = re.compile(r'^Goal\s+\d+:\s*(.+)$', re.M)
_SYMBOL = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')


def _conjecture_symbols(problem_file):
    """Lowercase symbols of the problem's fof conjectures and all-negative cnf
    negated conjectures, parsed here so the check does not trust Taelja. A cnf
    clause with a positive literal is a hypothesis. None if there are none."""
    try:
        txt = problem_file.read_text(errors='replace')
    except OSError:
        return None
    txt = re.sub(r'%[^\n]*', '', txt)
    units = re.findall(r'\b(fof|cnf)\s*\(\s*[^,]+,\s*(conjecture|negated_conjecture)\s*,(.*?)\)\s*\.', txt, re.S)
    syms = set()
    for kind, role, body in units:
        if kind == 'cnf' and role == 'negated_conjecture':
            # strip the parentheses around a multi-literal clause, or its first
            # literal fails the '~' check
            stripped = body.strip()
            if stripped.startswith('(') and stripped.endswith(')'):
                stripped = stripped[1:-1]
            lits = [l.strip() for l in stripped.split('|')]
            if not all(l.startswith('~') for l in lits):
                continue
        for s in _SYMBOL.findall(body):
            if s[0].islower():
                syms.add(s)
    return syms or None


_GOAL_HEAD = re.compile(r'^\s*([a-z][A-Za-z0-9_]*)\s*(?:\(|$)')


def _goal_matches_conjecture(proof_txt, problem_file):
    """False when an emitted goal's leading symbol is not in the conjecture,
    since a proof of another statement would still pass Lean. Only that symbol
    is compared, as existential witnesses may use any axiom symbol."""
    conj = _conjecture_symbols(problem_file)
    if conj is None:
        return True
    for goal in _GOAL_LINE.findall(proof_txt):
        # older outputs state a goal under hypotheses as H => G, and G is
        # what is proved
        m = _GOAL_HEAD.match(goal.rsplit(' => ', 1)[-1])
        if m and m.group(1) not in conj:
            return False
    return True


def _has_fatal_warning(err):
    """Whether a warning shows the proof is incomplete, as when a goal is
    left unproved."""
    return any(p in line for line in err.splitlines() for p in _FATAL_WARN_PATTERNS)


def _read_taelja_status(out, p_file, tag='taelja'):
    """The status of a cached translation. The conjecture check is redone
    rather than trusting an '[eval]' note from an earlier run."""
    txt_file = out / (tag + '.txt')
    err_file = out / (tag + '.err')
    if not txt_file.exists():
        return '-'
    txt = txt_file.read_text()
    raw_err = err_file.read_text() if err_file.exists() else ''
    # '[eval]' lines are this script's earlier verdicts, not Taelja warnings
    err = '\n'.join(line for line in raw_err.splitlines() if not line.startswith('[eval]'))
    if 'TIMEOUT' in err:
        return 'timeout'
    if NON_HORN_PROOF.search(err):
        return 'nonhorn'
    if 'unsupported proof' in err or 'unsupported conjecture' in err:
        return 'unsupported'
    if 'fallback budget' in err:
        return 'budget'
    if txt.strip() and _only_warnings(err) and not _has_empty_proof(txt) and not _has_fatal_warning(err):
        if _goal_matches_conjecture(txt, p_file):
            # drop a stale '[eval]' note
            if err.strip():
                err_file.write_text(err + '\n')
            elif err_file.exists():
                err_file.unlink()
            return 'ok'
        if not raw_err.rstrip('\n').endswith('does not mention'):
            err_file.write_text(raw_err.rstrip('\n') +
                '\n[eval] emitted goal uses a symbol the conjecture does not mention\n')
        return 'fail'
    return 'fail'


# Statuses of a proof outside the fragment, and the file stem of the
# --no-fallback translation.
OUT_OF_SCOPE = ('nonhorn', 'unsupported')
NOFB = 'taelja_nofallback'


def _translate(out, tag, flags, taelja, category, prover_name, stem, p_file, taelja_timeout, lean):
    """Run Taelja with flags on the cached proof from the project root, write
    <tag>.txt and <tag>.err, and return the status."""
    tstp_path = out / 'proof.tstp'
    taelja_cwd = taelja_project_root()
    twee_env = {'TAELJA_TWEE_TIMEOUT': '60'}
    args = list(flags)
    if lean:
        # the same run writes the Lean file, which Lean checks later
        lean_file = (out / (tag + '.lean')).resolve()
        for stale in (lean_file, out / 'lean.ok', out / 'lean.err'):
            if stale.exists():
                stale.unlink()
        args += [f'--lean-out={lean_file}',
                 f'--namespace={lean_namespace(category, prover_name, stem)}']
    args.append(str(tstp_path))
    if taelja:
        rc, proof, err = run([taelja] + args, timeout=taelja_timeout,
                             cwd=taelja_cwd, extra_env=twee_env)
    else:
        rc, proof, err = run(['cabal', 'run', 'taelja', '--'] + args,
                             timeout=taelja_timeout, cwd=taelja_cwd, extra_env=twee_env)

    (out / (tag + '.txt')).write_text(proof)
    if err.strip():
        (out / (tag + '.err')).write_text(err)
    elif (out / (tag + '.err')).exists():
        (out / (tag + '.err')).unlink()  # stale from an earlier run

    if rc == -1:
        return 'timeout'
    if NON_HORN_PROOF.search(err):
        return 'nonhorn'
    if 'unsupported proof' in err or 'unsupported conjecture' in err:
        return 'unsupported'
    if 'fallback budget' in err:
        return 'budget'
    if rc == 0 and proof.strip() and _only_warnings(err) and not _has_empty_proof(proof) and not _has_fatal_warning(err):
        if _goal_matches_conjecture(proof, p_file):
            return 'ok'
        (out / (tag + '.err')).write_text(err + '\n[eval] emitted goal uses a symbol the conjecture does not mention\n')
        return 'fail'
    return 'fail'


def process_one(p_file, category, prover_name, prover_bin, taelja, out_dir, tptp_dir, timeout,
                skip_done=False, lean_bin=None, taelja_timeout=60):
    """Run one prover on one problem, translate the proof with and without the
    fallback, check it with Lean when asked, and return the row of results."""
    stem = p_file.stem
    out  = out_dir / category / stem / prover_name
    out.mkdir(parents=True, exist_ok=True)

    result = {
        'category': category, 'problem': stem, 'prover': prover_name,
        'prove': '-', 'taelja': '-', 'nofallback': '-', 'lean': '-',
    }

    # Under --skip-done a cached translation is kept, except a timeout or spent
    # budget, which depends on machine load, and an ok proof without its Lean
    # file. A missing --no-fallback translation is run on its own.
    cached = None
    if skip_done and (out / 'proof.tstp').exists() and (out / 'taelja.txt').exists():
        status = _read_taelja_status(out, p_file)
        if status not in ('timeout', 'budget') and (status != 'ok' or (out / 'taelja.lean').exists()):
            cached = status
    if cached is not None:
        prove_status, tstp = _read_prove_status(out, prover_name)
        result['prove'] = prove_status
        if prove_status == 'ok':
            result['taelja'] = cached
            nofb = cached if cached in OUT_OF_SCOPE else _read_taelja_status(out, p_file, NOFB)
            if nofb in ('-', 'timeout'):
                nofb = _translate(out, NOFB, ['--no-fallback'], taelja, category, prover_name,
                                  stem, p_file, taelja_timeout, lean=False)
            result['nofallback'] = nofb
            if cached == 'ok':
                result['lean'] = _lean_verdict(out)
                if result['lean'] == '-' and lean_bin:
                    result['lean'] = _run_lean(out, lean_bin)
        return result

    # 1. The prover, unless proof.tstp is cached. A cached tfail or failed
    # launch is run again.
    proof_tstp = out / 'proof.tstp'
    cached_status = None
    if proof_tstp.exists() and not launch_failed(out):
        tstp = proof_tstp.read_text()
        if prover_succeeded(prover_name, tstp):
            cached_status = 'ok'
        elif _check_cached_timeout(out) == 'timeout':
            cached_status = 'timeout'
        elif prover_emit_failed(tstp):
            cached_status = None  # re-run below
        else:
            cached_status = 'fail'
    if cached_status is not None:
        prove_status = cached_status
    else:
        rc, tstp, err = run(prover_cmd(prover_name, prover_bin, p_file, tptp_dir),
                            timeout=timeout, cwd=str(tptp_dir),
                            extra_env=prover_env(prover_name, tptp_dir))
        if prover_name == 'twee':
            tstp = strip_twee_preamble(tstp)
        proof_tstp.write_text(tstp)
        # remove a prover.err left by an earlier run
        if err.strip():
            (out / 'prover.err').write_text(err)
        elif (out / 'prover.err').exists():
            (out / 'prover.err').unlink()
        if rc == -1:
            prove_status = 'timeout'
        elif prover_succeeded(prover_name, tstp):
            prove_status = 'ok'
        elif prover_emit_failed(tstp):
            prove_status = 'tfail'
        else:
            prove_status = 'fail'

    result['prove'] = prove_status
    if prove_status != 'ok':
        return result

    # 2. Taelja, with and without the fallback. A proof outside the fragment
    # is refused either way, so it is not run twice.
    result['taelja'] = _translate(out, 'taelja', [], taelja, category, prover_name, stem,
                                  p_file, taelja_timeout, lean=True)
    if result['taelja'] in OUT_OF_SCOPE:
        result['nofallback'] = result['taelja']
    else:
        result['nofallback'] = _translate(out, NOFB, ['--no-fallback'], taelja, category,
                                          prover_name, stem, p_file, taelja_timeout, lean=False)

    # 3. Lean verification (optional)
    if result['taelja'] == 'ok' and lean_bin:
        result['lean'] = _run_lean(out, lean_bin)

    return result


def _check_cached_timeout(out):
    """'timeout' when prover.err shows the cached prover run timed out, else
    'fail'."""
    err_file = out / 'prover.err'
    if err_file.exists() and 'TIMEOUT' in err_file.read_text():
        return 'timeout'
    return 'fail'


def _lean_verdict(out_dir):
    """The recorded Lean verdict on the proof's Lean file, '-' if none."""
    if (out_dir / 'lean.ok').exists():
        return 'ok'
    if (out_dir / 'lean.err').exists():
        return 'fail'
    return '-'


def record_lean(out_dir, ok, message=''):
    """Record a Lean verdict as lean.ok or lean.err, replacing the old one."""
    for marker in ('lean.ok', 'lean.err'):
        if (out_dir / marker).exists():
            (out_dir / marker).unlink()
    if ok:
        (out_dir / 'lean.ok').write_text('')
    else:
        (out_dir / 'lean.err').write_text(message[:2000])
    return 'ok' if ok else 'fail'


def _run_lean(out_dir, lean_bin):
    """Check the Lean file Taelja wrote for the proof. Returns 'ok' or 'fail'."""
    lean_file = out_dir / 'taelja.lean'
    if not lean_file.exists():
        return record_lean(out_dir, False, 'taelja wrote no Lean file')
    rc, lean_out, lean_err = run([lean_bin, str(lean_file)], timeout=120)
    return record_lean(out_dir, rc == 0 and 'error' not in lean_out + lean_err, lean_out + lean_err)


def main():
    """Run the evaluation over the listed problems and print the summary."""
    parser = argparse.ArgumentParser()
    parser.add_argument('tptp_dir', help='Path to TPTP directory (contains Problems/)')
    parser.add_argument('--vampire',     default=None, metavar='PATH')
    parser.add_argument('--eprover',     default=None, metavar='PATH')
    parser.add_argument('--twee',        default=None, metavar='PATH')
    parser.add_argument('--output-dir',  default='eval_out')
    parser.add_argument('--timeout',     type=int, default=60,
                        help='Per-prover timeout in seconds (default: 60)')
    parser.add_argument('--jobs',        type=int, default=2)
    parser.add_argument('--taelja-timeout', type=int, default=60, metavar='SEC',
                        help='Taelja timeout in seconds (default: 60)')
    parser.add_argument('--list',        action='append', default=[], metavar='FILE',
                        help='problem list from select_horn.py instead of the SPC scan')
    parser.add_argument('--skip-done',   action='store_true',
                        help='Skip problems where proof.tstp and taelja.txt already exist')
    parser.add_argument('--lean',        default=None, metavar='PATH',
                        help='Path to lean binary; verify each taelja proof with Lean 4')
    args = parser.parse_args()

    # Provers are found like Taelja finds Twee, as absolute paths since they
    # run in the TPTP directory.
    provers = {}
    for name, given, env_var, exe in (('vampire', args.vampire, 'TAELJA_VAMPIRE', 'vampire'),
                                      ('e', args.eprover, 'TAELJA_EPROVER', 'eprover'),
                                      ('twee', args.twee, 'TAELJA_TWEE', 'twee')):
        path = find_prover(given, env_var, exe)
        if path is None:
            raise SystemExit(f"error: no {exe} found. Give --{'eprover' if name == 'e' else name} PATH, "
                             f"set {env_var}, put it at bin/{exe} or on the PATH")
        provers[name] = path
    # Taelja's fallback uses the same Twee
    os.environ['TAELJA_TWEE'] = provers['twee']

    taelja = find_taelja()
    if taelja:
        taelja = str(Path(taelja).resolve())

    lean_bin = str(Path(args.lean).resolve()) if args.lean else None
    taelja_timeout = args.taelja_timeout

    print("Provers:")
    for name, path in provers.items():
        print(f"  {name:8s}: {path}")
    print(f"taelja:   {taelja or 'not found, using cabal run'}")
    if lean_bin:
        print(f"lean:     {lean_bin}")
    print(f"timeouts: prover={args.timeout}s  taelja={taelja_timeout}s")

    # The provers run in the TPTP directory, so a wrong path stops here,
    # rather than every new run failing while cached results look fine.
    tptp = Path(args.tptp_dir).resolve()
    if not (tptp / 'Problems').is_dir():
        raise SystemExit(f"error: no Problems/ directory under {tptp}")
    out  = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    problems = []
    if args.list:
        for lst in args.list:
            for line in Path(lst).read_text().splitlines():
                if line.strip():
                    cat, rel = line.split('\t')
                    problems.append((tptp / rel, cat))
        print(f"\nProblems from {', '.join(args.list)}")
    else:
        print("\nScanning TPTP problems for HNE/HEQ/UEQ by SPC field...")
        for p in sorted((tptp / 'Problems').glob('*/*.p')):
            cat = classify_problem(p)
            if cat:
                problems.append((p, cat))

    missing = [str(p) for p, _ in problems if not p.exists()]
    if missing:
        raise SystemExit(f"error: {len(missing)} listed problems do not exist, the first is {missing[0]}")

    categories = [c for c in ALL_CATEGORIES if any(cat == c for _, cat in problems)]
    for c in categories:
        n = sum(1 for _, cat in problems if cat == c)
        print(f"  {c}: {n}")
    print(f"  Total: {len(problems)} problems × {len(provers)} provers = "
          f"{len(problems) * len(provers)} tasks")
    print(f"\nRunning with {args.jobs} workers, timeout {args.timeout}s\n")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {
            ex.submit(process_one, p, cat, name, binary, taelja, out, tptp, args.timeout,
                      args.skip_done, lean_bin, taelja_timeout): (p, name)
            for p, cat in problems
            for name, binary in provers.items()
            # Twee reads no types
            if not (cat == 'TFF' and name == 'twee')
        }
        total = len(futures)
        for i, f in enumerate(as_completed(futures), 1):
            r = f.result()
            results.append(r)
            print(f"[{i:5d}/{total}] {r['category']}/{r['problem']} "
                  f"[{r['prover']:7s}]: prove={r['prove']:7s} taelja={r['taelja']:7s} "
                  f"nofallback={r['nofallback']}")

    csv_path = out / 'results.csv'
    fields = ['category', 'problem', 'prover', 'prove', 'taelja', 'nofallback', 'lean']
    with open(csv_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(sorted(results, key=lambda r: (r['category'], r['problem'], r['prover'])))

    print()
    _print_summary(results, provers, lean_bin is not None, categories)

    print(f"\nDetailed results: {csv_path}")

    # --- Taelja failure breakdown ---
    proved_results = [r for r in results if r['prove'] == 'ok']
    failed_taelja  = [r for r in proved_results
                      if r['taelja'] not in ('ok', 'unsupported', 'nonhorn', '-')]
    print(f"\nTaelja failure breakdown ({len(failed_taelja)} prover-proved, supported but not translated):")
    err_cats = {}
    for r in failed_taelja:
        p = out / r['category'] / r['problem'] / r['prover']
        err = (p / 'taelja.err').read_text().strip() if (p / 'taelja.err').exists() else ''
        txt = (p / 'taelja.txt').read_text().strip() if (p / 'taelja.txt').exists() else ''
        if r['taelja'] == 'timeout' or 'TIMEOUT' in err:
            key = 'TIMEOUT (Taelja)'
        elif r['taelja'] == 'budget':
            key = 'fallback budget spent (Twee calls)'
        elif 'no unit found for goal' in err:
            key = 'no unit found for goal'
        elif 'no proof found for goal' in err:
            key = 'no proof found for goal (Twee)'
        elif 'case split' in err:
            key = 'unsupported conjecture (case split)'
        elif 'outside the supported calculus' in err:
            key = 'unsupported proof (inference outside the calculus)'
        elif 'unsupported proof' in err or 'unsupported conjecture' in err:
            key = 'unsupported proof (not Horn)'
        elif 'never derives $false' in err:
            key = 'proof never derives $false'
        elif 'states the goal' in err:
            key = 'no clause states the goal'
        elif 'no goal proof produced' in err:
            key = 'no goal proof produced'
        elif err:
            key = f'other: {err[:60]}'
        elif not txt:
            key = '(empty output, no error)'
        else:
            key = '(output but incomplete proof)'
        err_cats[key] = err_cats.get(key, 0) + 1
    for key, cnt in sorted(err_cats.items(), key=lambda x: -x[1]):
        print(f"  {cnt:5d}  {key}")

    # --- Inference rules across all proved problems ---
    print("\nInference rules across all proved benchmarks:")
    all_rules = {}
    for r in proved_results:
        tstp = out / r['category'] / r['problem'] / r['prover'] / 'proof.tstp'
        if tstp.exists():
            for m in re.finditer(r'inference\((\w+)', tstp.read_text()):
                rule = m.group(1)
                all_rules[rule] = all_rules.get(rule, 0) + 1
    if all_rules:
        print(f"  {'Rule':<40s}  {'Count':>8s}")
        print(f"  {'-'*40}  {'-'*8}")
        for rule, count in sorted(all_rules.items(), key=lambda x: -x[1]):
            print(f"  {rule:<40s}  {count:>8d}")
    else:
        print("  (no inference rules found)")


def _print_summary(results, provers, lean_col, categories=CATEGORIES):
    """Print the counts per category and prover."""
    hdr = (f"{'Category':8s}  {'Prover':7s}  {'Total':>6s}  "
           f"{'Proved':>6s}  {'NonHrn':>6s}  {'Unsupp':>6s}  {'Transl':>6s}  {'NoFB':>6s}  {'Fail':>6s}  {'Budget':>6s}  {'TFail':>6s}"
           + (f"  {'Lean':>6s}" if lean_col else ''))
    print(hdr)
    print('-' * len(hdr))

    prover_list = list(provers)
    for cat in categories + ['TOTAL']:
        for prover in prover_list + (['ALL'] if len(provers) > 1 else []):
            sub = [r for r in results
                   if (cat == 'TOTAL' or r['category'] == cat)
                   and (prover == 'ALL' or r['prover'] == prover)]
            if not sub:
                continue
            n           = len(sub)
            # tfail counts as proved, as only the prover's TSTP output failed
            proved      = sum(1 for r in sub if r['prove'] in ('ok', 'tfail'))
            nonhorn     = sum(1 for r in sub if r['taelja'] == 'nonhorn')
            unsupported = sum(1 for r in sub if r['taelja'] == 'unsupported')
            translated  = sum(1 for r in sub if r['taelja'] == 'ok')
            # translated from the input proof alone, without Twee
            nofallback  = sum(1 for r in sub if r.get('nofallback') == 'ok')
            failed      = sum(1 for r in sub if r['prove'] == 'ok'
                              and r['taelja'] in ('fail', 'timeout'))
            budget      = sum(1 for r in sub if r['taelja'] == 'budget')
            tfail       = sum(1 for r in sub if r['prove'] == 'tfail')
            lean        = sum(1 for r in sub if r.get('lean') == 'ok')

            cat_col = cat if prover in (prover_list[0], 'ALL') else ''
            row = (f"{cat_col:8s}  {prover:7s}  {n:6d}  "
                   f"{proved:6d}  {nonhorn:6d}  {unsupported:6d}  {translated:6d}  {nofallback:6d}  "
                   f"{failed:6d}  {budget:6d}  {tfail:6d}")
            if lean_col:
                row += f"  {lean:6d}"
            print(row)
        if cat != 'TOTAL':
            print()


if __name__ == '__main__':
    main()
