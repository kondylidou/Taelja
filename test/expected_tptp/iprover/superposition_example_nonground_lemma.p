% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = X0, file('superposition_example_nonground_lemma.p', ax1)).
fof(f2, axiom, ! [X0]: f(X0) = g(X0), file('superposition_example_nonground_lemma.p', ax2)).
fof(f3, axiom, ! [X0]: (g(X0) = X0 => p(g(X0))), file('superposition_example_nonground_lemma.p', ax3)).
fof(s1, plain, ! [X] : g(X) = f(X), inference(instantiate, [status(thm)], [f2])).
fof(lemma_4, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [f1, s1])).
fof(s2, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_4])).
fof(f4, theorem, p(g(a)), inference(mp, [status(thm)], [f3, s2])).
% SZS output end Proof
