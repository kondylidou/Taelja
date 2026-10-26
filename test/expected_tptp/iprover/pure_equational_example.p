% SZS output start Proof
fof(f1, axiom, a = b, file('pure_equational_example.p', ax1)).
fof(f2, axiom, b = c, file('pure_equational_example.p', ax2)).
fof(f3, theorem, a = c, inference(rewrite, [status(thm)], [f2, f1])).
% SZS output end Proof
