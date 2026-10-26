% SZS output start Proof
fof(f1, axiom, ! [X0]: s(X0), file('resolution_example_horn_reuse_forced.p', ax1)).
fof(f2, axiom, ! [X1]: (s(X1) => q(b, X1)), file('resolution_example_horn_reuse_forced.p', ax2)).
fof(f3, axiom, ! [X1]: (s(X1) => p(X1)), file('resolution_example_horn_reuse_forced.p', ax3)).
fof(f4, axiom, ! [X1, X2]: ((p(X2) & q(X1, X2)) => r(X1, X2)), file('resolution_example_horn_reuse_forced.p', ax4)).
fof(s1, plain, s(a), inference(instantiate, [status(thm)], [f1])).
fof(lemma_5, lemma, q(b,a), inference(mp, [status(thm)], [f2, s1])).
fof(s2, plain, s(a), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, p(a), inference(mp, [status(thm)], [f3, s2])).
fof(f5, theorem, r(b, a), inference(mp, [status(thm)], [f4, s3, lemma_5])).
% SZS output end Proof
