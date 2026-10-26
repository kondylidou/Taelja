% SZS output start Proof
fof(f1, axiom, p(a, b), file('tau_shared.p', ax1)).
fof(f2, axiom, q(b, c), file('tau_shared.p', ax2)).
fof(f3, axiom, ! [X0, X1, X2]: ((q(X1, X2) & p(X0, X1)) => r(X0, X2)), file('tau_shared.p', ax3)).
fof(f4, theorem, r(a, c), inference(mp, [status(thm)], [f3, f2, f1])).
% SZS output end Proof
