#!/usr/bin/env python3
"""Re-emit the fresh translations in eval_out/recheck_tmp for the keys that
still failed in recheck.csv, using the current emitter, and Lean-check them.
Writes eval_out/recheck2.csv."""
import csv, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
EVAL = ROOT / "eval_out"; LEAN = ROOT / "lean"; TMP = EVAL / "recheck_tmp"
EMIT = ROOT / "scripts/taelja2lean.py"
JOBS = int(sys.argv[1]) if len(sys.argv) > 1 else 6
keys = [r["key"] for r in csv.DictReader(open(EVAL / "recheck.csv")) if r["lean"] != "ok"]
def one(key):
    tag = key.replace("/", "_").replace("-", "_").replace(".", "_")
    txt = TMP / f"{tag}.txt"; lean = TMP / f"{tag}.lean"
    if not txt.exists():
        return key, "missing", ""
    e = subprocess.run([sys.executable, str(EMIT), "--namespace", "R" + tag, str(txt)], capture_output=True, text=True)
    if e.returncode != 0:
        return key, "emit-error", e.stderr.strip().splitlines()[-1][:120]
    lean.write_text(e.stdout)
    l = subprocess.run(["lake", "env", "lean", str(lean)], cwd=LEAN, capture_output=True, text=True)
    out = l.stdout + l.stderr
    if l.returncode == 0 and "error" not in out:
        return key, "ok", ""
    return key, "fail", next((x for x in out.splitlines() if "error" in x), "")[:160]
rows = []
with ThreadPoolExecutor(max_workers=JOBS) as ex:
    for i, f in enumerate(as_completed([ex.submit(one, k) for k in keys]), 1):
        rows.append(f.result())
        if i % 50 == 0: print(f"  {i}/{len(keys)}", file=sys.stderr, flush=True)
rows.sort()
with open(EVAL / "recheck2.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["key", "lean", "error"]); w.writerows(rows)
from collections import Counter
print("lean:", Counter(r[1] for r in rows))
