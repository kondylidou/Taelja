#!/usr/bin/env python3
"""Copy the taelja.lean of every taelja=ok row in eval_out into
lean/TaeljaVerify/ and list them as imports in lean/TaeljaVerifyEval.lean.

Usage
  python3 scripts/regen_lean_eval.py [--only-new] [--limit N]

  --only-new   skip modules that already exist and keep earlier imports.
               Without it, every eval module not copied in this run is
               deleted, so --limit alone prunes the rest.
  --limit N    process at most N rows (for testing)
"""
import sys, argparse
from pathlib import Path

from eval import ALL_CATEGORIES, PROVER_DIR, lean_module, read_results

TAELJA = Path(__file__).resolve().parent.parent
LEAN    = TAELJA / "lean" / "TaeljaVerify"
# Eval modules are generated and not tracked, so their imports go to a
# git-ignored file of their own, apart from the suite's TaeljaVerify.lean.
EVAL_LEAN = TAELJA / "lean" / "TaeljaVerifyEval.lean"


def main():
    """Copy the Lean files of the translated proofs and rewrite the import list."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--only-new", action="store_true")
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--output-dir", default="eval_out", help="the evaluation directory")
    args = parser.parse_args()
    evaldir = (TAELJA / args.output_dir).resolve()

    rows = [row for row in read_results(evaldir) if row["taelja"] == "ok"]
    if args.limit:
        rows = rows[: args.limit]

    generated = []
    errors = []
    for row in rows:
        # such as HEQ, ANA009-2 and vampire
        cat, prob, prover = row["category"], row["problem"], row["prover"]
        lean_path = evaldir / cat / prob / prover / "taelja.lean"
        if not lean_path.exists():
            errors.append(f"MISSING taelja.lean (rerun eval.py): {lean_path}")
            continue
        prover_dir, camel = PROVER_DIR[prover], lean_module(prob)
        out_path = LEAN / cat / prover_dir / f"{camel}.lean"
        if args.only_new and out_path.exists():
            continue
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(lean_path.read_text())
        generated.append(f"TaeljaVerify.{cat}.{prover_dir}.{camel}")

    # Rewrite TaeljaVerifyEval.lean, keeping whatever precedes the marker line
    existing = EVAL_LEAN.read_text().splitlines() if EVAL_LEAN.exists() else []
    eval_marker = "-- Eval benchmark imports"
    base_lines = []
    for line in existing:
        if line.strip() == eval_marker:
            break
        base_lines.append(line)

    # Without --only-new the imports are exactly the modules copied in this
    # run and other module files are deleted, so the Lean build counts the
    # translated proofs exactly.
    imports = set(generated)
    if args.only_new:
        imports |= {line.strip().removeprefix("import ") for line in existing
                    if any(line.startswith(f"import TaeljaVerify.{c}.") for c in ALL_CATEGORIES)}
    else:
        for cat in ALL_CATEGORIES:
            for pdir in PROVER_DIR.values():
                for f in (LEAN / cat / pdir).glob("*.lean"):
                    if f"TaeljaVerify.{cat}.{pdir}.{f.stem}" not in imports:
                        f.unlink()

    head = "\n".join(base_lines).rstrip()
    EVAL_LEAN.write_text((head + "\n\n" if head else "") + f"{eval_marker}\n"
                         + "\n".join(f"import {m}" for m in sorted(imports)) + "\n")

    print(f"Generated {len(generated)} files. Build them with: lake build TaeljaVerifyEval")
    if errors:
        print(f"{len(errors)} errors, so the census covers fewer proofs than translated:")
        for e in errors[:20]:
            print(" ", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
