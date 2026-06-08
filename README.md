# Tälja

Tälja translates refutation proofs from automated theorem provers into
human-readable proofs for the Horn clause fragment.

## Usage

```
taelja [--debug] <proof-file>
```

The input is a TSTP proof file. `--debug` prints the parsed unit structure
before the proof.

## Proof Format

**Equational chain** — for goals of the form `s = t`:
```
  s
= { by axiom 1 }
  t1
= { by axiom 2 R->L }
  t
```

**Have/hence** — for relational goals:
```
have p(a)
  by axiom 1
hence p(b)
  by rw axiom 2
```

A complete proof consists of axioms, optional lemmas, and the main goal:
```
Axiom 1: ...

Lemma 1: ...
Proof:
  ...

Goal 1: ...
Proof:
  ...
```

## Fragment

The tool handles the **Horn clause fragment**: clauses with at most one
positive literal, where literals may be equational (`s = t`, `s ≠ t`) or
relational (`P(t̄)`, `¬P(t̄)`).

## Building

Requires GHC and Cabal ([GHCup](https://www.haskell.org/ghcup/) is the
recommended installer).

```
cabal build
cabal run taelja -- <proof-file>
```

## Testing

```
cabal test
```

Golden tests live in `test/`. To add a new test: place the input `.tstp` file
in `test/`, run the tool to produce the expected output, save it to
`test/expected/<name>.txt`, and add a `golden "<name>"` entry in
`test/Main.hs`.
