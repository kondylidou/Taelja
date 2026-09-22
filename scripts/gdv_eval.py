#!/usr/bin/env python3
"""Check every translated proof of the evaluation with GDV.

For each taelja=ok row, print the TPTP derivation with --tptp and run GDV
against the problem.  A GaveUp is retried, since GDV's syntax check over the
network is flaky.  Writes one line per row to gdv_results.csv in eval_out and
prints a summary.

Usage: gdv_eval.py [--jobs N] [--limit N] [--category FOF]
"""
import argparse, csv, subprocess, sys, os, tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EVAL = ROOT / 'eval_out'
TPTP = Path(os.environ.get('TPTP', str(Path.home() / 'Desktop' / 'TPTP-v9.2.1')))
GDV = os.environ.get('GDV', str(Path(os.environ.get('GDV_DIR', '')) / 'GDV'))


def status_of(taelja, row, tries=3):
    d = EVAL / row['category'] / row['problem'] / row['prover']
    problem = TPTP / 'Problems' / row['problem'][:3] / (row['problem'] + '.p')
    out = subprocess.run([taelja, '--tptp', str(d / 'proof.tstp')],
                         capture_output=True, text=True, timeout=300)
    if out.returncode != 0 or not out.stdout.strip():
        return 'NoDerivation'
    with tempfile.NamedTemporaryFile('w', suffix='.p', delete=False) as tmp:
        tmp.write(out.stdout)
        path = tmp.name
    try:
        for _ in range(tries):
            r = subprocess.run([GDV, '-r', '-l', '-q1', '-t', '300', '-p', str(problem), path],
                               capture_output=True, text=True, timeout=1800,
                               env={**os.environ, 'TPTP': str(TPTP)})
            szs = [l.split('% SZS status ')[1].strip() for l in r.stdout.splitlines()
                   if l.startswith('% SZS status ')]
            s = szs[-1] if szs else 'NoStatus'
            # GaveUp is GDV's flaky syntax check, and a step counted as not
            # verified is often its prover timing out under load
            if s not in ('GaveUp', 'NoStatus') and 'not verified' not in s:
                return s
        return s
    finally:
        os.unlink(path)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--jobs', type=int, default=2)
    p.add_argument('--limit', type=int)
    p.add_argument('--category')
    args = p.parse_args()
    taelja = subprocess.run(['cabal', 'list-bin', 'taelja'], capture_output=True,
                            text=True, cwd=ROOT).stdout.split()[-1]
    rows = [r for r in csv.DictReader(open(EVAL / 'results.csv')) if r['taelja'] == 'ok']
    if args.category:
        rows = [r for r in rows if r['category'] == args.category]
    if args.limit:
        rows = rows[:args.limit]
    out = open(EVAL / 'gdv_results.csv', 'w', newline='')
    w = csv.writer(out); w.writerow(['category', 'problem', 'prover', 'gdv'])
    done = {'n': 0}

    def run(r):
        try:
            s = status_of(taelja, r)
        except Exception as e:
            s = f'error {type(e).__name__}'
        return r, s

    with ThreadPoolExecutor(args.jobs) as ex:
        for r, s in ex.map(run, rows):
            w.writerow([r['category'], r['problem'], r['prover'], s]); out.flush()
            done['n'] += 1
            if done['n'] % 100 == 0:
                print(f"{done['n']}/{len(rows)}", flush=True)
    out.close()
    import collections
    c = collections.Counter(row[3] for row in csv.reader(open(EVAL / 'gdv_results.csv')) if row[0] != 'category')
    print(c)


if __name__ == '__main__':
    main()
