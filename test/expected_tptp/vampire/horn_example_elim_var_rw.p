% SZS output start Proof
fof(f1, axiom, ! [X0]: q(a, X0), file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p')).
fof(f3, axiom, ! [X0]: g(X0) = c, file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p')).
fof(f2, axiom, ! [X0, X1]: (q(X0, X1) => f(X0) = g(X1)), file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p')).
fof(s1, plain, ! [X] : f(a) = g(X), inference(mp, [status(thm)], [f2, f1])).
fof(f4, theorem, f(a) = c, inference(rewrite, [status(thm)], [f3, s1])).
% SZS output end Proof
