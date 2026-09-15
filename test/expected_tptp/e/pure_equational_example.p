% SZS output start Proof
fof(ax2, axiom, b = c, file('/home/user/Developer/Taelja/test/input/pure_equational_example.p', ax2)).
fof(ax1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/pure_equational_example.p', ax1)).
fof(goal, theorem, a = c, inference(rewrite, [status(thm)], [ax2, ax1])).
% SZS output end Proof
