% SZS output start Proof
fof(f1, axiom, c = a, file('superposition_example_unit1.p', ax1)).
fof(f2, axiom, a = b, file('superposition_example_unit1.p', ax2)).
fof(s1, plain, f(c) = f(a), inference(instantiate, [status(thm)], [f1])).
fof(f3, theorem, f(c) = f(b), inference(rewrite, [status(thm)], [f2, s1])).
% SZS output end Proof
