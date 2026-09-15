% SZS output start Proof
fof(f2, axiom, f(b) = c, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', unknown)).
fof(f3, axiom, ! [X0]: (f(X0) = c => g(X0) = c), file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', unknown)).
fof(f1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', unknown)).
fof(f4, axiom, g(a) = c => h(a) = c, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', unknown)).
fof(s1, plain, g(b) = c, inference(mp, [status(thm)], [f3, f2])).
fof(s2, plain, g(a) = c, inference(rewrite, [status(thm)], [f1, s1])).
fof(f5, theorem, h(a) = c, inference(mp, [status(thm)], [f4, s2])).
% SZS output end Proof
