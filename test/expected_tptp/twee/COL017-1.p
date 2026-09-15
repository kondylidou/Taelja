% SZS output start Proof
cnf(c2, axiom, apply(m, X) = apply(X, X), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL017-1.p', m_definition)).
cnf(c3, axiom, apply(apply(apply(b, X2), Y2), Z) = apply(X2, apply(Y2, Z)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL017-1.p', b_definition)).
fof(s1, plain, apply(m,apply(apply(b,combinator),m)) = apply(apply(apply(b,combinator),m),apply(apply(b,combinator),m)), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, apply(m,apply(apply(b,combinator),m)) = apply(combinator,apply(m,apply(apply(b,combinator),m))), inference(rewrite, [status(thm)], [c3, s1])).
% SZS output end Proof
