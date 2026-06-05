# Tälja

Tälja is a tool that translates refutation proofs from automated theorem provers
into human-readable proofs for the Horn clause fragment.

## Usage

```
talja <proof-file>
```

## Proof Format

Tälja supports two argument styles:

**Equational chain** — for proofs of equations `s = t`:
```
s
= { by axiom 1 }
  t1
= { by axiom 2 R->L }
  t
```

**Have/hence** — for proofs involving Horn clause applications:
```
have p(a)
  by axiom 1
hence p(b)
  by rw axiom 2
hence q(b)
  by axiom 3
```

A complete proof consists of axioms, followed by zero or more lemmas, followed by the main goal:
```
Axiom 1: ...
...

Lemma 1: ...
Proof:
  ...

Goal 1: ...
Proof:
  ...
```

## Building

Requires GHC and Cabal ([GHCup](https://www.haskell.org/ghcup/) is the recommended installer).

```
cabal build
cabal run talja -- <proof-file>
```

## Fragment

The tool handles the **Horn clause fragment with equational and non-equational atoms**: clauses with at most one positive literal, where literals may be equational (`s = t`, `s ≠ t`) or relational (`P(t̄)`, `¬P(t̄)`).
