% SZS output start Proof
fof(ax3, axiom, ! [X2, X3]: ((q(X2, X3) & p(X3)) => q(f(X2), X3)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax3)).
fof(ax1, axiom, ! [X1]: p(X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax1)).
fof(ax2, axiom, ! [X1]: q(b, X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax2)).
fof(s1, plain, q(b,a), inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, p(a), inference(instantiate, [status(thm)], [ax1])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [ax3, s1, s2])).
fof(s4, plain, p(a), inference(instantiate, [status(thm)], [ax1])).
fof(goal, theorem, q(f(f(b)), a), inference(mp, [status(thm)], [ax3, s3, s4])).
% SZS output end Proof
