% SZS output start Proof
fof(ax1, axiom, f(a) = b, file('/Users/kondylidou/Developer/Taelja/test/input/horn_rel_two_step_chain.p', ax1)).
fof(ax2, axiom, g(b) = c, file('/Users/kondylidou/Developer/Taelja/test/input/horn_rel_two_step_chain.p', ax2)).
fof(ax3, axiom, p(c), file('/Users/kondylidou/Developer/Taelja/test/input/horn_rel_two_step_chain.p', ax3)).
fof(s1, plain, p(g(b)), inference(rewrite, [status(thm)], [ax2, ax3])).
fof(goal, theorem, p(g(f(a))), inference(rewrite, [status(thm)], [ax1, s1])).
% SZS output end Proof
