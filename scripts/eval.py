#!/usr/bin/env python3
"""
Taelja evaluation pipeline.

Usage:
  python eval.py <vampire> <tptp_dir> [--output-dir DIR] [--timeout SEC] [--jobs N]

Processes all .p files in <tptp_dir>/Problems/{HNE,HEQ,UEQ}:
  1. Run Vampire to get a TSTP proof
  2. Run Taelja to translate to have/and/hence proof
  3. Run taelja2lean.py to generate a self-contained Lean 4 file

Output in --output-dir (default: eval_out/):
  <category>/<stem>/vampire.tstp  -- vampire output
  <category>/<stem>/taelja.txt    -- taelja proof
  <category>/<stem>/proof.lean    -- lean file
  results.csv                     -- per-problem outcomes
"""

import argparse
import csv
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

# SPC patterns for each category (matched against the % SPC line in problem headers).
# Vampire clausifies FOF/CNF alike, so we match both.
SPC_PATTERNS = {
    'HNE': re.compile(r'\w+_UNS_\w+_NEQ_HRN'),   # Horn, no equality
    'HEQ': re.compile(r'\w+_UNS_\w+_[SP]EQ_HRN'), # Horn, with (some/pure) equality
    'UEQ': re.compile(r'\w+_UNS_\w+_PEQ_UEQ'),   # unit equality
}

CATEGORIES = ['HNE', 'HEQ', 'UEQ']
SCRIPT_DIR = Path(__file__).parent
TAELJA2LEAN = SCRIPT_DIR / 'taelja2lean.py'


def classify_problem(p_file):
    """Return the category (HNE/HEQ/UEQ) for a .p file, or None if not relevant."""
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
    """Find the taelja binary: dist-newstyle first, then PATH."""
    project = SCRIPT_DIR.parent
    pattern = list(project.glob('dist-newstyle/**/taelja/taelja'))
    if pattern:
        return str(sorted(pattern)[-1])
    import shutil
    t = shutil.which('taelja')
    if t:
        return t
    # Fallback: run via cabal (slower, auto-builds)
    return None

def run(cmd, timeout=60):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return -1, '', 'TIMEOUT'
    except Exception as e:
        return -2, '', str(e)

def vampire_succeeded(stdout):
    return ('SZS status Theorem' in stdout
            or 'Refutation found' in stdout)

def process_problem(p_file, category, vampire, taelja, out_dir, timeout):
    stem = p_file.stem
    prob_dir = out_dir / category / stem
    prob_dir.mkdir(parents=True, exist_ok=True)

    result = {'category': category, 'problem': stem,
              'vampire': '-', 'taelja': '-', 'lean': '-'}

    # 1. Vampire
    rc, tstp, err = run([vampire, '--input_syntax', 'tptp', str(p_file)], timeout=timeout)
    (prob_dir / 'vampire.tstp').write_text(tstp)
    if err.strip():
        (prob_dir / 'vampire.err').write_text(err)

    if not vampire_succeeded(tstp):
        result['vampire'] = 'fail'
        return result
    result['vampire'] = 'ok'

    # 2. Taelja
    if taelja:
        rc, proof, err = run([taelja, str(prob_dir / 'vampire.tstp')], timeout=30)
    else:
        # cabal run fallback (slow)
        rc, proof, err = run(
            ['cabal', 'run', 'taelja', '--', str(prob_dir / 'vampire.tstp')],
            timeout=120)

    (prob_dir / 'taelja.txt').write_text(proof)
    if err.strip():
        (prob_dir / 'taelja.err').write_text(err)

    if rc != 0 or not proof.strip():
        result['taelja'] = 'fail'
        return result
    result['taelja'] = 'ok'

    # 3. taelja2lean.py
    rc, lean, err = run(
        [sys.executable, str(TAELJA2LEAN), str(prob_dir / 'taelja.txt')],
        timeout=30)
    (prob_dir / 'proof.lean').write_text(lean)
    if err.strip():
        (prob_dir / 'lean.err').write_text(err)

    if rc != 0 or not lean.strip():
        result['lean'] = 'fail'
        return result
    result['lean'] = 'ok'

    return result

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('vampire', help='Path to vampire binary')
    parser.add_argument('tptp_dir', help='Path to TPTP directory (contains Problems/)')
    parser.add_argument('--output-dir', default='eval_out')
    parser.add_argument('--timeout', type=int, default=60,
                        help='Vampire timeout in seconds (default: 60)')
    parser.add_argument('--jobs', type=int, default=min(32, os.cpu_count() or 8),
                        help='Parallel workers (default: min(32, cpu_count))')
    args = parser.parse_args()

    tptp = Path(args.tptp_dir)
    out  = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    vampire = args.vampire
    taelja  = find_taelja()
    if taelja:
        print(f"taelja: {taelja}")
    else:
        print("taelja binary not found in dist-newstyle or PATH — falling back to 'cabal run'")

    print("Scanning TPTP problems for HNE/HEQ/UEQ by SPC field...")
    all_p = sorted((tptp / 'Problems').glob('*/*.p'))
    problems = []  # list of (path, category)
    for p in all_p:
        cat = classify_problem(p)
        if cat:
            problems.append((p, cat))

    counts = {c: sum(1 for _, cat in problems if cat == c) for c in CATEGORIES}
    for c in CATEGORIES:
        print(f"  {c}: {counts[c]} problems")

    if not problems:
        print("No matching problems found.")
        sys.exit(1)

    print(f"\nTotal: {len(problems)} problems")
    print(f"Running with {args.jobs} workers, vampire timeout {args.timeout}s\n")

    results = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {
            ex.submit(process_problem, p, cat, vampire, taelja, out, args.timeout): p
            for p, cat in problems
        }
        for i, f in enumerate(as_completed(futures), 1):
            r = f.result()
            results.append(r)
            status = f"{r['vampire']:4s}  {r['taelja']:4s}  {r['lean']:4s}"
            print(f"[{i:4d}/{len(problems)}] {r['category']}/{r['problem']}: {status}")

    # CSV
    csv_path = out / 'results.csv'
    with open(csv_path, 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=['category', 'problem', 'vampire', 'taelja', 'lean'])
        w.writeheader()
        w.writerows(sorted(results, key=lambda r: (r['category'], r['problem'])))

    # Summary
    print()
    print(f"{'Category':8s}  {'Total':>6s}  {'Vampire':>8s}  {'Taelja':>7s}  {'Lean':>6s}")
    print('-' * 46)
    for cat in CATEGORIES + ['TOTAL']:
        sub = [r for r in results if cat == 'TOTAL' or r['category'] == cat]
        if not sub:
            continue
        v = sum(1 for r in sub if r['vampire'] == 'ok')
        t = sum(1 for r in sub if r['taelja'] == 'ok')
        l = sum(1 for r in sub if r['lean']    == 'ok')
        n = len(sub)
        print(f"{cat:8s}  {n:6d}  {v:4d}/{n:<3d}  {t:4d}/{n:<3d}  {l:3d}/{n}")

    print(f"\nDetailed results: {csv_path}")
    print(f"Per-problem output: {out}/")

if __name__ == '__main__':
    main()
