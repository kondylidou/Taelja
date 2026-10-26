% SZS output start Proof
fof(c_54, plain, less(a, b), file('Problems/NUM/NUM025-1.p', a_less_than_b)).
fof(c_55, plain, less(b, a), file('Problems/NUM/NUM025-1.p', prove_b_not_less_than_a)).
fof(c_56, plain, ! [X0, X1, X2]: (~ less(X0, X1) | ~ less(X2, X0) | less(X2, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/NUM001-1.ax', transitivity_of_less)).
fof(goal_1, theorem, less(a,a), inference(mp, [status(thm)], [c_56, c_55, c_54])).
% SZS output end Proof
