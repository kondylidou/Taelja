% SZS output start Proof
cnf(c2, axiom, product(identity, X, X), file('/home/user/Desktop/TPTP-v9.2.1/Problems/GRP/GRP007-1.p', left_identity)).
cnf(c3, hypothesis, product(A, c, A), file('/home/user/Desktop/TPTP-v9.2.1/Problems/GRP/GRP007-1.p', another_right_identity)).
cnf(c4, axiom, ~ product(X2, Y, Z) | ~ product(X2, Y, W) | Z = W, file('/home/user/Desktop/TPTP-v9.2.1/Problems/GRP/GRP007-1.p', total_function2)).
fof(s1, plain, product(identity,c,identity), inference(instantiate, [status(thm)], [c3])).
fof(s2, plain, product(identity,c,c), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, identity = c, inference(mp, [status(thm)], [c4, s1, s2])).
% SZS output end Proof
