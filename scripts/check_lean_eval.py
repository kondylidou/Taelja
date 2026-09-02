#!/usr/bin/env python3
"""Check every eval Lean module individually with `lake env lean`.

`lake build` of the aggregate target stops scheduling modules once some fail,
so its failure list is incomplete.  This checks each module of the current
taelja=ok rows on its own, records the verdict in results.csv's `lean` column
and prints per-category/prover counts.

Usage: python3 scripts/check_lean_eval.py [--jobs N] [--limit N]
"""
import argparse, csv, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
EVAL = ROOT / "eval_out"
RESULTS = EVAL / "results.csv"
LEAN = ROOT / "lean"
PROVER_DIR = {"vampire": "Vampire", "e": "E", "twee": "Twee"}


def to_camel(prob):
    # mirror regen_lean_eval.make_module_name: dots and dashes are not valid in
    # Lean module names (MSC015-1.005 -> Msc0151005)
    import re
    parts = re.split(r'[-_.]', prob)
    return parts[0].capitalize() + "".join(parts[1:])


def check(module_rel):
    r = subprocess.run(["lake", "env", "lean", module_rel], cwd=LEAN,
                       capture_output=True, text=True)
    out = (r.stdout + r.stderr)
    return r.returncode == 0 and "error" not in out, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--limit", type=int, default=None)
    args = ap.parse_args()

    rows = list(csv.DictReader(open(RESULTS)))
    todo = [r for r in rows if r["taelja"] == "ok"]
    if args.limit:
        todo = todo[: args.limit]

    def task(r):
        rel = f"TaeljaVerify/{r['category']}/{PROVER_DIR[r['prover']]}/{to_camel(r['problem'])}.lean"
        if not (LEAN / rel).exists():
            return r, "missing", ""
        ok, out = check(rel)
        return r, ("ok" if ok else "fail"), out

    verdict = {}
    failing = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futs = [ex.submit(task, r) for r in todo]
        for i, f in enumerate(as_completed(futs), 1):
            r, v, out = f.result()
            key = (r["category"], r["problem"], r["prover"])
            verdict[key] = v
            if v != "ok":
                first = next((l for l in out.splitlines() if "error" in l), "")
                failing.append((key, first[:160]))
            if i % 200 == 0:
                print(f"  {i}/{len(todo)} checked", file=sys.stderr)

    for r in rows:
        key = (r["category"], r["problem"], r["prover"])
        if key in verdict:
            r["lean"] = verdict[key]
    with open(RESULTS, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader(); w.writerows(rows)

    (EVAL / "lean_failing.txt").write_text(
        "\n".join(f"{c}/{p}/{pr}\t{msg}" for (c, p, pr), msg in sorted(failing)) + "\n")

    print(f"\nchecked {len(todo)} modules: "
          f"ok={sum(v=='ok' for v in verdict.values())} "
          f"fail={sum(v=='fail' for v in verdict.values())} "
          f"missing={sum(v=='missing' for v in verdict.values())}")
    print(f"{'cat':4} {'prover':8} {'ok':>5} {'fail':>5}")
    for c in ("HNE", "HEQ", "UEQ"):
        for pr in ("vampire", "e", "twee"):
            sub = [v for (cc, _, pp), v in verdict.items() if cc == c and pp == pr]
            print(f"{c:4} {pr:8} {sum(v=='ok' for v in sub):5} {sum(v!='ok' for v in sub):5}")
    print(f"failing list: {EVAL / 'lean_failing.txt'}")


if __name__ == "__main__":
    main()
