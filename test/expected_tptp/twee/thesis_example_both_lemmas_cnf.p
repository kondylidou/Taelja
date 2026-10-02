% SZS output start Proof
cnf(c2, axiom, s(a), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas_cnf.p', ax4)).
cnf(c3, axiom, g(X) = f(X), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas_cnf.p', ax2)).
cnf(c4, axiom, f(X2) = X2, file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas_cnf.p', ax1)).
cnf(c6, axiom, q(X2) | g(X2) != X2, file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas_cnf.p', ax3)).
cnf(c8, axiom, p(X2) | ~ s(X2) | ~ q(X2), file('/home/user/Developer/Taelja/test/input/thesis_example_both_lemmas_cnf.p', ax5)).
fof(lemma_6, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [c4, c3])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, q(a), inference(mp, [status(thm)], [c6, s1])).
fof(goal_1, theorem, p(a), inference(mp, [status(thm)], [c8, c2, lemma_7])).
% SZS output end Proof
