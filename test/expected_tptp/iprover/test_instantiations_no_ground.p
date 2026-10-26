% SZS output start Proof
fof(f1, axiom, top, file('test_instantiations_no_ground.p', f1)).
fof(f2, axiom, ! [X0, X1]: (top => q(X0, X1)), file('test_instantiations_no_ground.p', f2)).
fof(f3, axiom, ! [X0]: (q(X0, b) => r1(X0)), file('test_instantiations_no_ground.p', f3)).
fof(f4, axiom, ! [X0]: (q(X0, X0) => r2(X0)), file('test_instantiations_no_ground.p', f4)).
fof(f5, axiom, ! [X0]: ((r2(X0) & r1(X0)) => s(X0)), file('test_instantiations_no_ground.p', f5)).
fof(s1, plain, q(a,b), inference(mp, [status(thm)], [f2, f1])).
fof(lemma_6, lemma, r1(a), inference(mp, [status(thm)], [f3, s1])).
fof(s2, plain, q(a,a), inference(mp, [status(thm)], [f2, f1])).
fof(s3, plain, r2(a), inference(mp, [status(thm)], [f4, s2])).
fof(f6, theorem, s(a), inference(mp, [status(thm)], [f5, s3, lemma_6])).
% SZS output end Proof
