% SZS output start Proof
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(another_left_identity, hypothesis, product(c, X1, X1), file('Problems/GRP/GRP007-1.p', another_left_identity)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(s1, plain, product(c,identity,identity), inference(instantiate, [status(thm)], [another_left_identity])).
fof(s2, plain, product(c,identity,c), inference(instantiate, [status(thm)], [right_identity])).
fof(goal_1, theorem, identity = c, inference(mp, [status(thm)], [total_function2, s1, s2])).
% SZS output end Proof
