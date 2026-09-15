% SZS output start Proof
fof(ax1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', ax1)).
fof(ax2, axiom, ! [X1, X2]: (p(X1) => q(X1, X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', ax2)).
fof(ax3, axiom, ! [X1]: (q(X1, b) => r1(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', ax3)).
fof(ax4, axiom, ! [X1]: (q(X1, c) => r2(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', ax4)).
fof(ax5, axiom, ! [X1]: ((r1(X1) & r2(X1)) => r0(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_dag.p', ax5)).
fof(lemma_6, lemma, ! [X] : q(a,X), inference(mp, [status(thm)], [ax2, ax1])).
fof(s1, plain, q(a,c), inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, r2(a), inference(mp, [status(thm)], [ax4, s1])).
fof(s2, plain, q(a,b), inference(instantiate, [status(thm)], [lemma_6])).
fof(s3, plain, r1(a), inference(mp, [status(thm)], [ax3, s2])).
fof(goal, theorem, r0(a), inference(mp, [status(thm)], [ax5, s3, lemma_7])).
% SZS output end Proof
