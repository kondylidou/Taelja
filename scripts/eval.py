#!/usr/bin/env python3
"""
Taelja evaluation pipeline — Vampire, Twee, and E.

Usage:
  python eval.py <vampire> <tptp_dir> [options]

Required:
  vampire     Path to Vampire binary
  tptp_dir    Path to TPTP directory (contains Problems/)

Optional:
  --twee PATH       Path to Twee binary (default: ../bin/twee relative to this script)
  --eprover PATH    Path to E prover binary
  --output-dir DIR  Output directory (default: eval_out)
  --timeout SEC     Per-prover timeout in seconds (default: 60)
  --jobs N          Parallel workers (default: min(32, cpu_count))

For each .p file classified as HNE/HEQ/UEQ by its SPC field, each available
prover is run and its TSTP output is fed to Taelja, then taelja2lean.py.

Output layout:
  <out>/<category>/<stem>/<prover>/proof.tstp
  <out>/<category>/<stem>/<prover>/taelja.txt
  <out>/<category>/<stem>/<prover>/proof.lean
  <out>/results.csv
"""

import argparse
import csv
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

SPC_PATTERNS = {
    'HNE': re.compile(r'\w+_UNS_\w+_NEQ_HRN'),    # Horn, no equality
    'HEQ': re.compile(r'\w+_UNS_\w+_[SP]EQ_HRN'), # Horn, with equality
    'UEQ': re.compile(r'\w+_UNS_\w+_PEQ_UEQ'),    # unit equality
}
CATEGORIES = ['HNE', 'HEQ', 'UEQ']

SCRIPT_DIR  = Path(__file__).parent
TAELJA2LEAN = SCRIPT_DIR / 'taelja2lean.py'
BIN_DIR     = SCRIPT_DIR.parent / 'bin'


def classify_problem(p_file):
    try:
        with open(p_file) as f:
            for line in f:
                if not line.startswith('%'):
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
    hits = list(project.glob('dist-newstyle/**/taelja/taelja'))
    if hits:
        return str(sorted(hits)[-1])
    import shutil
    return shutil.which('taelja')


def run(cmd, timeout=60):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, '', 'TIMEOUT'
    except Exception as e:
        return -2, '', str(e)


def prover_cmd(name, binary, p_file):
    if name == 'vampire':
        return [binary, '--input_syntax', 'tptp', str(p_file)]
    if name == 'twee':
        return [binary, '--tstp', '--formal-proof', '--multi', str(p_file)]
    if name == 'e':
        return [binary, '--auto', '--proof-object', '--tstp-format', str(p_file)]
    raise ValueError(f"Unknown prover: {name}")


def prover_succeeded(name, stdout):
    if name == 'vampire':
        return 'SZS status Theorem' in stdout or 'Refutation found' in stdout
    if name == 'twee':
        return 'SZS status Theorem' in stdout or 'Proof found' in stdout
    if name == 'e':
        return 'SZS status Theorem' in stdout or "proof" in stdout.lower()
    return False


def process_one(p_file, category, prover_name, prover_bin, taelja, out_dir, timeout):
    stem    = p_file.stem
    out     = out_dir / category / stem / prover_name
    out.mkdir(parents=True, exist_ok=True)

    result = {
        'category': category, 'problem': stem, 'prover': prover_name,
        'prove': '-', 'taelja': '-', 'lean': '-',
    }

    # 1. Run prover
    rc, tstp, err = run(prover_cmd(prover_name, prover_bin, p_file), timeout=timeout)
    (out / 'proof.tstp').write_text(tstp)
    if err.strip():
        (out / 'prover.err').write_text(err)

    if not prover_succeeded(prover_name, tstp):
        result['prove'] = 'fail'
        return result
    result['prove'] = 'ok'

    # 2. Taelja
    tstp_path = out / 'proof.tstp'
    if taelja:
        rc, proof, err = run([taelja, str(tstp_path)], timeout=30)
    else:
        rc, proof, err = run(['cabal', 'run', 'taelja', '--', str(tstp_path)], timeout=120)

    (out / 'taelja.txt').write_text(proof)
    if err.strip():
        (out / 'taelja.err').write_text(err)

    if rc != 0 or not proof.strip():
        result['taelja'] = 'fail'
        return result
    result['taelja'] = 'ok'

    # 3. taelja2lean.py
    rc, lean, err = run(
        [sys.executable, str(TAELJA2LEAN), str(out / 'taelja.txt')],
        timeout=30)
    (out / 'proof.lean').write_text(lean)
    if err.strip():
        (out / 'lean.err').write_text(err)

    if rc != 0 or not lean.strip():
        result['lean'] = 'fail'
        return result
    result['lean'] = 'ok'

    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('vampire',  help='Path to Vampire binary')
    parser.add_argument('tptp_dir', help='Path to TPTP directory (contains Problems/)')
    parser.add_argument('--twee',      default=None)
    parser.add_argument('--eprover',   default=None)
    parser.add_argument('--output-dir', default='eval_out')
    parser.add_argument('--timeout', type=int, default=60)
    parser.add_argument('--jobs',    type=int, default=min(32, os.cpu_count() or 8))
    args = parser.parse_args()

    # Resolve provers
    provers = {'vampire': args.vampire}

    twee = args.twee or (str(BIN_DIR / 'twee') if (BIN_DIR / 'twee').exists() else None)
    if twee:
        provers['twee'] = twee

    if args.eprover:
        provers['e'] = args.eprover

    taelja = find_taelja()

    print("Provers:")
    for name, path in provers.items():
        print(f"  {name}: {path}")
    print(f"taelja: {taelja or 'not found — using cabal run'}")

    # Scan problems
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

    # Submit all (problem, prover) pairs
    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {
            ex.submit(process_one, p, cat, name, binary, taelja, out, args.timeout): (p, name)
            for p, cat in problems
            for name, binary in provers.items()
        }
        total = len(futures)
        for i, f in enumerate(as_completed(futures), 1):
            r = f.result()
            results.append(r)
            print(f"[{i:5d}/{total}] {r['category']}/{r['problem']} "
                  f"[{r['prover']:7s}]: prove={r['prove']:4s} "
                  f"taelja={r['taelja']:4s} lean={r['lean']:4s}")

    # CSV
    csv_path = out / 'results.csv'
    fields = ['category', 'problem', 'prover', 'prove', 'taelja', 'lean']
    with open(csv_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(sorted(results, key=lambda r: (r['category'], r['problem'], r['prover'])))

    # Summary table
    print()
    header = f"{'Category':8s}  {'Prover':7s}  {'Total':>6s}  {'Proved':>7s}  {'Taelja':>7s}  {'Lean':>6s}"
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
            l = sum(1 for r in sub if r['lean']   == 'ok')
            cat_col   = cat    if prover in (list(provers)[0], 'ALL') else ''
            print(f"{cat_col:8s}  {prover:7s}  {n:6d}  {v:4d}/{n:<3d}  {t:4d}/{n:<3d}  {l:3d}/{n}")
        if cat != 'TOTAL':
            print()

    print(f"\nDetailed results: {csv_path}")

if __name__ == '__main__':
    main()
