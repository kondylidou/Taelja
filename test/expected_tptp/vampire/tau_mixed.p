% SZS output start Proof
fof(f1, axiom, q(a), file('test/input/tau_mixed.p', unknown)).
fof(f2, axiom, ! [X0]: f(X0) = X0, file('test/input/tau_mixed.p', unknown)).
fof(f3, axiom, ! [X0]: g(X0) = f(X0), file('test/input/tau_mixed.p', unknown)).
fof(f4, axiom, ! [X0]: ((q(X0) & g(X0) = X0) => p(g(a))), file('test/input/tau_mixed.p', unknown)).
fof(lemma_5, lemma, ! [X] : g(X) = X, inference(rewrite, [status(thm)], [f2, f3])).
fof(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_5])).
fof(f5, theorem, p(g(a)), inference(mp, [status(thm)], [f4, f1, s1])).
% SZS output end Proof
