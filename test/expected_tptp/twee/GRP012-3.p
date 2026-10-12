% SZS output start Proof
cnf(c3, axiom, product(X, Y, multiply(X, Y)), file('TPTP/Problems/GRP/GRP012-3.p', total_function1)).
cnf(c4, axiom, product(X2, inverse(X2), identity), file('TPTP/Problems/GRP/GRP012-3.p', right_inverse)).
cnf(c5, axiom, product(X2, identity, X2), file('TPTP/Problems/GRP/GRP012-3.p', right_identity)).
cnf(c6, axiom, ~ product(X2, Y2, U) | ~ product(Y2, Z, V) | ~ product(X2, V, W) | product(U, Z, W), file('TPTP/Problems/GRP/GRP012-3.p', associativity2)).
cnf(c10, axiom, ~ product(X2, Y2, Z2) | ~ product(X2, Y2, W2) | Z2 = W2, file('TPTP/Problems/GRP/GRP012-3.p', total_function2)).
cnf(c14, axiom, product(identity, X2, X2), file('TPTP/Problems/GRP/GRP012-3.p', left_identity)).
cnf(c15, axiom, ~ product(X2, Y2, U2) | ~ product(Y2, Z2, V2) | ~ product(U2, Z2, W2) | product(X2, V2, W2), file('TPTP/Problems/GRP/GRP012-3.p', associativity1)).
fof(s1, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_8, lemma, ! [X,Y,Z] : (product(X,Y,Z) => multiply(X,Y) = Z), inference(mp, [status(thm)], [c10, c3, s1])).
fof(s2, plain, ! [X,Y] : product(inverse(X),Y,multiply(inverse(X),Y)), inference(instantiate, [status(thm)], [c3])).
fof(s3, plain, ! [X,Y] : product(X,multiply(inverse(X),Y),Y), inference(mp, [status(thm)], [c15, c4, s2, c14])).
fof(lemma_9, lemma, ! [X,Y] : multiply(X,multiply(inverse(X),Y)) = Y, inference(mp, [status(thm)], [lemma_8, s3])).
fof(s4, plain, product(b,multiply(inverse(b),inverse(a)),multiply(b,multiply(inverse(b),inverse(a)))), inference(instantiate, [status(thm)], [c3])).
fof(s5, plain, product(multiply(inverse(b),inverse(a)),inverse(multiply(inverse(b),inverse(a))),identity), inference(instantiate, [status(thm)], [c4])).
fof(s6, plain, product(b,identity,b), inference(instantiate, [status(thm)], [c5])).
fof(s7, plain, product(multiply(b,multiply(inverse(b),inverse(a))),inverse(multiply(inverse(b),inverse(a))),b), inference(mp, [status(thm)], [c6, s4, s5, s6])).
fof(lemma_10, lemma, multiply(multiply(b,multiply(inverse(b),inverse(a))),inverse(multiply(inverse(b),inverse(a)))) = b, inference(mp, [status(thm)], [lemma_8, s7])).
fof(s8, plain, product(multiply(inverse(b),inverse(a)),inverse(multiply(inverse(b),inverse(a))),identity), inference(instantiate, [status(thm)], [c4])).
fof(s9, plain, product(inverse(multiply(inverse(b),inverse(a))),inverse(inverse(multiply(inverse(b),inverse(a)))),identity), inference(instantiate, [status(thm)], [c4])).
fof(s10, plain, product(multiply(inverse(b),inverse(a)),identity,multiply(inverse(b),inverse(a))), inference(instantiate, [status(thm)], [c5])).
fof(s11, plain, product(identity,inverse(inverse(multiply(inverse(b),inverse(a)))),multiply(inverse(b),inverse(a))), inference(mp, [status(thm)], [c6, s8, s9, s10])).
fof(s12, plain, product(identity,inverse(inverse(multiply(inverse(b),inverse(a)))),inverse(inverse(multiply(inverse(b),inverse(a))))), inference(instantiate, [status(thm)], [c14])).
fof(s13, plain, multiply(inverse(b),inverse(a)) = inverse(inverse(multiply(inverse(b),inverse(a)))), inference(mp, [status(thm)], [c10, s11, s12])).
fof(s14, plain, multiply(inverse(b),inverse(a)) = inverse(multiply(a,multiply(inverse(a),inverse(multiply(inverse(b),inverse(a)))))), inference(rewrite, [status(thm)], [lemma_9, s13])).
fof(s15, plain, multiply(inverse(b),inverse(a)) = inverse(multiply(a,multiply(multiply(b,multiply(inverse(b),inverse(a))),inverse(multiply(inverse(b),inverse(a)))))), inference(rewrite, [status(thm)], [lemma_9, s14])).
fof(goal_1, theorem, inverse(multiply(a,b)) = multiply(inverse(b),inverse(a)), inference(rewrite, [status(thm)], [lemma_10, s15])).
% SZS output end Proof
