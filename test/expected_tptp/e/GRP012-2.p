% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(right_inverse, axiom, product(X1, inverse(X1), identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(a_multiply_b_is_c, hypothesis, product(a, b, c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP012-2.p', a_multiply_b_is_c)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(left_inverse, axiom, product(inverse(X1), X1, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
cnf(inverse_b_multiply_inverse_a_is_d, hypothesis, product(inverse(b), inverse(a), d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP012-2.p', inverse_b_multiply_inverse_a_is_d)).
fof(s1, plain, ! [X] : product(X,identity,multiply(X,identity)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_10, lemma, ! [X] : X = multiply(X,identity), inference(mp, [status(thm)], [total_function2, right_identity, s1])).
fof(s2, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s3, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,identity,multiply(X,identity))), inference(instantiate, [status(thm)], [total_function1])).
fof(s4, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(Z,inverse(Y),multiply(X,identity))), inference(mp, [status(thm)], [associativity2, s2, right_inverse, s3])).
fof(lemma_11, lemma, ! [X,Y,Z] : (product(X,Y,Z) => product(Z,inverse(Y),X)), inference(rewrite, [status(thm)], [lemma_10, s4])).
fof(s5, plain, product(inverse(c),a,multiply(inverse(c),a)), inference(instantiate, [status(thm)], [total_function1])).
fof(s6, plain, product(inverse(c),c,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s7, plain, product(multiply(inverse(c),a),b,identity), inference(mp, [status(thm)], [associativity2, s5, a_multiply_b_is_c, s6])).
fof(lemma_12, lemma, product(identity,inverse(b),multiply(inverse(c),a)), inference(mp, [status(thm)], [lemma_11, s7])).
fof(s8, plain, product(identity,inverse(b),inverse(b)), inference(instantiate, [status(thm)], [left_identity])).
fof(lemma_13, lemma, inverse(b) = multiply(inverse(c),a), inference(mp, [status(thm)], [total_function2, s8, lemma_12])).
fof(s9, plain, product(inverse(c),a,multiply(inverse(c),a)), inference(instantiate, [status(thm)], [total_function1])).
fof(s10, plain, product(inverse(c),a,inverse(b)), inference(rewrite, [status(thm)], [lemma_13, s9])).
fof(lemma_14, lemma, product(inverse(b),inverse(a),inverse(c)), inference(mp, [status(thm)], [lemma_11, s10])).
fof(goal_1, theorem, inverse(c) = d, inference(mp, [status(thm)], [total_function2, inverse_b_multiply_inverse_a_is_d, lemma_14])).
% SZS output end Proof
