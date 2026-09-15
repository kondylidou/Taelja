% SZS output start Proof
fof(f4, axiom, ! [X0]: f(X0) = g(X0), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p')).
fof(f2, axiom, ! [X0]: p(f(X0)), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p')).
fof(f3, axiom, ! [X0]: q(f(X0)), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p')).
fof(f1, axiom, ! [X0]: ((p(X0) & q(X0)) => X0 = zero), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p')).
fof(s1, plain, q(f(a)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_5, lemma, q(g(a)), inference(rewrite, [status(thm)], [f4, s1])).
fof(s2, plain, p(f(a)), inference(instantiate, [status(thm)], [f2])).
fof(s3, plain, p(g(a)), inference(rewrite, [status(thm)], [f4, s2])).
fof(f5, theorem, g(a) = zero, inference(mp, [status(thm)], [f1, s3, lemma_5])).
% SZS output end Proof
