#!/usr/bin/env python3
"""Generate Lean verification files for all taelja=ok entries in eval_out.

Usage:
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

PROVER_DIR = {"vampire": "Vampire", "e": "E", "twee": "Twee"}


def to_camel(name: str) -> str:
    """ANA009-2 → Ana0092,  ALG440-1 → Alg4401"""
    parts = re.split(r'[-_.]', name)  # MSC015-1.005 -> Msc0151005 (dots are not valid in Lean names)
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
        cat    = row["category"]          # HEQ, HNE, UEQ
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
    existing = ROOT_LEAN.read_text().splitlines()
    # Keep lines up to and including the last non-eval import block
    eval_marker = "-- Eval benchmark imports"
    base_lines = []
    for line in existing:
        if line.strip() == eval_marker:
            break
        base_lines.append(line)

    # The import list mirrors the current taelja=ok rows exactly: modules of
    # results that are no longer ok (e.g. reclassified holes) are dropped and
    # their stale .lean files deleted, so the Lean build is a faithful census.
    if args.only_new:
        kept = set(
            line.strip().removeprefix("import ")
            for line in existing
            if line.startswith("import TaeljaVerify.HEQ.")
            or line.startswith("import TaeljaVerify.HNE.")
            or line.startswith("import TaeljaVerify.UEQ.")
        )
    else:
        kept = set()
    all_eval_imports = sorted(kept | set(generated))
    if not args.only_new:
        wanted = set(all_eval_imports)
        for cat in ("HEQ", "HNE", "UEQ"):
            for pdir in PROVER_DIR.values():
                for f in (LEAN / cat / pdir).glob("*.lean"):
                    if f"TaeljaVerify.{cat}.{pdir}.{f.stem}" not in wanted:
                        f.unlink()

    new_content = "\n".join(base_lines).rstrip()
    new_content += f"\n\n{eval_marker}\n"
    new_content += "\n".join(f"import {m}" for m in all_eval_imports)
    new_content += "\n"
    ROOT_LEAN.write_text(new_content)

    print(f"Generated {len(generated)} files.")
    if errors:
        print(f"{len(errors)} errors:")
        for e in errors[:20]:
            print(" ", e)


if __name__ == "__main__":
    main()
