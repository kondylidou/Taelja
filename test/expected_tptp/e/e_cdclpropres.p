% SZS output start Proof
fof(a1, axiom, p(a), file('test.p', a1)).
fof(a2, axiom, ! [X]: (p(X) => q(X)), file('test.p', a2)).
fof(c, theorem, q(a), inference(mp, [status(thm)], [a2, a1])).
% SZS output end Proof
