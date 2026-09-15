% SZS output start Proof
fof(ax2, axiom, ! [X1]: g(X1) = f(X1), file('/home/user/Developer/Taelja/test/input/superposition_example_nonground_lemma.p', ax2)).
fof(ax1, axiom, ! [X1]: f(X1) = X1, file('/home/user/Developer/Taelja/test/input/superposition_example_nonground_lemma.p', ax1)).
fof(ax3, axiom, ! [X1]: (g(X1) = X1 => p(g(X1))), file('/home/user/Developer/Taelja/test/input/superposition_example_nonground_lemma.p', ax3)).
fof(lemma_4, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [ax1, ax2])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_4])).
fof(goal, theorem, p(g(a)), inference(mp, [status(thm)], [ax3, s1])).
% SZS output end Proof
