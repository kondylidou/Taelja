% SZS output start Proof
fof(f1, axiom, p(a), file('e_cdclpropres.p', a1)).
fof(f2, axiom, ! [X0]: (p(X0) => q(X0)), file('e_cdclpropres.p', a2)).
fof(f3, theorem, q(a), inference(mp, [status(thm)], [f2, f1])).
% SZS output end Proof
