% SZS output start Proof
fof(a1, axiom, p(a) & q(a, b) & q(c, d), file('t.p', a1)).
fof(axiom_1, plain, p(a), inference(clausify, [status(thm)], [a1])).
fof(axiom_2, plain, q(a,b), inference(clausify, [status(thm)], [a1])).
fof(axiom_3, plain, q(c,d), inference(clausify, [status(thm)], [a1])).
fof(s1, plain, p(a), inference(instantiate, [status(thm)], [axiom_1])).
fof(s2, plain, q(a,b), inference(instantiate, [status(thm)], [axiom_2])).
fof(s3, plain, q(c,d), inference(instantiate, [status(thm)], [axiom_3])).
fof(c, theorem, ? [X, Y, Z, W]: (p(X) & q(X, Y) & q(Z, W)), inference(conclude, [status(thm)], [s1, s2, s3])).
% SZS output end Proof
