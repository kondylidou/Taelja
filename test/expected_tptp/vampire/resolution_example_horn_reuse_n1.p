% SZS output start Proof
fof(f1, axiom, ! [X0]: p(X0), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p')).
fof(f2, axiom, ! [X0]: q(b, X0), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p')).
fof(f3, axiom, ! [X0, X1]: ((q(X0, X1) & p(X1)) => q(f(X0), X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p')).
fof(f4, axiom, ! [X0]: (q(f(b), X0) => r(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p')).
fof(s1, plain, q(b,a), inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, p(a), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [f3, s1, s2])).
fof(f5, theorem, r(a), inference(mp, [status(thm)], [f4, s3])).
% SZS output end Proof
