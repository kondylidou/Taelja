# Taelja

Taelja converts resolution/superposition refutation proofs in TSTP format into
structured, human-readable proofs, and can emit them as Lean 4 theorems for
independent verification.

It reads the TSTP output of Vampire, E, or Twee and produces direct proofs in
two forms: `have … and … hence … by axiom N` blocks (one block per
hyperresolution step) and equality chains
(`t1 = { by axiom 1 } t2 = { by lemma 3 R->L } t3`). Every step cites a
concrete axiom or lemma. Derived clauses that the input proof uses more than
once are introduced as named lemmas with their own proofs.

## Example

Input (`resolution_example_horn_general.tstp`, Vampire output):

```
fof(f1, axiom,   t(b)).
fof(f2, axiom,   ! [X] : (t(X) => q(X))).
fof(f3, axiom,   s(a)).
fof(f4, axiom,   ! [X] : (s(X) => p(X))).
fof(f5, axiom,   ! [X,Y] : (p(X) & q(Y) => r(X,Y))).
fof(f6, conjecture, r(a,b)).
...
```

Output:

```
Axiom 1: t(b)
Axiom 2: t(X) => q(X)
Axiom 3: s(a)
Axiom 4: s(X) => p(X)
Axiom 5: p(X) /\ q(Y) => r(X,Y)

Lemma 6: q(b)
Proof:
  have t(b)
    by axiom 1
  hence q(b)
    by axiom 2

Goal 1: r(a,b)
Proof:
  have s(a)
    by axiom 3
  hence p(a)
    by axiom 4
   and q(b)
    by lemma 6
  hence r(a,b)
    by axiom 5
```

## Building

Requires GHC 9.6 and Cabal 3. Twee is bundled (`bin/twee`); the E prover
(`eprover`) should be on the PATH for full functionality. Vampire is only
needed to produce input proofs, not to translate them.

```
cabal build
```

## Usage

```
cabal run taelja -- <proof-file.tstp>
cabal run taelja -- --debug <proof-file.tstp>
```

`--debug` additionally prints the parsed units, the refutation proof tree,
and per-step matching traces.

Environment variables (all optional):

| Variable | Default | Meaning |
|----------|---------|---------|
| `TAELJA_TWEE_TIMEOUT` | 15 s | Budget for goal-level Twee calls |
| `TAELJA_TWEE_INTERNAL_TIMEOUT` | 5 s | Budget for internal Twee calls; never exceeds the goal budget |
| `TAELJA_E_TIMEOUT` | 5 s | Budget per E lemma sub-proof |
| `TAELJA_EPROVER` | `eprover` | Path to the E binary |
| `TAELJA_STRICT` | unset | `1` runs only the strict translation stage |

## Checking a proof with Lean

```
cabal run taelja -- proof.tstp > proof.txt
python3 scripts/taelja2lean.py proof.txt > proof.lean
cd lean && lake env lean proof.lean
```

Each theorem in the generated file mirrors one lemma or goal of the
structured proof.

## Testing

```
cabal test
```

Golden tests translate stored prover outputs for all three provers
(`test/baseline_{vampire,e,twee}/`) and compare against
`test/expected_{vampire,e,twee}/`. Each golden also has a Lean module under
`lean/TaeljaVerify/`.
