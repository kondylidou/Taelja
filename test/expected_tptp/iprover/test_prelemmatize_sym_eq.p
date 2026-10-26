% SZS output start Proof
fof(f1, axiom, h(a) = k(a), file('test_prelemmatize_sym_eq.p', f1)).
fof(f2, axiom, ! [X0]: (h(X0) = k(X0) => p(X0)), file('test_prelemmatize_sym_eq.p', f2)).
fof(f3, axiom, ! [X0]: (h(X0) = k(X0) => q(X0)), file('test_prelemmatize_sym_eq.p', f3)).
fof(f4, axiom, ! [X0]: ((q(X0) & p(X0)) => r(X0)), file('test_prelemmatize_sym_eq.p', f4)).
fof(lemma_5, lemma, p(a), inference(mp, [status(thm)], [f2, f1])).
fof(s1, plain, q(a), inference(mp, [status(thm)], [f3, f1])).
fof(f5, theorem, r(a), inference(mp, [status(thm)], [f4, s1, lemma_5])).
% SZS output end Proof
