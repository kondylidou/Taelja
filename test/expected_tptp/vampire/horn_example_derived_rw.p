% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p')).
fof(f2, axiom, q(b), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p')).
fof(f3, axiom, ! [X0]: (p(X0) => f(X0) = c), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p')).
fof(f4, axiom, ! [X0]: (q(X0) => a = X0), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p')).
fof(lemma_5, lemma, a = b, inference(mp, [status(thm)], [f4, f2])).
fof(s1, plain, f(a) = c, inference(mp, [status(thm)], [f3, f1])).
fof(f5, theorem, f(b) = c, inference(rewrite, [status(thm)], [lemma_5, s1])).
% SZS output end Proof
