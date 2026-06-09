# Translation Algorithm

Translates a refutational proof into a structured readable proof for the Horn fragment.

## Setup

```
Units    = { (name, U, nil) | U is a positive unit axiom }
NonUnits = { (name | nil, N, σ) | N = ¬L₁ ∨ … ∨ ¬Lₙ ∨ H is a non-unit axiom }
           // σ = ground substitution from the refutation (ground case) or id (non-ground case)
goal     = the unnegated conjecture
```

## Processing Order

Non-units are processed in topological order of the forward proof DAG, taking the leftmost reducible non-unit at each step. A non-unit is reducible when all its body literals Lᵢ[σ] can be discharged by units already in `Units`.

**Invariant.** When a non-unit is processed, every unit Uᵢ and every unit equation needed to rewrite Uᵢ into the matching body literal Lᵢ[σ] is already in `Units`.

## Helpers

### `ensure_named(l=r)`
Guarantees the equation `l=r` has a name in `Units`, lemmatizing it on the spot if unnamed.

```
function ensure_named(l=r):
  (name, l=r, stored) = entry in Units
  if name ≠ nil: return name
  k = next lemma number
  emit "Lemma k: l=r"
  emit "Proof:" + stored
  Units ← (Units \ {(nil, l=r, stored)}) ∪ {("lemma k", l=r, nil)}
  return "lemma k"
```

### `make_block(U, rw)`
Builds the proof lines for a unit U, optionally followed by rewrite steps.
`rw` is a list of `(l=r, dir)` pairs — names are resolved inside via `ensure_named`.

```
function make_block(U, rw):
  if (nil, U, stored) ∈ Units:
    b = stored                    // inline unnamed U's derivation
  else:
    b = "have U
           by <name of U>"

  if rw = []:
    return b

  cur ← U
  for each (l = r, dir) in rw:
    name ← ensure_named(l=r)
    cur ← cur[l → r]   (or cur[r → l] if dir = R→L)
    b ← b + "hence cur
               by rw name" (+ " R->L" if dir = R→L)
  return b
```

**RL safety.** An equation `l = r` may be applied R→L only when `vars(l) ⊆ vars(r)`,
so that matching `r` binds every variable that appears in `l`. Equations where
`vars(l) ⊄ vars(r)` are LR-only.

### `find_path(s, t, visited)`
DFS search for a rewrite path from term `s` to term `t` using unit equations.

**Precondition.** All equation units in `Units` are named.

```
function find_path(s, t, visited):
  if s = t: return []
  if s ∈ visited: return failure
  for each named equation (name, l=r) in Units:
    for dir ∈ { LR } ∪ { RL | vars(l) ⊆ vars(r) }:
      s' = s[l → r]   (or s[r → l] if dir = RL)
      if s' ≠ s:
        path = find_path(s', t, visited ∪ {s})
        if path ≠ failure:
          return [(name, l=r, dir, s')] + path
  return failure
```

### `rw_chain_to(s, t)`
Finds a rewrite path from `s` to `t` via DFS.
Errors if no path exists — callers rely on the invariant that a path always exists.

```
function rw_chain_to(s, t):
  steps = find_path(s, t, {})
  if steps = failure: error "no rewrite path from s to t"
  return steps              // [(name, l=r, dir, cur)] for each step
```

## Main Loop

```
if NonUnits = ∅:
  if goal is equational (goal = s = t):
    // always use the chain format for equational goals — more readable than have/hence
    steps = rw_chain_to(s, t)
    emit "Goal 1: s = t"
    emit "Proof:"
    emit "  s"
    for (name, l = r, dir, cur) in steps:
      emit "= { by name" (+ " R->L" if dir = R→L) + " }"
      emit "  cur"
  else:
    if ∃ (_, U, _) ∈ Units, σ, rw such that U[σ] →^{rw} goal:
      emit "Goal 1: goal"
      emit "Proof:" + make_block(U, rw)[σ]
    else:
      error "no unit matches goal"

for each (name, N, σ) ∈ NonUnits:

  block = ""
  for i = 1..n:
    (_, Uᵢ, _) = find entry in Units
    σᵢ  = matching substitution s.t. Uᵢ[σᵢ] →^{rwᵢ} Lᵢ[σ·σᵢ]
    rwᵢ = [(name, l=r, dir) from Units] s.t. Uᵢ[σᵢ] →^{rwᵢ} Lᵢ[σ·σᵢ]
    σ   ← σ · σᵢ
    if i = 1:
      block ← make_block(U₁[σ₁], rw₁)
    else:  // i ≥ 2; Lᵢ[σ] must be named
      if (nil, Lᵢ[σ], _) ∈ Units ∨ Lᵢ[σ] ∉ Units:
        k = next lemma number
        emit "Lemma k: Lᵢ[σ]"
        emit "Proof:" + make_block(Uᵢ[σᵢ], rwᵢ)
        Units ← (Units \ { (nil, Lᵢ[σ], _) }) ∪ { ("lemma k", Lᵢ[σ], nil) }
      block ← block + " and Lᵢ[σ]
                         by <name of Lᵢ[σ]>"
  block ← block + "hence H[σ]
                     by <name of N>"

  if ∃ σ' s.t. H[σ][σ'] = goal:
    emit "Goal 1: goal"
    emit "Proof:" + block[σ·σ']
  else:
    Units ← Units ∪ { (nil, H[σ], block[σ]) }
```

## Lemmatization

Lemmatization of a derived positive unit is **forced** in two situations:

- It appears as the **second or later body literal** in an n ≥ 2 hyperresolution step.
- It is **cited as a rewrite step** (`rw`) in either an equational chain or a have/hence proof.

In all other cases lemmatization is **heuristic** (e.g. lemmatize if used at least twice).
