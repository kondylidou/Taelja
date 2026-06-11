# Translation Algorithm

## Data

```
-- shared mutable state, accessible to all functions
Units    = sequence + map of UnitEntry { name?, literal, derivation? }

-- fixed inputs
NonUnits = [ (clauseName, L₁ ∧ … ∧ Lₙ → H) ]
goals    = [ conjunct of conjecture ]

ProofBlock = HaveHence [ProofLine]
           | EqChain Term [(RwStep, Term)]
```

## Algorithm

```
translate(tstp):
  (Units, NonUnits, goals) = classify(tstp)
  for goal in goals: main_loop(NonUnits, goal)

main_loop(NonUnits, goal):
  if NonUnits = []: return direct_proof(goal)
  loop:
    for (name, body → head) in NonUnits:
      if matchLit(head, goal) = σ and prove_body(σ, body) = (block, _):
        return block + [Hence goal by name]
      else if prove_body([], body) = (block, σ):
        groundHead = head[σ]
        if literal BFS(groundHead →* goal, all equations) = (rwPath, σ'):
          return (block + [Hence groundHead by name] + rwPath)[σ']
        Units += (nil, groundHead, block + [Hence groundHead by name])
    if |Units| grew: continue
    ensureAllEqNamed()
    for (name, body → head) in NonUnits:
      if matchLit(head, goal) = σ and prove_body(σ, body) = (block, _):
        return block + [Hence goal by name]
      else if prove_body([], body) = (block, σ):
        groundHead = head[σ]
        if literal BFS(groundHead →* goal, all equations) = (rwPath, σ'):
          return (block + [Hence groundHead by name] + rwPath)[σ']
    return direct_proof(goal)

prove_body(σ, [L₁, …, Lₙ]):
  for each Lᵢ: literal BFS(unit →* Lᵢ[σ], named equations)  or failure
  return (combined proof block, accumulated σ)

direct_proof(goal):
  if goal = Eq(s, t): term BFS(s →* t, named equations)
  else:               literal BFS(unit →* goal, named equations)
```

"named equations" = units with a name, so every step is directly citable.
"all equations"   = named + unnamed; unnamed used as stepping stones, named on citation.

## Lemmatization

Forced by format:
- **And-line**: each tail body literal must be cited by name
- **Rewrite step**: equation citations are name-only slots
- **EqChain cites HaveHence**: `= { by name }` holds only a name; no inline embedding

Heuristic (`nonGroundEqEnd` in `make_block`):
- When a rewrite path ends at a non-ground equation, it is extracted as a named EqChain lemma
