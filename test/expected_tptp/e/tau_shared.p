% SZS output start Proof
fof(ax1, axiom, p(a, b), file('test/input/tau_shared.p', ax1)).
fof(ax2, axiom, q(b, c), file('test/input/tau_shared.p', ax2)).
fof(ax3, axiom, ! [X1, X2, X3]: ((p(X1, X2) & q(X2, X3)) => r(X1, X3)), file('test/input/tau_shared.p', ax3)).
fof(goal, theorem, r(a, c), inference(mp, [status(thm)], [ax3, ax1, ax2])).
% SZS output end Proof
