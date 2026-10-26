% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = X0, file('paper_heu.p', ax1)).
fof(f2, axiom, ! [X0]: f(X0) = g(X0), file('paper_heu.p', ax2)).
fof(f3, axiom, a = g(a) => p(g(a)), file('paper_heu.p', ax3)).
fof(s1, plain, a = f(a), inference(instantiate, [status(thm)], [f1])).
fof(lemma_4, lemma, a = g(a), inference(rewrite, [status(thm)], [f2, s1])).
fof(f4, theorem, p(g(a)), inference(mp, [status(thm)], [f3, lemma_4])).
% SZS output end Proof
