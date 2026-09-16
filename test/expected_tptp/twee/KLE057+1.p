% SZS output start Proof
cnf(c9, axiom, domain(zero) = zero, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/KLE/KLE057+1.p', domain4)).
fof(c8, assumption, x0 = zero, introduced(assumption, [], [])).
fof(s1, plain, domain(x0) = domain(zero), inference(instantiate, [status(thm), assumptions([c8])], [c8])).
fof(s2, plain, domain(x0) = zero, inference(rewrite, [status(thm), assumptions([c8])], [c9, s1])).
fof(discharged, plain, (x0 = zero => domain(x0) = zero), inference(implies, [status(thm), discharge(implies, [c8])], [s2, c8])).
fof(c1, theorem, ! [X0]: (domain(X0) = zero <= X0 = zero), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
