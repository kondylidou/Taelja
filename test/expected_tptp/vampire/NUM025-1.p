% SZS output start Proof
fof(f7, axiom, ! [X2, X0, X1]: (~ less(X2, X0) | ~ less(X0, X1) | less(X2, X1)), file('Problems/NUM/NUM025-1.p')).
fof(f15, axiom, less(a, b), file('Problems/NUM/NUM025-1.p')).
fof(f16, negated_conjecture, less(b, a), file('Problems/NUM/NUM025-1.p')).
fof(goal_1, theorem, less(b,b), inference(mp, [status(thm)], [f7, f16, f15])).
% SZS output end Proof
