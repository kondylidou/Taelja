% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/test_trivial_body_atom.p')).
fof(f2, axiom, r(a), file('/home/user/Developer/Taelja/test/input/test_trivial_body_atom.p')).
fof(f3, axiom, ! [X0, X1]: (~ p(X0) | X0 != X1 | ~ r(X1) | q(X0)), file('/home/user/Developer/Taelja/test/input/test_trivial_body_atom.p')).
fof(goal_1, theorem, q(a), inference(mp, [status(thm)], [f3, f1, f2])).
% SZS output end Proof
