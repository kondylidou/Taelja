% SZS output start Proof
fof(f1, axiom, p(a), file('test_axioms_contradictory.p', f1)).
fof(goal_1, theorem, p(a), inference(instantiate, [status(thm)], [f1])).
% SZS output end Proof
