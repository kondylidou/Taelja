% SZS output start Proof
fof(ax2, axiom, f(b) = c, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', ax2)).
fof(ax1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', ax1)).
fof(ax3, axiom, ! [X1]: (f(X1) = c => g(X1) = c), file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', ax3)).
fof(ax4, axiom, g(a) = c => h(a) = c, file('/home/user/Developer/Taelja/test/input/horn_example_eq_rw_chain.p', ax4)).
fof(s1, plain, f(a) = f(b), inference(instantiate, [status(thm)], [ax1])).
fof(lemma_5, lemma, f(a) = c, inference(rewrite, [status(thm)], [ax2, s1])).
fof(s2, plain, g(a) = c, inference(mp, [status(thm)], [ax3, lemma_5])).
fof(goal, theorem, h(a) = c, inference(mp, [status(thm)], [ax4, s2])).
% SZS output end Proof
