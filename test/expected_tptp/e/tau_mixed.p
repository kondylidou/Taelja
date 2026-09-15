% SZS output start Proof
fof(ax1, axiom, q(a), file('test/input/tau_mixed.p', ax1)).
fof(ax3, axiom, ! [X1]: g(X1) = f(X1), file('test/input/tau_mixed.p', ax3)).
fof(ax2, axiom, ! [X1]: f(X1) = X1, file('test/input/tau_mixed.p', ax2)).
fof(ax4, axiom, ! [X1]: ((q(X1) & g(X1) = X1) => p(g(a))), file('test/input/tau_mixed.p', ax4)).
fof(lemma_5, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [ax2, ax3])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_5])).
fof(goal, theorem, p(g(a)), inference(mp, [status(thm)], [ax4, ax1, s1])).
% SZS output end Proof
