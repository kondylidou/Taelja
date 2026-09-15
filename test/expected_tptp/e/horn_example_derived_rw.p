% SZS output start Proof
fof(ax2, axiom, q(b), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p', ax2)).
fof(ax4, axiom, ! [X2]: (q(X2) => a = X2), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p', ax4)).
fof(ax1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p', ax1)).
fof(ax3, axiom, ! [X1]: (p(X1) => f(X1) = c), file('/home/user/Developer/Taelja/test/input/horn_example_derived_rw.p', ax3)).
fof(lemma_5, lemma, a = b, inference(mp, [status(thm)], [ax4, ax2])).
fof(s1, plain, p(b), inference(rewrite, [status(thm)], [lemma_5, ax1])).
fof(goal, theorem, f(b) = c, inference(mp, [status(thm)], [ax3, s1])).
% SZS output end Proof
