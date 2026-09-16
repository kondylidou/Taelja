% SZS output start Proof
fof(ax4, axiom, ! [X1]: f(X1) = g(X1), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p', ax4)).
fof(ax1, axiom, ! [X1]: ((p(X1) & q(X1)) => X1 = zero), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p', ax1)).
fof(ax2, axiom, ! [X1]: p(f(X1)), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p', ax2)).
fof(ax3, axiom, ! [X1]: q(f(X1)), file('/home/user/Developer/Taelja/test/input/horn_example_eq_head_inlined.p', ax3)).
fof(s1, plain, p(f(a)), inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, q(f(a)), inference(instantiate, [status(thm)], [ax3])).
fof(s3, plain, f(a) = zero, inference(mp, [status(thm)], [ax1, s1, s2])).
fof(goal, theorem, g(a) = zero, inference(rewrite, [status(thm)], [ax4, s3])).
% SZS output end Proof
