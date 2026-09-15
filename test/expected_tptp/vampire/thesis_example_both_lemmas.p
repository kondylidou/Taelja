% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas.p', ax1)).
fof(f2, axiom, ! [X0]: g(X0) = f(X0), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas.p', ax2)).
fof(f3, axiom, ! [X0]: (g(X0) = X0 => q(X0)), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas.p', ax3)).
fof(f4, axiom, s(a), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas.p', ax4)).
fof(f5, axiom, ! [X0]: ((s(X0) & q(X0)) => p(X0)), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas.p', ax5)).
fof(lemma_6, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [f1, f2])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, q(a), inference(mp, [status(thm)], [f3, s1])).
fof(f6, theorem, p(a), inference(mp, [status(thm)], [f5, f4, lemma_7])).
% SZS output end Proof
