% SZS output start Proof
fof(f1, axiom, ! [X0]: q(a, X0), file('horn_example_elim_var_rw.p', f1)).
fof(f2, axiom, ! [X0, X1]: (q(X0, X1) => f(X0) = g(X1)), file('horn_example_elim_var_rw.p', f2)).
fof(f3, axiom, ! [X0]: g(X0) = c, file('horn_example_elim_var_rw.p', f3)).
fof(s1, plain, q(a,a), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, f(a) = g(a), inference(mp, [status(thm)], [f2, s1])).
fof(f4, theorem, c = f(a), inference(rewrite, [status(thm)], [f3, s2])).
% SZS output end Proof
