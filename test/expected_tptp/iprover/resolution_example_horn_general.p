% SZS output start Proof
fof(f1, axiom, s(a), file('resolution_example_horn_general.p', ax1)).
fof(f2, axiom, ! [X0]: (s(X0) => p(X0)), file('resolution_example_horn_general.p', ax2)).
fof(f3, axiom, t(b), file('resolution_example_horn_general.p', ax3)).
fof(f4, axiom, ! [X1]: (t(X1) => q(X1)), file('resolution_example_horn_general.p', ax4)).
fof(f5, axiom, ! [X0, X1]: ((q(X1) & p(X0)) => r(X0, X1)), file('resolution_example_horn_general.p', ax5)).
fof(lemma_6, lemma, p(a), inference(mp, [status(thm)], [f2, f1])).
fof(s1, plain, q(b), inference(mp, [status(thm)], [f4, f3])).
fof(f6, theorem, r(a, b), inference(mp, [status(thm)], [f5, s1, lemma_6])).
% SZS output end Proof
