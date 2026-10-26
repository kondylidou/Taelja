% SZS output start Proof
fof(c_49, plain, ! [X0]: product(c, X0, X0), file('Problems/GRP/GRP007-1.p', another_left_identity)).
fof(c_53, plain, ! [X0]: product(X0, identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(c_57, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
fof(s1, plain, product(c,identity,identity), inference(instantiate, [status(thm)], [c_49])).
fof(s2, plain, product(c,identity,c), inference(instantiate, [status(thm)], [c_53])).
fof(goal_1, theorem, c = identity, inference(mp, [status(thm)], [c_57, s1, s2])).
% SZS output end Proof
