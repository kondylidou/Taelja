#!/usr/bin/env python3
"""Find the FOF and TFF theorem problems of a TPTP library that are Horn as
written, for an eval run over them.

The fragment is decided on the problem as stated, before any prover runs and
without clausifying: every axiom must be a Horn clause as written, a
universally closed A1 & ... & An => B, an atom, a disjunction with at most one
positive literal, or a negated conjunction, and the conjecture a Horn clause
whose hypotheses are atoms and whose conclusion is an atom, a conjunction of
atoms, or one under an existential quantifier.  `taelja --horn-problem` makes
that judgement, includes resolved against the TPTP root.  TPTP's SPC field
marks CNF problems as Horn, and those are read off it.  TFF problems with
arithmetic, the polymorphic and extended forms, and the modal problems
encoded with $ki symbols are left out, since Taelja has no arithmetic and
reads plain first-order clauses only.

Usage
  python3 scripts/select_horn.py <tptp_dir> [--taelja PATH] [--jobs N] [--limit N]
                                 [--output-dir eval_out]

Writes <output-dir>/horn_fof.txt and <output-dir>/horn_tff.txt, one problem
per line as CATEGORY<TAB>Problems/DOM/NAME.p, for eval.py --list, and
<output-dir>/horn_cnf.txt with the HNE, HEQ and UEQ problems read off the
SPC tag, so one eval run can take all of them.
"""
import argparse
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

FORMS = {
    'FOF': re.compile(r'^% SPC\s*:\s*FOF_THM_'),
    'TFF': re.compile(r'^% SPC\s*:\s*TF0_THM_.*_NAR\s*$'),
}

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
                            if form == 'TFF' and '$ki' in Path(p_file).read_text(errors='ignore'):
                                return None
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


def is_horn(taelja, p_file, tptp_dir):
    """True, False, or None when the problem could not be read."""
    env = dict(os.environ, TPTP=str(tptp_dir))
    try:
        r = subprocess.run([taelja, '--horn-problem', str(p_file)],
                           cwd=tptp_dir, env=env, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return None
    out = (r.stdout + r.stderr).strip()
    if out == 'horn':
        return True
    if out.startswith('not horn:'):
        return False
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('tptp_dir')
    ap.add_argument('--taelja', default=None, help='the taelja binary, default: cabal list-bin taelja')
    ap.add_argument('--jobs', type=int, default=4)
    ap.add_argument('--limit', type=int, default=None, help='stop after N candidates, for a trial')
    ap.add_argument('--output-dir', default='eval_out')
    args = ap.parse_args()

    tptp = Path(args.tptp_dir).resolve()
    taelja = args.taelja
    if not taelja:
        r = subprocess.run(['cabal', 'list-bin', 'taelja'], capture_output=True, text=True,
                           cwd=Path(__file__).resolve().parent.parent)
        taelja = r.stdout.strip().splitlines()[-1] if r.returncode == 0 and r.stdout.strip() else None
    if not taelja or not Path(taelja).exists():
        sys.exit('no taelja binary found, pass --taelja')
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
    print(f'{len(candidates)} theorem problems to check '
          f'({sum(1 for f, _ in candidates if f == "FOF")} FOF, '
          f'{sum(1 for f, _ in candidates if f == "TFF")} TFF)')

    horn = {'FOF': [], 'TFF': []}
    counts = {'horn': 0, 'non-horn': 0, 'unknown': 0}
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futures = {ex.submit(is_horn, taelja, p, tptp): (form, p) for form, p in candidates}
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
