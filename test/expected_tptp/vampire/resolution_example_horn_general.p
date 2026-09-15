% SZS output start Proof
fof(f3, axiom, t(b), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p')).
fof(f4, axiom, ! [X0]: (t(X0) => q(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p')).
fof(f1, axiom, s(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p')).
fof(f2, axiom, ! [X0]: (s(X0) => p(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p')).
fof(f5, axiom, ! [X0, X1]: ((p(X0) & q(X1)) => r(X0, X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p')).
fof(lemma_6, lemma, q(b), inference(mp, [status(thm)], [f4, f3])).
fof(s1, plain, p(a), inference(mp, [status(thm)], [f2, f1])).
fof(f6, theorem, r(a, b), inference(mp, [status(thm)], [f5, s1, lemma_6])).
% SZS output end Proof
