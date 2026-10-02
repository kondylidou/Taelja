% SZS output start Proof
fof(ax2, axiom, ! [X1, X2]: (g(X1) = g(X2) => X1 = X2), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p', ax2)).
fof(ax3, axiom, g(f(a)) = g(f(b)), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p', ax3)).
fof(ax1, axiom, ! [X1, X2]: (f(X1) = f(X2) => X1 = X2), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p', ax1)).
fof(s1, plain, f(a) = f(b), inference(mp, [status(thm)], [ax2, ax3])).
fof(goal, theorem, a = b, inference(mp, [status(thm)], [ax1, s1])).
% SZS output end Proof
