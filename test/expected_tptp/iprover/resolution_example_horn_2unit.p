% SZS output start Proof
fof(f1, axiom, p(a), file('resolution_example_horn_2unit.p', ax1)).
fof(f2, axiom, q(b), file('resolution_example_horn_2unit.p', ax2)).
fof(f3, axiom, ! [X0, X1]: ((q(X1) & p(X0)) => r(X0, X1)), file('resolution_example_horn_2unit.p', ax3)).
fof(f4, theorem, r(a, b), inference(mp, [status(thm)], [f3, f2, f1])).
% SZS output end Proof
