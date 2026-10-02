% SZS output start Proof
fof(ax3, axiom, ! [X1]: f(X1) = X1, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', ax3)).
fof(ax2, axiom, b = c, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', ax2)).
fof(ax1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', ax1)).
fof(s1, plain, c = b, inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, c = a, inference(rewrite, [status(thm)], [ax1, s1])).
fof(s3, plain, f(d) = d, inference(instantiate, [status(thm)], [ax3])).
fof(goal, theorem, c = a & f(d) = d, inference(conclude, [status(thm)], [s2, s3])).
% SZS output end Proof
