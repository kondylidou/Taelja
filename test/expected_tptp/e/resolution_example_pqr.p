% SZS output start Proof
fof(ax3, axiom, ! [X1]: (q(X1) => r(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', ax3)).
fof(ax2, axiom, ! [X1]: (p(X1) => q(X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', ax2)).
fof(ax1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_pqr.p', ax1)).
fof(s1, plain, q(a), inference(mp, [status(thm)], [ax2, ax1])).
fof(goal, theorem, r(a), inference(mp, [status(thm)], [ax3, s1])).
% SZS output end Proof
