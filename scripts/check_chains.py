#!/usr/bin/env python3
"""Sanity-check equality chains in eval outputs: for every chain step whose
cited rule is an equation, verify that applying the rule (in the cited
direction) to the previous term really yields the next term.  Reports the
share of unjustifiable steps per prover — a direct measure of mis-cited
chain steps, independent of Lean."""
import csv, sys, collections
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from taelja2lean import parse_document, find_rw_subst, EqLit, EqChainProof

ROOT = Path(__file__).resolve().parent.parent
rows = list(csv.DictReader(open(ROOT / "eval_out/results.csv")))
limit = int(sys.argv[1]) if len(sys.argv) > 1 else 10**9
tally = collections.defaultdict(lambda: collections.Counter())
examples = collections.defaultdict(list)
n = 0
for r in rows:
    if r["taelja"] != "ok": continue
    if n >= limit: break
    n += 1
    txt = ROOT / f"eval_out/{r['category']}/{r['problem']}/{r['prover']}/taelja.txt"
    try:
        doc = parse_document(txt.read_text())
    except Exception as e:
        tally[r['prover']]['parse-error'] += 1; continue
    ax = {a.num: a.formula for a in doc.axioms} if hasattr(doc, 'axioms') else {}
    lm = {l.num: l.formula for l in doc.lemmas} if hasattr(doc, 'lemmas') else {}
    blocks = [(f"lemma {l.num}", l.proof) for l in doc.lemmas] + [(f"goal {i+1}", g.proof) for i, g in enumerate(doc.goals)]
    for name, proof in blocks:
        if not isinstance(proof, EqChainProof): continue
        prev = proof.start
        for st in proof.steps:
            f = ax.get(st.ref.num) if st.ref.kind == 'axiom' else lm.get(st.ref.num)
            if isinstance(f, EqLit):
                ok = find_rw_subst(prev, st.term, f, st.ref.direction) is not None
                tally[r['prover']]['ok' if ok else 'BAD'] += 1
                if not ok and len(examples[r['prover']]) < 4:
                    examples[r['prover']].append(f"{r['category']}/{r['problem']}/{r['prover']} {name}: step by {st.ref.kind} {st.ref.num} {st.ref.direction}")
            else:
                tally[r['prover']]['non-eq-rule'] += 1
            prev = st.term
for p, c in tally.items():
    print(p, dict(c))
for p, ex in examples.items():
    for e in ex: print("  ", e)
