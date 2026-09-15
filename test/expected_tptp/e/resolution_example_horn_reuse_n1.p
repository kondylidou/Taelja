% SZS output start Proof
fof(ax2, axiom, ! [X1]: q(b, X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p', ax2)).
fof(ax1, axiom, ! [X1]: p(X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p', ax1)).
fof(ax3, axiom, ! [X2, X3]: ((q(X2, X3) & p(X3)) => q(f(X2), X3)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p', ax3)).
fof(ax4, axiom, ! [X3]: (q(f(b), X3) => r(X3)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_n1.p', ax4)).
fof(s1, plain, q(b,a), inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, p(a), inference(instantiate, [status(thm)], [ax1])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [ax3, s1, s2])).
fof(goal, theorem, r(a), inference(mp, [status(thm)], [ax4, s3])).
% SZS output end Proof
