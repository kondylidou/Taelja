% SZS output start Proof
fof(f2, axiom, ! [X0]: product(X0, identity, X0), file('Problems/GRP/GRP007-1.p')).
fof(f9, axiom, ! [X0]: product(c, X0, X0), file('Problems/GRP/GRP007-1.p')).
fof(f6, axiom, ! [X2, X3, X0, X1]: (~ product(X0, X1, X3) | ~ product(X0, X1, X2) | X2 = X3), file('Problems/GRP/GRP007-1.p')).
fof(s1, plain, product(c,identity,identity), inference(instantiate, [status(thm)], [f9])).
fof(s2, plain, product(c,identity,c), inference(instantiate, [status(thm)], [f2])).
fof(goal_1, theorem, identity = c, inference(mp, [status(thm)], [f6, s1, s2])).
% SZS output end Proof
