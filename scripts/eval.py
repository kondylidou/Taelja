#!/usr/bin/env python3
"""
Taelja evaluation pipeline — Vampire, E, and Twee.

Usage:
  python eval.py <vampire> <tptp_dir> [options]

Required:
  vampire     Path to Vampire binary
  tptp_dir    Path to TPTP directory (contains Problems/)

Optional:
  --eprover PATH    Path to E prover binary
  --twee PATH       Path to Twee binary (auto-detected from bin/twee if omitted)
  --output-dir DIR  Output directory (default: eval_out)
  --timeout SEC     Per-prover timeout in seconds (default: 30)
  --jobs N          Parallel workers (default: min(32, cpu_count))
  --lean PATH       Path to lean binary; if given, verify each taelja proof
  --skip-done       Skip problems where proof.tstp and taelja.txt already exist

For each .p file classified as HNE/HEQ/UEQ by its SPC field, each available
prover is run and its TSTP output is fed to Taelja.

Output layout:
  <out>/<category>/<stem>/<prover>/proof.tstp
  <out>/<category>/<stem>/<prover>/taelja.txt
  <out>/<category>/<stem>/<prover>/taelja.err   (if any)
  <out>/<category>/<stem>/<prover>/lean.lean     (if --lean given and taelja ok)
  <out>/<category>/<stem>/<prover>/lean.err      (if lean check failed)
  <out>/results.csv
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


def prover_succeeded(name, stdout):
    ok_markers = ['SZS status Theorem', 'SZS status Unsatisfiable',
                  'Refutation found', 'Proof found', 'RESULT: Unsatisfiable']
    return any(m in stdout for m in ok_markers)


def strip_twee_preamble(output):
    """Remove Twee's human-readable preamble; keep only the TSTP block."""
    lines = output.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if line.startswith('%') or line.startswith('cnf(') or line.startswith('fof('):
            # Drop trailing non-TSTP line ("RESULT: ..." at the end)
            tstp_lines = [l for l in lines[i:]
                          if not l.startswith('RESULT:')]
            return ''.join(tstp_lines)
    return output


def process_one(p_file, category, prover_name, prover_bin, taelja, out_dir, tptp_dir, timeout,
                skip_done=False, lean_bin=None, taelja_timeout=15):
    stem = p_file.stem
    out  = out_dir / category / stem / prover_name
    out.mkdir(parents=True, exist_ok=True)

    result = {
        'category': category, 'problem': stem, 'prover': prover_name,
        'prove': '-', 'taelja': '-', 'lean': '-',
    }

    # Skip if already fully processed (proof.tstp + taelja.txt both exist)
    if skip_done and (out / 'proof.tstp').exists() and (out / 'taelja.txt').exists():
        tstp = (out / 'proof.tstp').read_text()
        result['prove'] = 'ok' if prover_succeeded(prover_name, tstp) else 'fail'
        if result['prove'] == 'ok':
            proof = (out / 'taelja.txt').read_text()
            err   = (out / 'taelja.err').read_text() if (out / 'taelja.err').exists() else ''
            taelja_ok = bool(proof.strip() and not err.strip())
            result['taelja'] = 'ok' if taelja_ok else 'fail'
            if taelja_ok and lean_bin:
                lean_out = out / 'lean.lean'
                lean_err = out / 'lean.err'
                if lean_out.exists() and not lean_err.exists():
                    result['lean'] = 'ok'
                elif lean_out.exists() and lean_err.exists():
                    result['lean'] = 'fail'
        return result

    # 1. Run prover — skip if proof.tstp already exists (reuse cached proof)
    proof_tstp = out / 'proof.tstp'
    if proof_tstp.exists():
        tstp = proof_tstp.read_text()
    else:
        rc, tstp, err = run(prover_cmd(prover_name, prover_bin, p_file, tptp_dir),
                            timeout=timeout, cwd=str(tptp_dir),
                            extra_env=prover_env(prover_name, tptp_dir))
        if prover_name == 'twee':
            tstp = strip_twee_preamble(tstp)
        proof_tstp.write_text(tstp)
        if err.strip():
            (out / 'prover.err').write_text(err)

    if not prover_succeeded(prover_name, tstp):
        result['prove'] = 'fail'
        return result
    result['prove'] = 'ok'

    # 2. Taelja (cwd=project root so bin/twee resolves correctly)
    tstp_path = out / 'proof.tstp'
    taelja_cwd = taelja_project_root()
    if taelja:
        rc, proof, err = run([taelja, str(tstp_path)], timeout=taelja_timeout, cwd=taelja_cwd)
    else:
        rc, proof, err = run(['cabal', 'run', 'taelja', '--', str(tstp_path)],
                             timeout=120, cwd=taelja_cwd)

    (out / 'taelja.txt').write_text(proof)
    if err.strip():
        (out / 'taelja.err').write_text(err)
    elif (out / 'taelja.err').exists():
        (out / 'taelja.err').unlink()  # clear stale error from previous run

    taelja_ok = rc == 0 and bool(proof.strip()) and not err.strip()
    result['taelja'] = 'ok' if taelja_ok else 'fail'

    # 3. Lean verification (optional)
    if taelja_ok and lean_bin:
        result['lean'] = _run_lean(proof, out, lean_bin)

    return result


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
    parser.add_argument('--timeout',     type=int, default=30)
    parser.add_argument('--jobs',        type=int, default=2)
    parser.add_argument('--taelja-timeout', type=int, default=60, metavar='SEC',
                        help='Taelja timeout in seconds (default: 60)')
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

    tptp = Path(args.tptp_dir)
    out  = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    print("\nScanning TPTP problems for HNE/HEQ/UEQ by SPC field...")
    problems = []
    for p in sorted((tptp / 'Problems').glob('*/*.p')):
        cat = classify_problem(p)
        if cat:
            problems.append((p, cat))

    for c in CATEGORIES:
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
        }
        total = len(futures)
        for i, f in enumerate(as_completed(futures), 1):
            r = f.result()
            results.append(r)
            print(f"[{i:5d}/{total}] {r['category']}/{r['problem']} "
                  f"[{r['prover']:7s}]: prove={r['prove']:4s} taelja={r['taelja']}")

    csv_path = out / 'results.csv'
    fields = ['category', 'problem', 'prover', 'prove', 'taelja', 'lean']
    with open(csv_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(sorted(results, key=lambda r: (r['category'], r['problem'], r['prover'])))

    print()
    lean_col = lean_bin is not None
    header = (f"{'Category':8s}  {'Prover':7s}  {'Total':>6s}  {'Proved':>7s}  {'Taelja':>7s}"
              + (f"  {'Lean':>7s}" if lean_col else ''))
    print(header)
    print('-' * len(header))
    for cat in CATEGORIES + ['TOTAL']:
        for prover in list(provers) + (['ALL'] if len(provers) > 1 else []):
            sub = [r for r in results
                   if (cat == 'TOTAL' or r['category'] == cat)
                   and (prover == 'ALL' or r['prover'] == prover)]
            if not sub:
                continue
            n = len(sub)
            v = sum(1 for r in sub if r['prove']  == 'ok')
            t = sum(1 for r in sub if r['taelja'] == 'ok')
            l = sum(1 for r in sub if r.get('lean') == 'ok')
            cat_col = cat if prover in (list(provers)[0], 'ALL') else ''
            row = f"{cat_col:8s}  {prover:7s}  {n:6d}  {v:4d}/{n:<3d}  {t:4d}/{n}"
            if lean_col:
                row += f"  {l:4d}/{n}"
            print(row)
        if cat != 'TOTAL':
            print()

    print(f"\nDetailed results: {csv_path}")

    # --- Taelja failure breakdown ---
    proved_results = [r for r in results if r['prove'] == 'ok']
    failed_taelja  = [r for r in proved_results if r['taelja'] != 'ok']
    print(f"\nTaelja failure breakdown ({len(failed_taelja)} proved but not translated):")
    err_cats = {}
    for r in failed_taelja:
        p = out / r['category'] / r['problem'] / r['prover']
        err = (p / 'taelja.err').read_text().strip() if (p / 'taelja.err').exists() else ''
        txt = (p / 'taelja.txt').read_text().strip() if (p / 'taelja.txt').exists() else ''
        if 'no unit found for goal' in err:
            key = 'no unit found for goal'
        elif 'no proof found for goal' in err:
            key = 'no proof found for goal (Twee)'
        elif 'no refutation found' in err:
            key = 'no refutation found (unsupported structure)'
        elif 'TIMEOUT' in err:
            key = 'TIMEOUT (Taelja)'
        elif 'unnamed relational unit' in err:
            key = 'unnamed relational unit'
        elif err:
            key = f'other: {err[:50]}'
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


if __name__ == '__main__':
    main()
