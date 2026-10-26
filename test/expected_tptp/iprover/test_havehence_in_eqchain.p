% SZS output start Proof
fof(f1, axiom, p(a), file('test_havehence_in_eqchain.p', f1)).
fof(f2, axiom, q(a), file('test_havehence_in_eqchain.p', f2)).
fof(f3, axiom, ! [X0]: (p(X0) => f(X0) = g(X0)), file('test_havehence_in_eqchain.p', f3)).
fof(f4, axiom, ! [X0]: (q(X0) => g(X0) = h(X0)), file('test_havehence_in_eqchain.p', f4)).
fof(lemma_5, lemma, g(a) = h(a), inference(mp, [status(thm)], [f4, f2])).
fof(lemma_6, lemma, f(a) = g(a), inference(mp, [status(thm)], [f3, f1])).
fof(s1, plain, s(f(a)) = s(g(a)), inference(instantiate, [status(thm)], [lemma_6])).
fof(f5, theorem, s(f(a)) = s(h(a)), inference(rewrite, [status(thm)], [lemma_5, s1])).
% SZS output end Proof
