% SZS output start Proof
fof(ax3, axiom, ! [X2]: (s(X2) => p(X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p', ax3)).
fof(ax1, axiom, ! [X1]: s(X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p', ax1)).
fof(ax4, axiom, ! [X2, X3]: ((q(X2, X3) & p(X3)) => r(X2, X3)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p', ax4)).
fof(ax2, axiom, ! [X2]: (s(X2) => q(b, X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_forced.p', ax2)).
fof(s1, plain, s(a), inference(instantiate, [status(thm)], [ax1])).
fof(lemma_5, lemma, p(a), inference(mp, [status(thm)], [ax3, s1])).
fof(s2, plain, s(a), inference(instantiate, [status(thm)], [ax1])).
fof(s3, plain, q(b,a), inference(mp, [status(thm)], [ax2, s2])).
fof(goal, theorem, r(b, a), inference(mp, [status(thm)], [ax4, s3, lemma_5])).
% SZS output end Proof
