% SZS output start Proof
fof(c_49, plain, p(a), file('test_trivial_body_atom.p', a1)).
fof(c_50, plain, r(a), file('test_trivial_body_atom.p', a2)).
fof(c_51, plain, ! [X0, X1]: (X0 != X1 | ~ p(X0) | ~ r(X1) | q(X0)), file('test_trivial_body_atom.p', a3)).
fof(goal_1, theorem, q(a), inference(mp, [status(thm)], [c_51, c_49, c_50])).
% SZS output end Proof
