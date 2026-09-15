% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', unknown)).
fof(f2, axiom, ! [X0]: (p(X0) => q(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', unknown)).
fof(f3, axiom, ! [X0]: (q(X0) => r(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', unknown)).
fof(s1, plain, q(a), inference(mp, [status(thm)], [f2, f1])).
fof(f4, theorem, r(a), inference(mp, [status(thm)], [f3, s1])).
% SZS output end Proof
