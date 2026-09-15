#!/usr/bin/env python3
"""Find the FOF and TFF theorem problems of a TPTP library whose clausal form
is Horn, for an eval run over them.

TPTP's SPC field marks only CNF problems as Horn, so a FOF or TFF problem has
to be clausified to know.  E does that in a moment for all but the largest
problems, and a clause is Horn when at most one of its literals is positive,
a disequality counting as negative.  TFF problems with arithmetic and the
polymorphic and extended forms are left out, since Taelja has no arithmetic
and reads first-order clauses only.

Usage
  python3 scripts/select_horn.py <tptp_dir> [--eprover PATH] [--jobs N] [--limit N]
                                 [--output-dir eval_out]

Writes <output-dir>/horn_fof.txt and <output-dir>/horn_tff.txt, one problem
per line as CATEGORY<TAB>Problems/DOM/NAME.p, for eval.py --list, and
<output-dir>/horn_cnf.txt with the HNE, HEQ and UEQ problems read off the
SPC tag, so one eval run can take all of them.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

FORMS = {
    'FOF': re.compile(r'^% SPC\s*:\s*FOF_THM_'),
    'TFF': re.compile(r'^% SPC\s*:\s*TF0_THM_.*_NAR\s*$'),
}

CLAUSE = re.compile(r'^(?:cnf|tcf)\([^,]*,[^,]*,\s*(.*)\)\.\s*$', re.M)

CNF_CATEGORIES = {
    'HNE': re.compile(r'^% SPC\s*:\s*\w+_UNS_\w+_NEQ_HRN'),
    'HEQ': re.compile(r'^% SPC\s*:\s*\w+_UNS_\w+_[SP]EQ_HRN'),
    'UEQ': re.compile(r'^% SPC\s*:\s*\w+_UNS_\w+_PEQ_UEQ'),
}


def form_of(p_file):
    """FOF or TFF when the file is a theorem problem of that form, a CNF
    category when its SPC tag says Horn, else None."""
    try:
        with open(p_file, errors='ignore') as f:
            for line in f:
                if line.startswith('% SPC'):
                    for form, pat in FORMS.items():
                        if pat.match(line):
                            return form
                    for cat, pat in CNF_CATEGORIES.items():
                        if pat.match(line):
                            return cat
                    return None
                if not line.startswith('%') and line.strip():
                    return None
    except OSError:
        pass
    return None


def positive_literals(clause):
    """Positive literals of a clause as E prints it, a disequality being negative."""
    c = clause.strip()
    c = re.sub(r'^!\s*\[[^\]]*\]\s*:\s*', '', c)
    if c.startswith('(') and c.endswith(')'):
        c = c[1:-1]
    lits = re.split(r'\|(?![^()]*\))', c)
    return sum(1 for l in lits
               if not l.strip().startswith('~') and '!=' not in l and l.strip() != '$false')


def is_horn(eprover, p_file, tptp_dir, secs):
    """True, False, or None when E could not clausify within the cap."""
    env = dict(os.environ, TPTP=str(tptp_dir))
    try:
        r = subprocess.run([eprover, '--cnf', '-s', '--auto', f'--cpu-limit={secs}', str(p_file)],
                           cwd=tptp_dir, env=env, capture_output=True, text=True, timeout=secs + 5)
    except subprocess.TimeoutExpired:
        return None
    clauses = CLAUSE.findall(r.stdout)
    if not clauses:
        return None
    return all(positive_literals(c) <= 1 for c in clauses)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('tptp_dir')
    ap.add_argument('--eprover', default=None)
    ap.add_argument('--jobs', type=int, default=4)
    ap.add_argument('--limit', type=int, default=None, help='stop after N candidates, for a trial')
    ap.add_argument('--cpu', type=int, default=5, help='E clausification cap in seconds')
    ap.add_argument('--output-dir', default='eval_out')
    args = ap.parse_args()

    tptp = Path(args.tptp_dir).resolve()
    eprover = args.eprover or shutil.which('eprover')
    if not eprover:
        sys.exit('no eprover found, pass --eprover')
    out = Path(args.output_dir)
    out.mkdir(parents=True, exist_ok=True)

    candidates = []
    cnf = []
    for p in sorted((tptp / 'Problems').glob('*/*.p')):
        form = form_of(p)
        if form in ('FOF', 'TFF'):
            candidates.append((form, p))
        elif form:
            cnf.append((form, p))
    with open(out / 'horn_cnf.txt', 'w') as f:
        for cat, p in cnf:
            f.write(f'{cat}\t{p.relative_to(tptp)}\n')
    print(f'{len(cnf)} CNF Horn problems written to {out / "horn_cnf.txt"}')
    if args.limit:
        candidates = candidates[:args.limit]
    print(f'{len(candidates)} theorem problems to clausify '
          f'({sum(1 for f, _ in candidates if f == "FOF")} FOF, '
          f'{sum(1 for f, _ in candidates if f == "TFF")} TFF)')

    horn = {'FOF': [], 'TFF': []}
    counts = {'horn': 0, 'non-horn': 0, 'unknown': 0}
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {ex.submit(is_horn, eprover, p, tptp, args.cpu): (form, p) for form, p in candidates}
        for i, fut in enumerate(as_completed(futures), 1):
            form, p = futures[fut]
            verdict = fut.result()
            if verdict is None:
                counts['unknown'] += 1
            elif verdict:
                counts['horn'] += 1
                horn[form].append(p)
            else:
                counts['non-horn'] += 1
            if i % 200 == 0 or i == len(futures):
                print(f'  {i}/{len(futures)}  {counts}', flush=True)

    for form, fname in (('FOF', 'horn_fof.txt'), ('TFF', 'horn_tff.txt')):
        with open(out / fname, 'w') as f:
            for p in sorted(horn[form]):
                f.write(f'{form}\t{p.relative_to(tptp)}\n')
        print(f'{len(horn[form])} {form} Horn problems written to {out / fname}')


if __name__ == '__main__':
    main()
