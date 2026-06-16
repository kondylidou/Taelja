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

**Equational chain** — when the goal is a pure equation `s = t` not produced by any non-unit clause:
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

**Ordering non-unit clauses**: the TSTP proof is a DAG; Tälja expands it into a full proof tree and assigns each non-unit clause a position based on where it appears as a leaf. Sorting by the lexicographically earliest leaf position guarantees that when a clause is processed, all units its premises require are already available — a single ordered pass suffices.

Each non-unit clause is tried two ways:

- **Top-down** — if the head matches the goal, prove each premise against Units under that substitution. If all premises are covered, the proof is done. Falls back to bottom-up when the substitution forces a body target that requires a derived-lemma rewrite.
- **Bottom-up** — match premises against Units freely, derive the grounded head, then connect it to the goal by matching or rewriting. If it doesn't reach the goal, add it to Units for later rounds.

**Stall recovery**: if the ordered pass does not reach the goal, every
anonymous equation is named so it can be cited in a rewrite step, and one
further pass is attempted. If that also fails, the goal is discharged as a
pure rewriting problem over the accumulated units.

**Rewriting** uses BFS over unit equations in three places: matching a body literal against a unit, connecting a derived head to the goal, and building equational chains. Each equation may be applied left-to-right or right-to-left; the direction that would introduce unbound variables is skipped. Body rewrites via axiom equations are valid in place. Body rewrites via derived lemma equations are an equational complication: the rewrite belongs on the head after the inference, not on the body literal, so top-down falls back to bottom-up in that case.

**Lemmatization** promotes an anonymous proved fact to a named lemma.

Forced cases:

- An `and`-line must cite a fact by name (non-first premises in a multi-premise step).
- A rewrite step (`by rw`) must cite an equation by name.
- An equational chain cannot embed a `have/hence` derivation inline.

Heuristic cases:

- **DAG sharing** — a fact that would be consumed as the first premise by two or more clauses is named before any of them runs, avoiding duplicated derivations.
- **Non-ground equational end** — a rewrite path ending at a non-ground equation is extracted as a named equational-chain lemma rather than inlined.

Lemmas are stored in their most general (non-ground) form and instantiated at the point of use. After translation, unreferenced lemmas are removed and the survivors are renumbered sequentially.

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
