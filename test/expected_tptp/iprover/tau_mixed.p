% SZS output start Proof
fof(f1, axiom, q(a), file('tau_mixed.p', ax1)).
fof(f2, axiom, ! [X0]: f(X0) = X0, file('tau_mixed.p', ax2)).
fof(f3, axiom, ! [X0]: f(X0) = g(X0), file('tau_mixed.p', ax3)).
fof(f4, axiom, ! [X0]: ((g(X0) = X0 & q(X0)) => p(g(a))), file('tau_mixed.p', ax4)).
fof(s1, plain, ! [X] : g(X) = f(X), inference(instantiate, [status(thm)], [f3])).
fof(lemma_5, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [f2, s1])).
fof(s2, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_5])).
fof(f5, theorem, p(g(a)), inference(mp, [status(thm)], [f4, s2, f1])).
% SZS output end Proof
