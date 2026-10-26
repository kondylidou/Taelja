% SZS output start Proof
fof(f1, axiom, b = a, file('test_eq_symmetry.p', eq_axiom)).
fof(f2, theorem, b = a, inference(instantiate, [status(thm)], [f1])).
% SZS output end Proof
