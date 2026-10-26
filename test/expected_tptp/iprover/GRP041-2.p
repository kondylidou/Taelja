% SZS output start Proof
fof(c_50, plain, ! [X0]: product(identity, X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP005-0.ax', left_identity)).
fof(c_53, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | equalish(X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP005-0.ax', total_function2)).
fof(s1, plain, product(identity,a,a), inference(instantiate, [status(thm)], [c_50])).
fof(s2, plain, product(identity,a,a), inference(instantiate, [status(thm)], [c_50])).
fof(goal_1, theorem, equalish(a,a), inference(mp, [status(thm)], [c_53, s1, s2])).
% SZS output end Proof
