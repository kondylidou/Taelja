% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = g(X0), file('/home/user/Developer/Taelja/test/input/test_eqchain_in_havehence.p', unknown)).
fof(f2, axiom, ! [X0]: g(X0) = h(X0), file('/home/user/Developer/Taelja/test/input/test_eqchain_in_havehence.p', unknown)).
fof(f3, axiom, ! [X0]: (f(X0) = h(X0) => p(X0)), file('/home/user/Developer/Taelja/test/input/test_eqchain_in_havehence.p', unknown)).
fof(lemma_4, lemma, ! [X] : f(X) = h(X), inference(rewrite, [status(thm)], [f2, f1])).
fof(s1, plain, f(a) = h(a), inference(instantiate, [status(thm)], [lemma_4])).
fof(f4, theorem, p(a), inference(mp, [status(thm)], [f3, s1])).
% SZS output end Proof
