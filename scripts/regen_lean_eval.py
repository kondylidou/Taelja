#!/usr/bin/env python3
"""Generate Lean verification files for all taelja=ok entries in eval_out.

Usage
  python3 scripts/regen_lean_eval.py [--only-new] [--limit N]

  --only-new   skip files that already exist
  --limit N    process at most N files (for testing)
"""
import subprocess, sys, re, csv, argparse
from pathlib import Path

TAELJA = Path(__file__).resolve().parent.parent
SCRIPT  = TAELJA / "scripts" / "taelja2lean.py"
EVAL    = TAELJA / "eval_out"
LEAN    = TAELJA / "lean" / "TaeljaVerify"
RESULTS = EVAL / "results.csv"
ROOT_LEAN = TAELJA / "lean" / "TaeljaVerify.lean"
# The eval modules are generated from eval_out and not shipped, so their
# imports go to a file of their own, which .gitignore covers, and the tracked
# TaeljaVerify.lean keeps the suite's own modules only.
EVAL_LEAN = TAELJA / "lean" / "TaeljaVerifyEval.lean"

PROVER_DIR = {"vampire": "Vampire", "e": "E", "twee": "Twee"}
CATEGORIES = ("HEQ", "HNE", "UEQ", "FOF", "TFF")


def to_camel(name: str) -> str:
    """ANA009-2 → Ana0092,  ALG440-1 → Alg4401,  ALG018+1 → Alg0181"""
    parts = re.split(r'[-_.+]', name)  # MSC015-1.005 -> Msc0151005 (dots and pluses are not valid in Lean names)
    return ''.join(p.capitalize() for p in parts if p)


def make_namespace(category: str, prover: str, problem: str) -> str:
    """e.g. HeqVampireAna0092"""
    return category.capitalize() + PROVER_DIR[prover] + to_camel(problem)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only-new", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    args = parser.parse_args()

    # Read results.csv and collect taelja=ok rows
    rows = []
    with open(RESULTS) as f:
        for row in csv.DictReader(f):
            if row["taelja"] == "ok":
                rows.append(row)

    if args.limit:
        rows = rows[: args.limit]

    generated = []
    errors = []

    for row in rows:
        cat    = row["category"]          # HEQ, HNE, UEQ, FOF, TFF
        prob   = row["problem"]           # ANA009-2
        prover = row["prover"]            # vampire / e / twee

        txt_path = EVAL / cat / prob / prover / "taelja.txt"
        if not txt_path.exists():
            errors.append(f"MISSING taelja.txt: {txt_path}")
            continue

        prover_dir = PROVER_DIR[prover]
        camel      = to_camel(prob)
        ns         = make_namespace(cat, prover, prob)
        out_dir    = LEAN / cat / prover_dir
        out_path   = out_dir / f"{camel}.lean"

        if args.only_new and out_path.exists():
            continue

        out_dir.mkdir(parents=True, exist_ok=True)

        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--namespace", ns, str(txt_path)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            errors.append(f"SCRIPT ERROR {prob}/{prover}: {result.stderr[:200]}")
            continue

        out_path.write_text(result.stdout)
        generated.append(f"TaeljaVerify.{cat}.{prover_dir}.{camel}")

    # Rewrite TaeljaVerify.lean with all imports
    # Keep existing non-eval imports (Vampire/, E/, Twee/ at top level), add eval ones.
    existing = EVAL_LEAN.read_text().splitlines() if EVAL_LEAN.exists() else []
    # Keep lines up to and including the last non-eval import block
    eval_marker = "-- Eval benchmark imports"
    base_lines = []
    for line in existing:
        if line.strip() == eval_marker:
            break
        base_lines.append(line)

    # The import list mirrors the current taelja=ok rows exactly.  Modules of
    # results no longer ok are dropped and their stale .lean files deleted, so the
    # Lean build is a faithful census.
    if args.only_new:
        kept = set(
            line.strip().removeprefix("import ")
            for line in existing
            if any(line.startswith(f"import TaeljaVerify.{c}.") for c in CATEGORIES)
        )
    else:
        kept = set()
    all_eval_imports = sorted(kept | set(generated))
    if not args.only_new:
        wanted = set(all_eval_imports)
        for cat in CATEGORIES:
            for pdir in PROVER_DIR.values():
                for f in (LEAN / cat / pdir).glob("*.lean"):
                    if f"TaeljaVerify.{cat}.{pdir}.{f.stem}" not in wanted:
                        f.unlink()

    new_content = "\n".join(base_lines).rstrip()
    new_content = (new_content + "\n\n" if new_content else "") + f"{eval_marker}\n"
    new_content += "\n".join(f"import {m}" for m in all_eval_imports)
    new_content += "\n"
    EVAL_LEAN.write_text(new_content)

    print(f"Generated {len(generated)} files. Build them with: lake build TaeljaVerifyEval")
    if errors:
        print(f"{len(errors)} errors:")
        for e in errors[:20]:
            print(" ", e)


if __name__ == "__main__":
    main()
