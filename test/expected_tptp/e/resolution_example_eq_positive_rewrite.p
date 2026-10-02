% SZS output start Proof
fof(ax3, axiom, p(b) => q(b), file('/home/user/Developer/Taelja/test/input/resolution_example_eq_positive_rewrite.p', ax3)).
fof(ax1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_eq_positive_rewrite.p', ax1)).
fof(ax2, axiom, a = b, file('/home/user/Developer/Taelja/test/input/resolution_example_eq_positive_rewrite.p', ax2)).
fof(s1, plain, p(b), inference(rewrite, [status(thm)], [ax2, ax1])).
fof(goal, theorem, q(b), inference(mp, [status(thm)], [ax3, s1])).
% SZS output end Proof
