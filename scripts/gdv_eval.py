#!/usr/bin/env python3
"""Verify every translated proof of the evaluation with GDV.

For each taelja=ok row of results.csv, print the proof with taelja --tptp, run
GDV on it against the problem under $TPTP, write the verdict to
gdv_results.csv beside results.csv and print the counts. GDV is found like
eval.py finds the provers (--gdv, $GDV, bin/GDV, then the PATH).

Usage: gdv_eval.py [--gdv PATH] [--output-dir eval_out] [--jobs N] [--limit N] [--category FOF]
"""
import argparse, csv, os, tempfile
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from eval import find_prover, find_taelja, read_results, run

ROOT = Path(__file__).resolve().parent.parent
TPTP = Path(os.environ.get('TPTP', str(Path.home() / 'Desktop' / 'TPTP-v9.2.1')))


def status_of(gdv, taelja, evaldir, row, tries=3):
    """GDV's verdict on the TPTP derivation of one row."""
    d = evaldir / row['category'] / row['problem'] / row['prover']
    problem = TPTP / 'Problems' / row['problem'][:3] / (row['problem'] + '.p')
    # from the project root, as eval.py runs Taelja, so bin/twee is found
    rc, derivation, _ = run([taelja, '--tptp', str(d / 'proof.tstp')], timeout=300, cwd=str(ROOT))
    if rc != 0 or not derivation.strip():
        return 'NoDerivation'
    with tempfile.NamedTemporaryFile('w', suffix='.p') as tmp:
        tmp.write(derivation)
        tmp.flush()
        for _ in range(tries):
            # GDV names its obligation files after the steps, in /tmp by
            # default, so each run gets its own directory (-k) or parallel
            # runs overwrite each other's.
            with tempfile.TemporaryDirectory(prefix='gdv-', ignore_cleanup_errors=True) as work:
                _, report, _ = run([gdv, '-r', '-l', '-q1', '-t', '300', '-k', work,
                                    '-p', str(problem), tmp.name],
                                   timeout=1800, extra_env={'TPTP': str(TPTP)})
            szs = [l.split('% SZS status ')[1].strip() for l in report.splitlines()
                   if l.startswith('% SZS status ')]
            s = szs[-1] if szs else 'NoStatus'
            # GaveUp means GDV's online syntax check failed, and a run that
            # printed no status failed too, so only these are retried. An
            # unverified step is GDV's verdict and stands.
            if s not in ('GaveUp', 'NoStatus'):
                break
    return s


def main():
    """Check every translated proof with GDV and write gdv_results.csv."""
    p = argparse.ArgumentParser()
    p.add_argument('--gdv', help='the GDV binary')
    p.add_argument('--output-dir', default='eval_out', help='the evaluation directory')
    p.add_argument('--jobs', type=int, default=2)
    p.add_argument('--limit', type=int)
    p.add_argument('--category')
    args = p.parse_args()
    gdv = find_prover(args.gdv, 'GDV', 'GDV')
    if gdv is None:
        raise SystemExit('error: no GDV found. Give --gdv PATH, set GDV, put it at bin/GDV or on the PATH')
    taelja = find_taelja()
    if taelja is None:
        raise SystemExit('error: no taelja binary found; run cabal build first')
    evaldir = (ROOT / args.output_dir).resolve()
    rows = [r for r in read_results(evaldir) if r['taelja'] == 'ok']
    if args.category:
        rows = [r for r in rows if r['category'] == args.category]
    if args.limit:
        rows = rows[:args.limit]

    def check_row(r):
        """The verdict on one row, or the error a check raised."""
        try:
            return r, status_of(gdv, taelja, evaldir, r)
        except Exception as e:
            return r, f'error {type(e).__name__}'

    counts = Counter()
    with open(evaldir / 'gdv_results.csv', 'w', newline='') as out, ThreadPoolExecutor(args.jobs) as ex:
        w = csv.writer(out)
        w.writerow(['category', 'problem', 'prover', 'gdv'])
        for i, (r, s) in enumerate(ex.map(check_row, rows), 1):
            w.writerow([r['category'], r['problem'], r['prover'], s])
            out.flush()
            counts[s] += 1
            if i % 100 == 0:
                print(f"{i}/{len(rows)}", flush=True)
    print(counts)


if __name__ == '__main__':
    main()
