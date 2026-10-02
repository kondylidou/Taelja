% SZS output start Proof
fof(f2, axiom, ! [X1, X2]: (q(X1, X2) => f(X1) = g(X2)), file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p', f2)).
fof(f3, axiom, ! [X1]: g(X1) = c, file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p', f3)).
fof(f1, axiom, ! [X1]: q(a, X1), file('/home/user/Developer/Taelja/test/input/horn_example_elim_var_rw.p', f1)).
fof(s1, plain, ! [X] : f(a) = g(X), inference(mp, [status(thm)], [f2, f1])).
fof(f4, theorem, f(a) = c, inference(rewrite, [status(thm)], [f3, s1])).
% SZS output end Proof
