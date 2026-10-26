% SZS output start Proof
fof(c_49, plain, ! [X0]: less_equal(X0, top), file('e_unit_source_axiom.p', ax1)).
fof(c_50, plain, ! [X0, X1]: (~ less_equal(X0, X1) | member(X0, X1)), file('e_unit_source_axiom.p', ax2)).
fof(s1, plain, less_equal(a,top), inference(instantiate, [status(thm)], [c_49])).
fof(goal_1, theorem, member(a,top), inference(mp, [status(thm)], [c_50, s1])).
% SZS output end Proof
