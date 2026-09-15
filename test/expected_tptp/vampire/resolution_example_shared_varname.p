% SZS output start Proof
fof(f24, axiom, l0(c), file('Problems/SYN/SYN189-1.p')).
fof(f17, axiom, ! [X0]: q0(X0, d), file('Problems/SYN/SYN189-1.p')).
fof(f1, axiom, s0(d), file('Problems/SYN/SYN189-1.p')).
fof(f144, axiom, ! [X0]: (q1(X0, X0, X0) | ~ s0(X0)), file('Problems/SYN/SYN189-1.p')).
fof(f162, axiom, ! [X0, X1]: (~ q1(d, X1, d) | ~ q0(X0, X1) | ~ s0(d) | r1(X0)), file('Problems/SYN/SYN189-1.p')).
fof(f226, axiom, ! [X0]: (~ r1(X0) | r2(X0) | ~ l0(X0)), file('Problems/SYN/SYN189-1.p')).
fof(s1, plain, q1(d,d,d), inference(mp, [status(thm)], [f144, f1])).
fof(s2, plain, q0(c,d), inference(instantiate, [status(thm)], [f17])).
fof(s3, plain, r1(c), inference(mp, [status(thm)], [f162, s1, s2, f1])).
fof(goal_1, theorem, r2(c), inference(mp, [status(thm)], [f226, s3, f24])).
% SZS output end Proof
