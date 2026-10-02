% SZS output start Proof
fof(f1, axiom, ! [X0]: product(identity, X0, X0), file('Problems/GRP/GRP041-2.p')).
fof(f4, axiom, ! [X2, X3, X0, X1]: (~ product(X0, X1, X3) | ~ product(X0, X1, X2) | equalish(X2, X3)), file('Problems/GRP/GRP041-2.p')).
fof(s1, plain, product(identity,a,a), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, product(identity,a,a), inference(instantiate, [status(thm)], [f1])).
fof(goal_1, theorem, equalish(a,a), inference(mp, [status(thm)], [f4, s1, s2])).
% SZS output end Proof
