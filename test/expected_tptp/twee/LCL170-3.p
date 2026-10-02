% SZS output start Proof
cnf(c2, axiom, axiom(implies(A, or(B, A))), file('TPTP/Problems/LCL/LCL170-3.p', axiom_1_3)).
cnf(c3, axiom, implies(X, Y) = or(not(X), Y), file('TPTP/Problems/LCL/LCL170-3.p', implies_definition)).
cnf(c5, axiom, theorem(X2) | ~ axiom(X2), file('TPTP/Problems/LCL/LCL170-3.p', rule_1)).
fof(s1, plain, axiom(implies(q,or(not(p),q))), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, axiom(implies(q,implies(p,q))), inference(rewrite, [status(thm)], [c3, s1])).
fof(goal_1, theorem, theorem(implies(q,implies(p,q))), inference(mp, [status(thm)], [c5, s2])).
% SZS output end Proof
