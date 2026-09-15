% SZS output start Proof
fof(f1, axiom, ! [X0]: s(X0), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p')).
fof(f3, axiom, ! [X0]: (s(X0) => p(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p')).
fof(f2, axiom, ! [X0]: (s(X0) => q(b, X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p')).
fof(f4, axiom, ! [X0, X1]: ((q(X0, X1) & p(X1)) => r(X0, X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p')).
fof(s1, plain, s(a), inference(instantiate, [status(thm)], [f1])).
fof(lemma_5, lemma, p(a), inference(mp, [status(thm)], [f3, s1])).
fof(s2, plain, s(a), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, q(b,a), inference(mp, [status(thm)], [f2, s2])).
fof(f5, theorem, r(b, a), inference(mp, [status(thm)], [f4, s3, lemma_5])).
% SZS output end Proof
