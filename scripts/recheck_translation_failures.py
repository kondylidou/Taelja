#!/usr/bin/env python3
"""Re-translate the problems whose eval status was a translation failure
(taelja != ok, prover ok) with the current binary + emitter, under the eval's
own 60 s budget, and Lean-check whatever translates.  Does not touch the
eval_out caches.  Writes eval_out/recheck_tfail.csv (key, before, taelja,
lean, note)."""
import csv, os, subprocess, sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
EVAL = ROOT / "eval_out"; LEAN = ROOT / "lean"
BIN = ROOT / "dist-newstyle/build/aarch64-osx/ghc-9.6.7/taelja-0.1.0.0/x/taelja/build/taelja/taelja"
EMIT = ROOT / "scripts/taelja2lean.py"
TMP = EVAL / "recheck_tfail_tmp"; TMP.mkdir(exist_ok=True)
JOBS = int(sys.argv[1]) if len(sys.argv) > 1 else 6
ONLY = sys.argv[2] if len(sys.argv) > 2 else None   # optional substring filter on the before-status
FATAL = ("goal(s) unproved in the final proof", "translate: translation failed", "taelja:")

def one(key, before):
    cat, prob, prov = key.split("/")
    proof = EVAL / cat / prob / prov / "proof.tstp"
    if not proof.exists():
        return key, before, "no-proof-file", "-", ""
    tag = key.replace("/", "_").replace("-", "_").replace(".", "_")
    txt = TMP / f"{tag}.txt"; lean = TMP / f"{tag}.lean"
    try:
        r = subprocess.run([str(BIN), str(proof)], capture_output=True, text=True, timeout=60, cwd=ROOT)
    except subprocess.TimeoutExpired:
        return key, before, "timeout", "-", ""
    first = next((l for l in r.stderr.splitlines() if l.strip()), "")
    if r.returncode != 0 or any(f in r.stderr for f in FATAL) or not r.stdout.strip():
        return key, before, "fail", "-", first[:100]
    txt.write_text(r.stdout)
    e = subprocess.run([sys.executable, str(EMIT), "--namespace", "T" + tag, str(txt)], capture_output=True, text=True)
    if e.returncode != 0:
        return key, before, "ok", "emit-error", e.stderr.strip().splitlines()[-1][:100]
    lean.write_text(e.stdout)
    l = subprocess.run(["lake", "env", "lean", str(lean)], cwd=LEAN, capture_output=True, text=True)
    out = l.stdout + l.stderr
    if l.returncode == 0 and "error" not in out:
        return key, before, "ok", "ok", first[:100]
    err = next((ln for ln in out.splitlines() if "error" in ln), "")[:100]
    return key, before, "ok", "fail", err

rows = list(csv.DictReader(open(EVAL / "results.csv")))
todo = []
for r in rows:
    if r["prove"] != "ok" or r["taelja"] == "ok":
        continue
    key = f"{r['category']}/{r['problem']}/{r['prover']}"
    err = EVAL / r["category"] / r["problem"] / r["prover"] / "taelja.err"
    before = r["taelja"]
    if before != "timeout" and err.exists():
        t = err.read_text()
        before = ("unproved" if "unproved in the final proof" in t else
                  "shouldBlock" if "shouldBlock" in t else
                  "ensureNamed" if "no proof found for" in t else
                  "unsupported" if "unsupported proof structure" in t else "fail")
    if ONLY and ONLY not in before:
        continue
    todo.append((key, before))
print(f"{len(todo)} keys", flush=True)
out = []
with ThreadPoolExecutor(JOBS) as ex:
    futs = [ex.submit(one, k, b) for k, b in todo]
    for i, f in enumerate(as_completed(futs), 1):
        out.append(f.result())
        if i % 50 == 0:
            print(f"  {i}/{len(todo)}", flush=True)
with open(EVAL / "recheck_tfail.csv", "w", newline="") as f:
    w = csv.writer(f); w.writerow(["key", "before", "taelja", "lean", "note"]); w.writerows(sorted(out))
from collections import Counter
print("by before-status -> now:")
c = Counter((b, t, l) for _, b, t, l, _ in out)
for (b, t, l), n in sorted(c.items()):
    print(f"  {b:12s} -> taelja={t:8s} lean={l:10s} {n}")
