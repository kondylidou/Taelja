% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', unknown)).
fof(f2, axiom, ! [X0, X1]: (p(X0) => q(X0, X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', unknown)).
fof(f3, axiom, ! [X0]: (q(X0, b) => r1(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', unknown)).
fof(f4, axiom, ! [X0]: (q(X0, c) => r2(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', unknown)).
fof(f5, axiom, ! [X0]: ((r1(X0) & r2(X0)) => r0(X0)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', unknown)).
fof(s1, plain, q(a,c), inference(mp, [status(thm)], [f2, f1])).
fof(lemma_6, lemma, r2(a), inference(mp, [status(thm)], [f4, s1])).
fof(s2, plain, q(a,b), inference(mp, [status(thm)], [f2, f1])).
fof(s3, plain, r1(a), inference(mp, [status(thm)], [f3, s2])).
fof(f6, theorem, r0(a), inference(mp, [status(thm)], [f5, s3, lemma_6])).
% SZS output end Proof
