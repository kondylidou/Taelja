# Tälja

Tälja translates refutation proofs from automated theorem provers into
human-readable proofs for the Horn clause fragment.

## Usage

```
taelja [--debug] <proof-file>
```

The input is a TSTP proof file. `--debug` emits a per-round trace to stderr:
which clause was tried each round, whether top-down or bottom-up was taken,
what unit was derived, and when the fixpoint stalls.

## Proof Format

**Have/hence** — for goals discharged via Horn clause steps (including equational goals that go through a Horn implication):
```
have p(a)
  by axiom 1
hence p(b)
  by rw axiom 2
hence q(b)
  by axiom 3
```

A multi-premise step uses `and` for the second and later premises:
```
have p(a)
  by axiom 1
 and q(b)
  by lemma 5
hence r(a,b)
  by axiom 4
```

**Equational chain** — when the goal is a pure equation `s = t` and no non-unit clause produces it (either because there are no non-units, or all passes over them have been exhausted):
```
  s
= { by axiom 1 }
  t1
= { by axiom 2 R->L }
  t
```

A complete proof consists of axioms, optional lemmas, and the main goal:
```
Axiom 1: ...

Lemma 5: ...
Proof:
  ...

Goal 1: ...
Proof:
  ...
```

## Fragment

The tool handles the **Horn clause fragment**: clauses with at most one
positive literal, where literals may be equational (`s = t`, `s ≠ t`) or
relational (`P(t̄)`, `¬P(t̄)`). Input is validated on load; a clear error is
reported if any axiom falls outside this fragment.

## How It Works

The input axioms split into two groups:

- **Units** — positive unit clauses (single facts such as `p(a)` or `f(a) = b`).
- **Non-units** — Horn implications `L₁ ∧ … ∧ Lₙ → H` with two or more literals.

The **goal** is the unnegated conjecture. Units start with the axioms and grow as new facts are derived.

**Ordering non-unit clauses** follows Waldmann's position ordering (Lemma 0.6).
The TSTP proof is a DAG; Tälja expands it into a full proof tree with ⊥ at the
root. Each node is assigned a binary position string: left child (positive
provider) gets suffix `0`, right child (negative consumer) gets suffix `1`,
unary inference gets suffix `1`. Non-unit clauses are sorted by the
lexicographic minimum of their leaf positions across all occurrences in the
tree. By Lemma 0.6, this ordering guarantees that when a non-unit clause is
processed, all the units its premises require are already available — a single
ordered pass suffices.

Each non-unit clause is tried two ways:

- **Top-down** — if the head matches the goal, match each premise against Units under the same substitution. If all premises are covered, the proof is done.
- **Bottom-up** — match the premises against Units freely, derive the grounded head, then check whether it reaches the goal by matching or rewriting. If not, add the derived head to Units for later rounds.

**Stall recovery**: if the ordered pass does not reach the goal, every
anonymous equation is named so it can be cited in a rewrite step, and one
further pass is attempted. If that also fails, the goal is discharged as a
pure rewriting problem over the accumulated units.

**Rewriting** uses BFS over unit equations in three places: matching a body literal against a unit (rewrite a known fact until it matches the target), connecting a derived head to the goal, and building equational chains `s = … = t`.

**Proof blocks** take one of two shapes: `have … and … hence …` for relational goals, and `s = {by eq} t₁ = … = t` for equational goals.

**Lemmatization** promotes an anonymous proved fact to a named lemma.

Forced cases:

- An `and`-line must cite a fact by name (non-first premises in a multi-premise step).
- A rewrite step (`by rw`) must cite an equation by name.
- An equational chain cannot embed a `have/hence` derivation inline.

Heuristic cases:

- **DAG sharing** — a fact that would be consumed as the first premise by two or more clauses is named before any of them runs, avoiding duplicated derivations. The scan covers all non-unit clauses so sharing is detected regardless of processing order.
- **Non-ground equational end** — a rewrite path ending at a non-ground equation is extracted as a named equational-chain lemma rather than inlined.

Lemmas are stored in their most general (non-ground) form and instantiated at the point of use. After translation, a post-processing pass removes any lemmas that are not referenced by any goal or other lemma, then renumbers the survivors sequentially.

## Building

Requires GHC and Cabal ([GHCup](https://www.haskell.org/ghcup/) is the
recommended installer).

```
cabal build
cabal install --overwrite-policy=always
```

## Testing

```
cabal test
```
