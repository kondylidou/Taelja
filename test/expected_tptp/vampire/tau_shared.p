% SZS output start Proof
fof(f1, axiom, p(a, b), file('test/input/tau_shared.p', unknown)).
fof(f2, axiom, q(b, c), file('test/input/tau_shared.p', unknown)).
fof(f3, axiom, ! [X0, X1, X2]: ((p(X0, X1) & q(X1, X2)) => r(X0, X2)), file('test/input/tau_shared.p', unknown)).
fof(f4, theorem, r(a, c), inference(mp, [status(thm)], [f3, f1, f2])).
% SZS output end Proof
