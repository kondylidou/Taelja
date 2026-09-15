% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/test_havehence_in_eqchain.p')).
fof(f3, axiom, ! [X0]: (p(X0) => f(X0) = g(X0)), file('/home/user/Developer/Taelja/test/input/test_havehence_in_eqchain.p')).
fof(f2, axiom, q(a), file('/home/user/Developer/Taelja/test/input/test_havehence_in_eqchain.p')).
fof(f4, axiom, ! [X0]: (q(X0) => g(X0) = h(X0)), file('/home/user/Developer/Taelja/test/input/test_havehence_in_eqchain.p')).
fof(lemma_5, lemma, f(a) = g(a), inference(mp, [status(thm)], [f3, f1])).
fof(lemma_6, lemma, g(a) = h(a), inference(mp, [status(thm)], [f4, f2])).
fof(s1, plain, s(f(a)) = s(g(a)), inference(instantiate, [status(thm)], [lemma_5])).
fof(f5, theorem, s(f(a)) = s(h(a)), inference(rewrite, [status(thm)], [lemma_6, s1])).
% SZS output end Proof
