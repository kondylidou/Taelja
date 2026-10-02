% SZS output start Proof
cnf(ax1, axiom, less_equal(X, top), file('test.p', ax1)).
cnf(ax2, axiom, member(X, Y) | ~ less_equal(X, Y), file('test.p', ax2)).
fof(s1, plain, less_equal(a,top), inference(instantiate, [status(thm)], [ax1])).
fof(goal_1, theorem, member(a,top), inference(mp, [status(thm)], [ax2, s1])).
% SZS output end Proof
