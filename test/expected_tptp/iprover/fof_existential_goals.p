% SZS output start Proof
fof(f1, axiom, q(c, d) & q(a, b) & p(a), file('fof_existential_goals.p', a1)).
fof(axiom_1, plain, p(a), inference(clausify, [status(thm)], [f1])).
fof(axiom_2, plain, q(a,b), inference(clausify, [status(thm)], [f1])).
fof(s1, plain, q(a,b), inference(instantiate, [status(thm)], [axiom_2])).
fof(s2, plain, p(a), inference(instantiate, [status(thm)], [axiom_1])).
fof(f2, theorem, ? [X0, X1, X2, X3]: (q(X2, X3) & q(X0, X1) & p(X0)), inference(conclude, [status(thm)], [s1, s2])).
% SZS output end Proof
