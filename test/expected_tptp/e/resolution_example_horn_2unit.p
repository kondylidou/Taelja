% SZS output start Proof
fof(ax3, axiom, ! [X1, X2]: ((p(X1) & q(X2)) => r(X1, X2)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p', ax3)).
fof(ax2, axiom, q(b), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p', ax2)).
fof(ax1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p', ax1)).
fof(goal, theorem, r(a, b), inference(mp, [status(thm)], [ax3, ax1, ax2])).
% SZS output end Proof
