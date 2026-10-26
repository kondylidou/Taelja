% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = X0, file('thesis_example_both_lemmas.p', ax1)).
fof(f2, axiom, ! [X0]: f(X0) = g(X0), file('thesis_example_both_lemmas.p', ax2)).
fof(f3, axiom, ! [X0]: (g(X0) = X0 => q(X0)), file('thesis_example_both_lemmas.p', ax3)).
fof(f4, axiom, s(a), file('thesis_example_both_lemmas.p', ax4)).
fof(f5, axiom, ! [X0]: ((q(X0) & s(X0)) => p(X0)), file('thesis_example_both_lemmas.p', ax5)).
fof(s1, plain, g(a) = f(a), inference(instantiate, [status(thm)], [f2])).
fof(lemma_6, lemma, g(a) = a, inference(rewrite, [status(thm)], [f1, s1])).
fof(s2, plain, q(a), inference(mp, [status(thm)], [f3, lemma_6])).
fof(f6, theorem, p(a), inference(mp, [status(thm)], [f5, s2, f4])).
% SZS output end Proof
