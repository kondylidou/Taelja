% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/paper_heu.p', unknown)).
fof(f2, axiom, ! [X0]: g(X0) = f(X0), file('/home/user/Developer/Taelja/test/input/paper_heu.p', unknown)).
fof(f3, axiom, g(a) = a => p(g(a)), file('/home/user/Developer/Taelja/test/input/paper_heu.p', unknown)).
fof(lemma_4, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [f1, f2])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_4])).
fof(f4, theorem, p(g(a)), inference(mp, [status(thm)], [f3, s1])).
% SZS output end Proof
