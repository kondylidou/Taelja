% SZS output start Proof
fof(c_49, plain, product(a, b, c), file('Problems/GRP/GRP012-2.p', a_multiply_b_is_c)).
fof(c_50, plain, product(inverse(b), inverse(a), d), file('Problems/GRP/GRP012-2.p', inverse_b_multiply_inverse_a_is_d)).
fof(c_52, plain, ! [X0]: product(identity, X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
fof(c_53, plain, ! [X0]: product(X0, identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(c_54, plain, ! [X0]: product(inverse(X0), X0, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
fof(c_55, plain, ! [X0]: product(X0, inverse(X0), identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
fof(c_56, plain, ! [X0, X1]: product(X0, X1, multiply(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
fof(c_57, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
fof(c_58, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X1, X3, X4) | ~ product(X2, X3, X5) | product(X0, X4, X5)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity1)).
fof(s1, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_10, lemma, ! [X,Y,Z] : (product(X,Y,Z) => multiply(X,Y) = Z), inference(mp, [status(thm)], [c_57, c_56, s1])).
fof(s2, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [c_55])).
fof(s3, plain, product(identity,inverse(a),inverse(a)), inference(instantiate, [status(thm)], [c_52])).
fof(s4, plain, product(b,d,inverse(a)), inference(mp, [status(thm)], [c_58, s2, c_50, s3])).
fof(lemma_11, lemma, multiply(b,d) = inverse(a), inference(mp, [status(thm)], [lemma_10, s4])).
fof(s5, plain, product(b,d,multiply(b,d)), inference(instantiate, [status(thm)], [c_56])).
fof(s6, plain, product(c,d,multiply(c,d)), inference(instantiate, [status(thm)], [c_56])).
fof(s7, plain, product(a,multiply(b,d),multiply(c,d)), inference(mp, [status(thm)], [c_58, c_49, s5, s6])).
fof(lemma_12, lemma, multiply(a,multiply(b,d)) = multiply(c,d), inference(mp, [status(thm)], [lemma_10, s7])).
fof(s8, plain, product(a,multiply(b,d),multiply(a,multiply(b,d))), inference(instantiate, [status(thm)], [c_56])).
fof(s9, plain, product(a,multiply(b,d),multiply(c,d)), inference(rewrite, [status(thm)], [lemma_12, s8])).
fof(lemma_13, lemma, product(a,inverse(a),multiply(c,d)), inference(rewrite, [status(thm)], [lemma_11, s9])).
fof(s10, plain, product(a,inverse(a),identity), inference(instantiate, [status(thm)], [c_55])).
fof(lemma_14, lemma, identity = multiply(c,d), inference(mp, [status(thm)], [c_57, s10, lemma_13])).
fof(s11, plain, product(c,d,multiply(c,d)), inference(instantiate, [status(thm)], [c_56])).
fof(lemma_15, lemma, product(c,d,identity), inference(rewrite, [status(thm)], [lemma_14, s11])).
fof(s12, plain, product(inverse(c),c,identity), inference(instantiate, [status(thm)], [c_54])).
fof(s13, plain, product(identity,d,d), inference(instantiate, [status(thm)], [c_52])).
fof(lemma_16, lemma, product(inverse(c),identity,d), inference(mp, [status(thm)], [c_58, s12, lemma_15, s13])).
fof(s14, plain, product(inverse(c),identity,inverse(c)), inference(instantiate, [status(thm)], [c_53])).
fof(goal_1, theorem, inverse(c) = d, inference(mp, [status(thm)], [c_57, s14, lemma_16])).
% SZS output end Proof
