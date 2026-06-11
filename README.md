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

## How It Works

The input axioms split into two groups:

- **Units** — positive unit clauses (single facts such as `p(a)` or `f(a) = b`).
- **Non-units** — Horn implications `L₁ ∧ … ∧ Lₙ → H` with two or more literals.

The **goal** is the unnegated conjecture. Units starts with the axioms and grows as new facts are derived.

Each non-unit clause is tried two ways:

- **Top-down** — if the head matches the goal, match each premise against Units under the same substitution. If all premises are covered, the proof is done.
- **Bottom-up** — match the premises against Units freely, derive the grounded head, then check whether it reaches the goal by matching or rewriting. If not, add the derived head to Units for later rounds.

The **fixpoint loop** retries all clauses until the goal is reached or Units stops growing. If it stalls, every anonymous equation is named so it can be cited in a proof step, and one final round is attempted. If that also fails, the goal is discharged as a pure rewriting problem over the accumulated units.

**Rewriting** uses BFS over unit equations in three places: matching a body literal against a unit (rewrite a known fact until it matches the target), connecting a derived head to the goal, and building equational chains `s = … = t`.

**Proof blocks** take one of two shapes: `have … and … hence …` for relational goals, and `s = {by eq} t₁ = … = t` for equational goals.

**Lemmatization** promotes an anonymous proved fact to a named lemma. It is forced when an `and`-line or a rewrite step must cite a fact by name, and when an equational chain cannot embed a `have/hence` derivation inline. As a heuristic, a rewrite path that ends at a non-ground equation is extracted as a named equational-chain lemma rather than inlined.

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