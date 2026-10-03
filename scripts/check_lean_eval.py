#!/usr/bin/env python3
"""Check each eval Lean module on its own with `lake env lean`.

`lake build` of the whole library stops after failures, so its failure list
is incomplete. For every taelja=ok row this checks the module that
regen_lean_eval.py copied, records the verdict in results.csv's lean column
and as lean.ok or lean.err beside the proof (which eval.py reads on a rerun),
lists failures in eval_out/lean_failing.txt and prints counts.

Usage
  python3 scripts/check_lean_eval.py [--jobs N] [--limit N]
"""
import argparse, csv, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

from eval import ALL_CATEGORIES, PROVER_DIR, lean_module, read_results, record_lean, run

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
LEAN = ROOT / "lean"
TIMEOUT = 600  # seconds per module


def check(module_rel):
    """Check one Lean module, returning whether Lean accepts it and Lean's output."""
    rc, out, err = run(["lake", "env", "lean", module_rel], timeout=TIMEOUT, cwd=str(LEAN))
    if rc == -1:
        return False, f"error: no verdict within {TIMEOUT} s"
    return rc == 0 and "error" not in out + err, out + err


def main():
    """Check the Lean module of every translated proof and record the verdicts."""
    ap = argparse.ArgumentParser()
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--limit", type=int, default=None)
    ap.add_argument("--output-dir", default="eval_out", help="the evaluation directory")
    args = ap.parse_args()
    evaldir = (ROOT / args.output_dir).resolve()

    rows = read_results(evaldir)
    todo = [r for r in rows if r["taelja"] == "ok"]
    if args.limit:
        todo = todo[: args.limit]

    def check_row(r):
        """The verdict on the module of one row."""
        rel = f"TaeljaVerify/{r['category']}/{PROVER_DIR[r['prover']]}/{lean_module(r['problem'])}.lean"
        if not (LEAN / rel).exists():
            return r, "missing", ""
        ok, out = check(rel)
        return r, record_lean(evaldir / r["category"] / r["problem"] / r["prover"], ok, out), out

    verdict = {}
    failing = []
    with ThreadPoolExecutor(max_workers=args.jobs) as ex:
        futs = [ex.submit(check_row, r) for r in todo]
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
    with open(evaldir / "results.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader(); w.writerows(rows)

    (evaldir / "lean_failing.txt").write_text(
        "\n".join(f"{c}/{p}/{pr}\t{msg}" for (c, p, pr), msg in sorted(failing)) + "\n")

    print(f"\nchecked {len(todo)} modules: "
          f"ok={sum(v=='ok' for v in verdict.values())} "
          f"fail={sum(v=='fail' for v in verdict.values())} "
          f"missing={sum(v=='missing' for v in verdict.values())}")
    print(f"{'cat':4} {'prover':8} {'ok':>5} {'fail':>5}")
    for c in ALL_CATEGORIES:
        for pr in ("vampire", "e", "twee"):
            sub = [v for (cc, _, pp), v in verdict.items() if cc == c and pp == pr]
            print(f"{c:4} {pr:8} {sum(v=='ok' for v in sub):5} {sum(v!='ok' for v in sub):5}")
    print(f"failing list: {evaldir / 'lean_failing.txt'}")


if __name__ == "__main__":
    main()
