% SZS output start Proof
fof(f1, axiom, p(a), file('test_axioms_contradictory.p', f1)).
fof(f2, axiom, ~ p(a), file('test_axioms_contradictory.p', f2)).
fof(s1, plain, $false, inference(mp, [status(thm)], [f2, f1])).
fof(f3, theorem, q(b), inference(contradiction, [status(thm)], [s1])).
% SZS output end Proof
