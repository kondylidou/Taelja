# Taelja

Taelja converts Horn resolution/superposition refutation proofs in TSTP format
into structured, human-readable hyperresolution proofs.

It takes the TSTP output of a prover such as Vampire or E and produces a
`have … and … hence … by axiom N` proof.

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

Requires GHC 9.6 and Cabal 3.

```
cabal build
```

## Usage

```
cabal run taelja -- <proof-file.tstp>
cabal run taelja -- --debug <proof-file.tstp>
```

`--debug` prints the parsed TSTP units, the refutation proof tree, and the
Phase 1 classification (units and non-units with their positions) before the
proof output.

## Testing

```
cabal test
```

The test suite runs golden-file tests against TSTP proofs produced by both
Vampire (`test/baseline_vampire/`) and E (`test/baseline_e/`).
Expected outputs live in `test/expected_vampire/` (Vampire) and `test/expected_e/` (E).

To regenerate expected files after an intentional output change:

```
cabal test --test-option=--accept
```

## Algorithm

The conversion proceeds in three phases:

- **Phase 0** (`ProofTree.hs`): build the refutation proof tree from the flat
  TSTP unit list, assigning bit-string positions to every node (left child
  appends `0`, right child appends `1`).

- **Phase 1** (`Translate.hs` → `phaseOne`): visit leaves in left-first DFS
  order (≺-increasing position order). Positive unit clauses become
  *electrons* in `Units`; everything else becomes a nucleus in `NonUnits`.

- **Phase 2** (`runPhase2`): if `NonUnits` is empty, prove the goal directly
  from the unit set via matching and equational rewriting.

- **Phase 3** (`runPhase3`): for each nucleus in ≺-increasing order, collect
  `ELECTRONS(p, Units)` — all units at positions strictly before `p` — and
  use `MATCH` to find electrons that instantiate the body literals. Assemble
  the `have/and/hence` proof block. Derived intermediate units are added to
  `Units` with their proof position so they can serve as electrons for later
  nuclei.

## Module structure

| Module | Role |
|--------|------|
| `Types.hs` | Core data types: `Term`, `Literal`, `Clause`, `UnitEntry`, `ProofBlock`, `StructuredProof` |
| `Helpers.hs` | Shared functions: substitution, matching, rewriting, literal utilities |
| `ProofTree.hs` | Phase 0: build and label the refutation proof tree |
| `Convert.hs` | Phases 1–3: the main translation algorithm |
| `Emitter.hs` | Render a `StructuredProof` to the output text format |
| `Debug.hs` | Optional debug dumps: TSTP units, proof tree, Phase 1 result |
