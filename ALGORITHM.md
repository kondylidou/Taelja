# Translation Algorithm

## State

```
Units    = { ("axiom i", U, nil) | U is a positive unit axiom }
NonUnits = { ("axiom i", L₁ ∧ … ∧ Lₙ → H) | clause is non-unit }
goals    = unnegated conjecture conjuncts
```

`Units` grows during proof search. `NonUnits` and `goals` are fixed.
Unnamed entries carry their derivation so they can be promoted to a lemma later.

## Helpers

**`ensure_named(L)`** — guarantees L has a name; emits a lemma if not.

```
function ensure_named(L):
  (name, L, stored) = Units[L]
  if name ≠ nil: return name
  k = next lemma number
  emit "Lemma k: L" + "Proof:" + stored
  Units[L] ← ("lemma k", L, nil)
  return "lemma k"
```

**`make_block(ue, rw)`** — builds the proof block for unit `ue`, extended by rewrite steps `rw`.

```
function make_block(ue, rw):
  if rw ≠ [] and last(rw).lit = Eq(l, r) with vars(Eq(l,r)) ≠ ∅:
    if Eq(l,r) ∉ Units:
      eqBlock = EqChain(l, find_path(l, r))   if find_path succeeds,
              | build_inline(ue, rw)           otherwise
      Units ← Units ∪ { (nil, Eq(l,r), eqBlock) }
    return HaveHence [ Have Eq(l,r) by ensure_named(Eq(l,r)) ]
  return build_inline(ue, rw)

function build_inline(ue, rw):
  base = case ue.deriv:
    HaveHence(ls) → ls
    EqChain       → [ Have ue.unit by ensure_named(ue.unit) ]   // can't inline EqChain into HaveHence
    nil           → [ Have ue.unit by ue.name ]
  for (RwStep(_, (l,r), dir), next) ∈ rw:
    base ← base + [ Hence next by rw ensure_named(Eq(l,r)) (RL if dir = RL) ]
  return HaveHence(base)
```

**`find_path(s, t)`** — term-level BFS from `s` to `t` using named equations.

```
function find_path(s, t):
  eqs   = { (name, l, r) | (name ≠ nil, Eq(l,r), _) ∈ Units, vars(r) ⊆ vars(l) }
  bound = max(size(s), size(t)) + max { size(l) | (_, l, _) ∈ eqs }
  BFS from s, applying eqs LR and RL (RL only when vars(l) ⊆ vars(r)),
       pruning above bound and revisited terms,
       returning path on success when cur = t, failure if frontier exhausted
```

**`body_lit_match(target)`** — finds a unit that matches or rewrites to `target`.

```
function body_lit_match(target):
  try one-sided matching against each ue ∈ Units:
    if ∃ σUnit, rw s.t. ue.unit →^{rw} target  (named eqs):
      return (ue, σUnit, rw, σClause = [])
  try two-sided unification against each ue ∈ Units:
    if ∃ σ, rw s.t. unify(target, ue.unit →^{rw}) (named eqs):
      σClause = { (v,t) ∈ σ | v ∈ vars(target) }    // propagates into running clause subst
      σUnit   = { (v,t) ∈ σ | v ∉ vars(target) }    // applied to the stored proof block
      return (ue, σUnit, rw, σClause)
  return failure
```

## Algorithm

```
for each goal:

  loop:
    for each (name, L₁ ∧ … ∧ Lₙ → H) ∈ NonUnits:

      ┌ top-down: head matches goal, prove body under σH
      │ if H[σH] = goal for some σH:
      │   if n ≥ 2: prelemmatize unnamed Lᵢ[σH] for i = 2..n
      │   σ = σH
      │   for i = 1..n:
      │     (ue, blkSubst, rw, δ) = body_lit_match(Lᵢ[σ])   or fall through
      │     σ ← σ · δ
      │     if i = 1: block ← make_block(ue, rw)[blkSubst]
      │     else:     block ← block + [ And Lᵢ[σ] by ensure_named(Lᵢ[σ]) ]
      │   return block + [ Hence goal by name ]
      │
      └ bottom-up: prove body freely, then connect derived head to goal
        σ = []
        for i = 1..n:
          (ue, blkSubst, rw, δ) = body_lit_match(Lᵢ[σ])   or skip this clause
          σ ← σ · δ
          if i = 1: block ← make_block(ue, rw)[blkSubst]
          else:     block ← block + [ And Lᵢ[σ] by ensure_named(Lᵢ[σ]) ]
        groundH = H[σ]
        block ← block + [ Hence groundH by name ]

        if groundH matches goal with σ':
          return block[σ']
        if literal BFS(groundH →* goal, all equations) = (rw_path, σ'):
          return extend_with_rw(block, rw_path)[σ']

        // uppercase vars are unit vars (clause vars are c-prefixed by freshenClause)
        unit_free = { v ∈ vars(groundH) | v starts with uppercase }
        if unit_free = ∅:
          Units ← Units ∪ { (nil, groundH, block) }
        else:
          terms = ground_subterms(goal)
          if terms = ∅:
            Units ← Units ∪ { (nil, groundH, block) }  // findMatchingUnit will bind unit_free at match time
          else:
            for each ground instantiation σ' of unit_free over terms:
              Units ← Units ∪ { (nil, groundH[σ'], block[σ']) }

    if |Units| grew: continue

    for each (nil, Eq(l,r), _) ∈ Units: ensure_named(Eq(l,r))
    one final pass over NonUnits (same logic as above, no further loop)

  // no non-unit clause matched
  if goal = Eq(s, t):
    return EqChain(s, find_path(s, t))
  else:
    (ue, σ, rw) = find_matching_unit(goal, Units)
    return make_block(ue, rw)[σ]
```

## Lemmatization

Forced by format:
- **And-line**: each tail body literal must be cited by name
- **Rewrite step**: equation citations are name-only slots
- **EqChain cites HaveHence**: `= { by name }` holds only a name; no inline embedding

Heuristic (`nonGroundEqEnd` in `make_block`):
- When a rewrite path ends at a non-ground equation, it is extracted as a named EqChain lemma
