% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(right_inverse, axiom, product(X1, inverse(X1), identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(inverse_b_multiply_inverse_a_is_d, hypothesis, product(inverse(b), inverse(a), d), file('Problems/GRP/GRP012-2.p', inverse_b_multiply_inverse_a_is_d)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(a_multiply_b_is_c, hypothesis, product(a, b, c), file('Problems/GRP/GRP012-2.p', a_multiply_b_is_c)).
cnf(left_inverse, axiom, product(inverse(X1), X1, identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(s1, plain, ! [X] : product(identity,X,multiply(identity,X)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_10, lemma, ! [X] : multiply(identity,X) = X, inference(mp, [status(thm)], [total_function2, left_identity, s1])).
fof(s2, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s3, plain, product(b,d,multiply(b,d)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_11, lemma, product(identity,inverse(a),multiply(b,d)), inference(mp, [status(thm)], [associativity2, s2, inverse_b_multiply_inverse_a_is_d, s3])).
fof(s4, plain, product(identity,inverse(a),multiply(identity,inverse(a))), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_12, lemma, multiply(identity,inverse(a)) = multiply(b,d), inference(mp, [status(thm)], [total_function2, s4, lemma_11])).
fof(s5, plain, product(b,d,multiply(b,d)), inference(instantiate, [status(thm)], [total_function1])).
fof(s6, plain, product(b,d,multiply(identity,inverse(a))), inference(rewrite, [status(thm)], [lemma_12, s5])).
fof(lemma_13, lemma, product(b,d,inverse(a)), inference(rewrite, [status(thm)], [lemma_10, s6])).
fof(s7, plain, product(a,b,multiply(a,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_14, lemma, c = multiply(a,b), inference(mp, [status(thm)], [total_function2, a_multiply_b_is_c, s7])).
fof(s8, plain, product(a,b,multiply(a,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(s9, plain, product(a,inverse(a),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s10, plain, product(multiply(a,b),d,identity), inference(mp, [status(thm)], [associativity2, s8, lemma_13, s9])).
fof(lemma_15, lemma, product(c,d,identity), inference(rewrite, [status(thm)], [lemma_14, s10])).
fof(s11, plain, product(inverse(c),c,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s12, plain, product(inverse(c),identity,inverse(c)), inference(instantiate, [status(thm)], [right_identity])).
fof(lemma_16, lemma, product(identity,d,inverse(c)), inference(mp, [status(thm)], [associativity2, s11, lemma_15, s12])).
fof(s13, plain, product(identity,d,multiply(identity,d)), inference(instantiate, [status(thm)], [total_function1])).
fof(s14, plain, multiply(identity,d) = inverse(c), inference(mp, [status(thm)], [total_function2, s13, lemma_16])).
fof(goal_1, theorem, inverse(c) = d, inference(rewrite, [status(thm)], [lemma_10, s14])).
% SZS output end Proof
