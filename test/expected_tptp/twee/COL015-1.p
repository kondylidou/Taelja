% SZS output start Proof
cnf(c2, axiom, apply(m, X) = apply(X, X), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL015-1.p', m_definition)).
cnf(c3, axiom, apply(apply(apply(q, X2), Y2), Z) = apply(Y2, apply(X2, Z)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL015-1.p', q_definition)).
fof(s1, plain, apply(m,apply(apply(q,m),combinator)) = apply(apply(apply(q,m),combinator),apply(apply(q,m),combinator)), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, apply(m,apply(apply(q,m),combinator)) = apply(combinator,apply(m,apply(apply(q,m),combinator))), inference(rewrite, [status(thm)], [c3, s1])).
% SZS output end Proof
