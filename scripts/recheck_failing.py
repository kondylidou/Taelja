#!/usr/bin/env python3
"""Re-translate the problems listed in eval_out/lean_failing.txt with the
current taelja binary + emitter and Lean-check the result, without touching
eval_out caches.  Writes eval_out/recheck.csv (key, taelja, lean, error)."""
import csv, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EVAL = ROOT / "eval_out"; LEAN = ROOT / "lean"
BIN = ROOT / "dist-newstyle/build/aarch64-osx/ghc-9.6.7/taelja-0.1.0.0/x/taelja/build/taelja/taelja"
EMIT = ROOT / "scripts/taelja2lean.py"
TMP = EVAL / "recheck_tmp"; TMP.mkdir(exist_ok=True)
JOBS = int(sys.argv[1]) if len(sys.argv) > 1 else 6

def one(key):
    cat, prob, prov = key.split("/")
    proof = EVAL / cat / prob / prov / "proof.tstp"
    tag = key.replace("/", "_").replace("-", "_").replace(".", "_")
    txt = TMP / f"{tag}.txt"; lean = TMP / f"{tag}.lean"
    try:
        r = subprocess.run([str(BIN), str(proof)], capture_output=True, text=True, timeout=90,
                           cwd=ROOT, env={**os.environ, "TAELJA_TWEE_TIMEOUT": "60"})
    except subprocess.TimeoutExpired:
        return key, "timeout", "-", ""
    err = r.stderr
    if r.returncode != 0 or "unproved" in err or "translation failed" in err or "no refutation" in err:
        return key, "fail", "-", err.strip().splitlines()[0][:120] if err.strip() else "rc!=0"
    txt.write_text(r.stdout)
    e = subprocess.run([sys.executable, str(EMIT), "--namespace", "R" + tag, str(txt)],
                       capture_output=True, text=True)
    if e.returncode != 0:
        return key, "ok", "emit-error", e.stderr.strip().splitlines()[-1][:120]
    lean.write_text(e.stdout)
    l = subprocess.run(["lake", "env", "lean", str(lean)], cwd=LEAN, capture_output=True, text=True)
    out = l.stdout + l.stderr
    if l.returncode == 0 and "error" not in out:
        return key, "ok", "ok", ""
    first = next((x for x in out.splitlines() if "error" in x), "")
    return key, "ok", "fail", first[:160]

keys = [l.split("\t")[0] for l in open(EVAL / "lean_failing.txt") if l.strip()]
rows = []
with ThreadPoolExecutor(max_workers=JOBS) as ex:
    futs = [ex.submit(one, k) for k in keys]
    for i, f in enumerate(as_completed(futs), 1):
        rows.append(f.result())
        if i % 50 == 0: print(f"  {i}/{len(keys)}", file=sys.stderr, flush=True)
rows.sort()
with open(EVAL / "recheck.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["key", "taelja", "lean", "error"]); w.writerows(rows)
from collections import Counter
print("taelja:", Counter(r[1] for r in rows))
print("lean  :", Counter(r[2] for r in rows))
