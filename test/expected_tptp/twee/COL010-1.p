% SZS output start Proof
cnf(c2, axiom, apply(apply(apply(s2, X), Y2), Z) = apply(apply(X, Z), apply(Y2, Y2)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL010-1.p', s2_definition)).
cnf(c3, axiom, apply(apply(apply(b, X2), Y2), Z2) = apply(X2, apply(Y2, Z2)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL010-1.p', b_definition)).
fof(s1, plain, apply(apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator))),apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator)))) = apply(apply(apply(b,combinator),apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator)))),apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator)))), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, apply(apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator))),apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator)))) = apply(combinator,apply(apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator))),apply(apply(s2,apply(b,combinator)),apply(s2,apply(b,combinator))))), inference(rewrite, [status(thm)], [c3, s1])).
% SZS output end Proof
