#!/usr/bin/env python3
"""
Taelja evaluation pipeline for Vampire, E and Twee.

Usage
  python eval.py <vampire> <tptp_dir> [options]

Required
  vampire     Path to Vampire binary
  tptp_dir    Path to TPTP directory (contains Problems/)

Optional
  --eprover PATH    Path to E prover binary
  --twee PATH       Path to Twee binary (bin/twee if omitted)
  --output-dir DIR  Output directory (default eval_out)
  --timeout SEC     Per-prover timeout in seconds (default 60)
  --taelja-timeout SEC  Taelja timeout in seconds (default 60)
  --jobs N          Parallel workers (default 2)
  --lean PATH       Path to lean binary, to verify each taelja proof
  --skip-done       Skip problems where proof.tstp and taelja.txt already exist,
                    except that a Taelja timeout is run again on the cached proof
  --list FILE       Run the problems listed in FILE instead of scanning by SPC,
                    one CATEGORY<TAB>Problems/DOM/NAME.p per line as written by
                    select_horn.py.  May be repeated.  Twee is not run on TFF.

For each .p file classified as HNE, HEQ or UEQ by its SPC field, each
available prover is run and its TSTP output is fed to Taelja.

Output layout
  <out>/<category>/<stem>/<prover>/proof.tstp
  <out>/<category>/<stem>/<prover>/taelja.txt
  <out>/<category>/<stem>/<prover>/taelja.err   (if any)
  <out>/<category>/<stem>/<prover>/lean.lean     (if --lean given and taelja ok)
  <out>/<category>/<stem>/<prover>/lean.err      (if lean check failed)
  <out>/results.csv

prove is ok, timeout or fail.
taelja is ok, timeout, fail, nonhorn (the proof the prover returned leaves the
  Horn fragment, so it is out of scope rather than a refusal), unsupported,
  budget (the Twee and E call budget was spent), or - when not attempted.
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

SCRIPT_DIR = Path(__file__).parent


# A proof whose clauses are not all Horn is out of the fragment Taelja
# translates, whatever the problem is: a prover may name subformulas or keep a
# disjunction its other clausification distributes away.  Such a proof is
# counted apart from the refusals, which are about the conjecture or the
# calculus.
NON_HORN_PROOF = re.compile(r'unsupported proof, clause \S+ is not Horn')


def classify_problem(p_file):
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


def find_taelja():
    project = SCRIPT_DIR.parent
    hits = [p for p in project.glob('dist-newstyle/**/taelja/taelja')
            if '/t/' not in str(p)]  # exclude test executables (dist-newstyle/.../t/...)
    if hits:
        return str(sorted(hits)[-1])
    import shutil
    return shutil.which('taelja')


def find_twee():
    candidate = SCRIPT_DIR.parent / 'bin' / 'twee'
    if candidate.exists():
        return str(candidate)
    import shutil
    return shutil.which('twee')


def taelja2lean_script():
    return str(SCRIPT_DIR / 'taelja2lean.py')

def taelja_project_root():
    """Project root where bin/twee lives, needed as cwd for Taelja."""
    return str(SCRIPT_DIR.parent)


def run(cmd, timeout=60, cwd=None, extra_env=None, stdin_text=None):
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
            start_new_session=True,  # own process group → killpg kills whole tree
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
    if name == 'e':
        return {'TPTP': str(tptp_dir)}
    return {}


OK_MARKERS = ['SZS status Theorem', 'SZS status Unsatisfiable',
              'Refutation found', 'Proof found', 'RESULT: Unsatisfiable']


def prover_succeeded(name, stdout):
    if not any(m in stdout for m in OK_MARKERS):
        return False
    # Twee sometimes outputs just the SZS status with an empty CNFRefutation block
    # (no actual proof clauses).  Without clauses Taelja has nothing to parse, so
    # treat it as a prover failure.
    if name == 'twee' and not any(l.startswith('cnf(') or l.startswith('fof(')
                                  for l in stdout.splitlines()):
        return False
    return True


def strip_twee_preamble(output):
    """Remove Twee's human-readable preamble and keep only the TSTP block."""
    lines = output.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith('%') or line.startswith('cnf(') or line.startswith('fof('):
            # Drop the trailing non-TSTP RESULT line
            tstp_lines = [l for l in lines[i:]
                          if not l.startswith('RESULT:')]
            return ''.join(tstp_lines)
    return output


def prover_emit_failed(stdout):
    """Prover reported a proof (status marker) but failed to emit usable
    proof clauses, e.g. Twee crashing in its proof output component."""
    return any(m in stdout for m in OK_MARKERS)


def _read_prove_status(out, prover_name):
    """Re-derive prove/timeout status from cached files (used with --skip-done)."""
    tstp = (out / 'proof.tstp').read_text()
    if prover_succeeded(prover_name, tstp):
        return 'ok', tstp
    # Tell a timeout from other failures.  A run killed mid-print may carry a
    # status marker in partial output, so timeout evidence wins
    err_file = out / 'prover.err'
    if err_file.exists() and 'TIMEOUT' in err_file.read_text():
        return 'timeout', tstp
    if prover_emit_failed(tstp):
        return 'tfail', tstp
    return 'fail', tstp


def _has_empty_proof(txt):
    """True if any goal's proof section is empty."""
    import re
    return bool(re.search(r'Proof:\s*(?:Goal\b|Lemma\b|\Z)', txt, re.DOTALL))


def _only_warnings(err):
    """Return True if stderr contains only [warn] lines (no real errors)."""
    return all(line.startswith('[warn]') or not line.strip() for line in err.splitlines())


_FATAL_WARN_PATTERNS = (
    # translate's verdict that the chosen result still has a hole, which also
    # covers single-term chains _has_empty_proof cannot see
    'goal(s) unproved in the final proof',
    'no unit found for goal',
    'no proof found for goal',
    'makeBlock: unnamed relational unit',
    'makeBlock: unit not in table',
    'makeBlock: cannot prove unnamed eq unit',
)


_GOAL_LINE = re.compile(r'^Goal\s+\d+:\s*(.+)$', re.M)
_SYMBOL = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')


def _conjecture_symbols(problem_file):
    """Symbols of the problem's conjecture, read independently of the tool from
    fof conjecture units and all-negative cnf negated_conjecture clauses.  A
    clause with a positive literal is a hypothesis.  None when the file has no
    conjecture."""
    try:
        txt = problem_file.read_text(errors='replace')
    except OSError:
        return None
    txt = re.sub(r'%[^\n]*', '', txt)
    units = re.findall(r'\b(fof|cnf)\s*\(\s*[^,]+,\s*(conjecture|negated_conjecture)\s*,(.*?)\)\s*\.', txt, re.S)
    syms = set()
    for kind, role, body in units:
        if kind == 'cnf' and role == 'negated_conjecture':
            # A multi-literal clause is written "( lit1 | lit2 | ... )".  The parens
            # are stripped before splitting on '|', or the first literal keeps a '(' and
            # fails the '~' check below.
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
    """False when an emitted goal's predicate does not occur in the conjecture,
    since a proof of another statement would still pass Lean.  Only the
    predicate is compared, as existential witnesses may use any axiom symbol."""
    conj = _conjecture_symbols(problem_file)
    if conj is None:
        return True
    for goal in _GOAL_LINE.findall(proof_txt):
        # a goal under hypotheses is stated H => G, and G is what is proved
        m = _GOAL_HEAD.match(goal.rsplit(' => ', 1)[-1])
        if m and m.group(1) not in conj:
            return False
    return True


def _has_fatal_warning(err):
    """Return True if any [warn] line indicates a definitely-incomplete proof."""
    return any(p in line for line in err.splitlines() for p in _FATAL_WARN_PATTERNS)


def _read_taelja_status(out, p_file):
    """Re-derive taelja status from cached files.  Recomputes the
    goal-matches-conjecture check fresh rather than trusting a possible
    stale '[eval] ...' note left in taelja.err by an earlier run, so a fix
    to _goal_matches_conjecture itself is picked up under --skip-done."""
    txt_file = out / 'taelja.txt'
    err_file = out / 'taelja.err'
    if not txt_file.exists():
        return '-'
    txt = txt_file.read_text()
    raw_err = err_file.read_text() if err_file.exists() else ''
    # An '[eval] ...' line is this check's own earlier verdict, not a warning.
    # It is excluded since the verdict is recomputed below, or a stale one would
    # fail _only_warnings on its own.
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
            # Drop a stale '[eval] ...' note left by an earlier, buggier check.
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


def process_one(p_file, category, prover_name, prover_bin, taelja, out_dir, tptp_dir, timeout,
                skip_done=False, lean_bin=None, taelja_timeout=120):
    stem = p_file.stem
    out  = out_dir / category / stem / prover_name
    out.mkdir(parents=True, exist_ok=True)

    result = {
        'category': category, 'problem': stem, 'prover': prover_name,
        'prove': '-', 'taelja': '-', 'lean': '-',
    }

    # Skip if already fully processed (proof.tstp + taelja.txt both exist).  A
    # cached Taelja timeout is not a result, it depends on the machine's load,
    # so such a row runs Taelja again on the cached proof.
    if skip_done and (out / 'proof.tstp').exists() and (out / 'taelja.txt').exists() \
            and _read_taelja_status(out, p_file) != 'timeout':
        prove_status, tstp = _read_prove_status(out, prover_name)
        result['prove'] = prove_status
        if prove_status == 'ok':
            result['taelja'] = _read_taelja_status(out, p_file)
            if result['taelja'] == 'ok' and lean_bin:
                lean_out = out / 'lean.lean'
                lean_err = out / 'lean.err'
                if lean_out.exists() and not lean_err.exists():
                    result['lean'] = 'ok'
                elif lean_out.exists() and lean_err.exists():
                    result['lean'] = 'fail'
        return result

    # 1. Run the prover unless proof.tstp is cached.  A cached tfail depends on
    # the prover binary, so it is re-run.
    proof_tstp = out / 'proof.tstp'
    cached_status = None
    if proof_tstp.exists():
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
        if err.strip():
            (out / 'prover.err').write_text(err)
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

    # 2. Taelja (cwd=project root so bin/twee resolves correctly)
    tstp_path = out / 'proof.tstp'
    taelja_cwd = taelja_project_root()
    twee_env = {'TAELJA_TWEE_TIMEOUT': '60'}
    if taelja:
        rc, proof, err = run([taelja, str(tstp_path)], timeout=taelja_timeout,
                             cwd=taelja_cwd, extra_env=twee_env)
    else:
        rc, proof, err = run(['cabal', 'run', 'taelja', '--', str(tstp_path)],
                             timeout=taelja_timeout, cwd=taelja_cwd, extra_env=twee_env)

    (out / 'taelja.txt').write_text(proof)
    if err.strip():
        (out / 'taelja.err').write_text(err)
    elif (out / 'taelja.err').exists():
        (out / 'taelja.err').unlink()  # clear stale error from previous run

    if rc == -1:
        result['taelja'] = 'timeout'
    elif NON_HORN_PROOF.search(err):
        result['taelja'] = 'nonhorn'
    elif 'unsupported proof' in err or 'unsupported conjecture' in err:
        result['taelja'] = 'unsupported'
    elif 'fallback budget' in err:
        result['taelja'] = 'budget'
    elif rc == 0 and proof.strip() and _only_warnings(err) and not _has_empty_proof(proof) and not _has_fatal_warning(err):
        if _goal_matches_conjecture(proof, p_file):
            result['taelja'] = 'ok'
        else:
            result['taelja'] = 'fail'
            (out / 'taelja.err').write_text(err + '\n[eval] emitted goal uses a symbol the conjecture does not mention\n')
    else:
        result['taelja'] = 'fail'

    # 3. Lean verification (optional)
    if result['taelja'] == 'ok' and lean_bin:
        result['lean'] = _run_lean(proof, out, lean_bin)

    return result


def _check_cached_timeout(out):
    """Check if a cached prover run timed out (from prover.err)."""
    err_file = out / 'prover.err'
    if err_file.exists() and 'TIMEOUT' in err_file.read_text():
        return 'timeout'
    return 'fail'


def _run_lean(taelja_proof, out_dir, lean_bin):
    """Translate taelja proof to Lean 4 and verify it. Returns 'ok' or 'fail'."""
    import sys
    t2l = taelja2lean_script()
    rc, lean_src, err = run([sys.executable, t2l], timeout=10,
                             stdin_text=taelja_proof)
    if rc != 0 or not lean_src.strip():
        (out_dir / 'lean.err').write_text(f'taelja2lean failed: {err}')
        return 'fail'

    lean_file = out_dir / 'lean.lean'
    lean_file.write_text(lean_src)

    rc2, _, lean_err = run([lean_bin, str(lean_file)], timeout=30)
    if rc2 == 0:
        if (out_dir / 'lean.err').exists():
            (out_dir / 'lean.err').unlink()
        return 'ok'
    else:
        (out_dir / 'lean.err').write_text(lean_err[:2000])
        return 'fail'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('vampire',  help='Path to Vampire binary')
    parser.add_argument('tptp_dir', help='Path to TPTP directory (contains Problems/)')
    parser.add_argument('--eprover',     default=None, metavar='PATH')
    parser.add_argument('--twee',        default=None, metavar='PATH',
                        help='Path to Twee binary (Twee not used unless this is given)')
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

    # Resolve all binaries to absolute paths so cwd changes don't break them
    provers = {'vampire': str(Path(args.vampire).resolve())}
    if args.eprover:
        provers['e'] = str(Path(args.eprover).resolve())
    twee_path = args.twee
    if twee_path is None:
        # auto-detect bin/twee relative to this repo, as documented
        candidate = Path(__file__).resolve().parent.parent / 'bin' / 'twee'
        if candidate.exists():
            twee_path = str(candidate)
    if twee_path:
        provers['twee'] = str(Path(twee_path).resolve())

    taelja = find_taelja()
    if taelja:
        taelja = str(Path(taelja).resolve())

    lean_bin = str(Path(args.lean).resolve()) if args.lean else None
    taelja_timeout = args.taelja_timeout

    print("Provers:")
    for name, path in provers.items():
        print(f"  {name:8s}: {path}")
    print(f"taelja:   {taelja or 'not found — using cabal run'}")
    if lean_bin:
        print(f"lean:     {lean_bin}")
    print(f"timeouts: prover={args.timeout}s  taelja={taelja_timeout}s")

    tptp = Path(args.tptp_dir)
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

    categories = [c for c in CATEGORIES + ['FOF', 'TFF'] if any(cat == c for _, cat in problems)]
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
                  f"[{r['prover']:7s}]: prove={r['prove']:7s} taelja={r['taelja']}")

    csv_path = out / 'results.csv'
    fields = ['category', 'problem', 'prover', 'prove', 'taelja', 'lean']
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
            key = 'fallback budget spent (Twee and E calls)'
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
        elif 'more than the limit' in err:
            key = 'proof above the clause limit'
        elif 'unnamed relational unit' in err:
            key = 'unnamed relational unit'
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

    # --- Inference rules across ALL proved benchmarks ---
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
    # Header columns Category Prover Total Proved Unsupp Transl Fail and Lean
    hdr = (f"{'Category':8s}  {'Prover':7s}  {'Total':>6s}  "
           f"{'Proved':>6s}  {'NonHrn':>6s}  {'Unsupp':>6s}  {'Transl':>6s}  {'Fail':>6s}  {'Budget':>6s}  {'TFail':>6s}"
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
            # tfail counts as proved since the prover found a proof and only its TSTP
            # output failed
            proved      = sum(1 for r in sub if r['prove'] in ('ok', 'tfail'))
            nonhorn     = sum(1 for r in sub if r['taelja'] == 'nonhorn')
            unsupported = sum(1 for r in sub if r['taelja'] == 'unsupported')
            translated  = sum(1 for r in sub if r['taelja'] == 'ok')
            failed      = sum(1 for r in sub if r['prove'] == 'ok'
                              and r['taelja'] in ('fail', 'timeout'))
            budget      = sum(1 for r in sub if r['taelja'] == 'budget')
            tfail       = sum(1 for r in sub if r['prove'] == 'tfail')
            lean        = sum(1 for r in sub if r.get('lean') == 'ok')

            cat_col = cat if prover in (prover_list[0], 'ALL') else ''
            row = (f"{cat_col:8s}  {prover:7s}  {n:6d}  "
                   f"{proved:6d}  {nonhorn:6d}  {unsupported:6d}  {translated:6d}  "
                   f"{failed:6d}  {budget:6d}  {tfail:6d}")
            if lean_col:
                row += f"  {lean:6d}"
            print(row)
        if cat != 'TOTAL':
            print()


if __name__ == '__main__':
    main()
