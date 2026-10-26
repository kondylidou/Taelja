% SZS output start Proof
fof(f1, axiom, a = b, file('superposition_example_clausal1.p', ax1)).
fof(f2, axiom, b = c, file('superposition_example_clausal1.p', ax2)).
fof(f3, axiom, ! [X0]: f(X0) = X0, file('superposition_example_clausal1.p', ax3)).
fof(s1, plain, d = f(d), inference(instantiate, [status(thm)], [f3])).
fof(s2, plain, a = c, inference(rewrite, [status(thm)], [f2, f1])).
fof(f4, theorem, d = f(d) & a = c, inference(conclude, [status(thm)], [s1, s2])).
% SZS output end Proof
