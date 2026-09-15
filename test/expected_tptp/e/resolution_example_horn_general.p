% SZS output start Proof
fof(ax1, axiom, s(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p', ax1)).
fof(ax2, axiom, ! [X1]: (s(X1) => p(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p', ax2)).
fof(ax3, axiom, t(b), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p', ax3)).
fof(ax4, axiom, ! [X2]: (t(X2) => q(X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p', ax4)).
fof(ax5, axiom, ! [X1, X2]: ((p(X1) & q(X2)) => r(X1, X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_general.p', ax5)).
fof(lemma_6, lemma, q(b), inference(mp, [status(thm)], [ax4, ax3])).
fof(s1, plain, p(a), inference(mp, [status(thm)], [ax2, ax1])).
fof(goal, theorem, r(a, b), inference(mp, [status(thm)], [ax5, s1, lemma_6])).
% SZS output end Proof
