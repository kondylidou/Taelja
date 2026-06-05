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
  for each (name, l = r, dir) in rw:
    name ← ensure_named(l=r)
    cur ← cur[l → r]   (or cur[r → l] if dir = R→L)
    b ← b + "hence cur
               by rw name" (+ " R->L" if dir = R→L)
  return b
```

### `rw_chain_to(s, t)`
Rewrites `s` toward `t` using unit equations from `Units`.

```
function rw_chain_to(s, t):
  cur = s;  steps = []
  while cur ≠ t:
    if (name, l=r, dir) ∈ Units s.t. cur[l→r] ≠ cur  else break
    name ← ensure_named(l=r)
    cur ← cur[l → r]   (or cur[r → l] if dir = R→L)
    steps.append((name, l = r, dir, cur))
  return (cur, steps)
```

## Main Loop

```
if NonUnits = ∅:
  if ∃ (_, U, _) ∈ Units, σ, rw such that U[σ] →^{rw} goal:
    emit "Goal 1: goal"
    emit "Proof:" + make_block(U, rw)[σ]
  else:
    // equational chain from LHS s to RHS t
    (_, steps) = rw_chain_to(s, t)
    emit "Goal 1: s = t"
    emit "Proof:"
    emit "  s"
    for (name, l = r, dir, cur) in steps:
      emit "= { by name" (+ " R->L" if dir = R→L) + " }"
      emit "  cur"

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

  σ' matches H[σ] against goal
  (cur, steps) = rw_chain_to(H[σ][σ'], goal)
  for (name, l = r, dir, s) in steps:
    block ← block + "hence s
                        by rw name" (+ " R->L" if dir = R→L)
  if cur = goal:
    emit "Goal 1: goal"
    emit "Proof:" + block[σ·σ']
  else:
    Units ← Units ∪ { (nil, H[σ], block) }
```

## Lemmatization

Lemmatization of a derived positive unit is **forced** in two situations:

- It appears as the **second or later body literal** in an n ≥ 2 hyperresolution step.
- It is **cited as a rewrite step** (`rw`) in either an equational chain or a have/hence proof.

In all other cases lemmatization is **heuristic** (e.g. lemmatize if used at least twice).
