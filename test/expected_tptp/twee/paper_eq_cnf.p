% SZS output start Proof
cnf(c2, axiom, g(X) = f(X), file('/home/user/Developer/Taelja/test/input/paper_eq_cnf.p', ax2)).
cnf(c3, axiom, f(X2) = X2, file('/home/user/Developer/Taelja/test/input/paper_eq_cnf.p', ax1)).
fof(lemma_3, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [c3, c2])).
fof(s1, plain, g(g(a)) = g(a), inference(instantiate, [status(thm)], [lemma_3])).
fof(goal_1, theorem, g(g(a)) = a, inference(rewrite, [status(thm)], [lemma_3, s1])).
% SZS output end Proof
