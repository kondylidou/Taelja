% SZS output start Proof
cnf(c4, axiom, g(X) = f(X), file('/home/user/Developer/Taelja/test/input/paper_eq.p', ax2)).
cnf(c5, axiom, f(X2) = X2, file('/home/user/Developer/Taelja/test/input/paper_eq.p', ax1)).
fof(lemma_3, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [c5, c4])).
fof(s1, plain, g(g(a)) = g(a), inference(instantiate, [status(thm)], [lemma_3])).
fof(c1, theorem, g(g(a)) = a, inference(rewrite, [status(thm)], [lemma_3, s1])).
% SZS output end Proof
