#!/usr/bin/env python3
"""List the TPTP problems that are Horn as written, for eval.py --list.

FOF and TFF theorem problems are kept when `taelja --horn-problem` finds them
Horn before any clausification. CNF problems are read off their SPC tag as
HNE, HEQ or UEQ. TFF with arithmetic, polymorphism, extended forms or the
modal $ki encoding is skipped, as Taelja reads plain first-order clauses only.

Usage
  python3 scripts/select_horn.py <tptp_dir> [--taelja PATH] [--jobs N] [--limit N]
                                 [--output-dir eval_out]

Writes horn_fof.txt, horn_tff.txt and horn_cnf.txt to the output directory,
one CATEGORY<TAB>Problems/DOM/NAME.p per line, and unknown.txt for problems
taelja could not judge.
"""
import argparse
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from eval import SPC_PATTERNS, find_taelja

FORMS = {
    'FOF': re.compile(r'^% SPC\s*:\s*FOF_THM_'),
    'TFF': re.compile(r'^% SPC\s*:\s*TF0_THM_.*_NAR\s*$'),
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
                    for cat, pat in SPC_PATTERNS.items():
                        if pat.search(line):
                            return cat
                    return None
                if not line.startswith('%') and line.strip():
                    return None
    except OSError:
        pass
    return None


UNKNOWN = {}


def is_horn(taelja, p_file, tptp_dir):
    """True, False, or None when the problem could not be read, with the
    reason kept in UNKNOWN."""
    env = dict(os.environ, TPTP=str(tptp_dir))
    try:
        r = subprocess.run([taelja, '--horn-problem', str(p_file)],
                           cwd=tptp_dir, env=env, capture_output=True, text=True, timeout=900)
    except subprocess.TimeoutExpired:
        UNKNOWN[str(p_file)] = 'timeout'
        return None
    out = (r.stdout + r.stderr).strip()
    if out == 'horn':
        return True
    if out.startswith('not horn:'):
        return False
    UNKNOWN[str(p_file)] = out.splitlines()[0][:160] if out else 'no output'
    return None


def main():
    """Select the Horn problems of a TPTP library and write one list per format."""
    ap = argparse.ArgumentParser()
    ap.add_argument('tptp_dir')
    ap.add_argument('--taelja', default=None, help='the taelja binary, default: cabal list-bin taelja')
    ap.add_argument('--jobs', type=int, default=4)
    ap.add_argument('--limit', type=int, default=None, help='stop after N candidates, for a trial')
    ap.add_argument('--output-dir', default='eval_out')
    args = ap.parse_args()

    tptp = Path(args.tptp_dir).resolve()
    taelja = args.taelja or find_taelja()
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
    if UNKNOWN:
        with open(out / 'unknown.txt', 'w') as f:
            for p, why in sorted(UNKNOWN.items()):
                f.write(f'{Path(p).relative_to(tptp)}\t{why}\n')
        print(f'{len(UNKNOWN)} problems could not be read, listed in {out / "unknown.txt"}')


if __name__ == '__main__':
    main()
