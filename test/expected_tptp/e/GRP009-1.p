% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(a_is_an_inverse_of_b, hypothesis, product(a, b, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP009-1.p', a_is_an_inverse_of_b)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(associativity1, axiom, product(X1, X5, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X3, X4, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity1)).
cnf(left_inverse, axiom, product(inverse(X1), X1, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(c_is_an_inverse_of_b, hypothesis, product(c, b, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP009-1.p', c_is_an_inverse_of_b)).
fof(s1, plain, ! [X,Y] : (product(X,identity,Y) => product(X,identity,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_10, lemma, ! [X,Y] : (product(X,identity,Y) => Y = X), inference(mp, [status(thm)], [total_function2, right_identity, s1])).
fof(s2, plain, product(inverse(a),identity,multiply(inverse(a),identity)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_11, lemma, multiply(inverse(a),identity) = inverse(a), inference(mp, [status(thm)], [lemma_10, s2])).
fof(s3, plain, product(inverse(a),a,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s4, plain, product(inverse(a),identity,multiply(inverse(a),identity)), inference(instantiate, [status(thm)], [total_function1])).
fof(s5, plain, product(identity,b,multiply(inverse(a),identity)), inference(mp, [status(thm)], [associativity2, s3, a_is_an_inverse_of_b, s4])).
fof(lemma_12, lemma, product(identity,b,inverse(a)), inference(rewrite, [status(thm)], [lemma_11, s5])).
fof(s6, plain, product(identity,b,multiply(identity,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_13, lemma, multiply(identity,b) = inverse(a), inference(mp, [status(thm)], [total_function2, s6, lemma_12])).
fof(s7, plain, product(identity,b,b), inference(instantiate, [status(thm)], [left_identity])).
fof(s8, plain, product(identity,b,multiply(identity,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_14, lemma, b = multiply(identity,b), inference(mp, [status(thm)], [total_function2, s7, s8])).
fof(s9, plain, inverse(a) = multiply(identity,b), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_15, lemma, inverse(a) = b, inference(rewrite, [status(thm)], [lemma_14, s9])).
fof(s10, plain, product(inverse(a),a,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(lemma_16, lemma, product(b,a,identity), inference(rewrite, [status(thm)], [lemma_15, s10])).
fof(s11, plain, product(identity,a,a), inference(instantiate, [status(thm)], [left_identity])).
fof(s12, plain, product(c,identity,a), inference(mp, [status(thm)], [associativity1, c_is_an_inverse_of_b, lemma_16, s11])).
fof(goal_1, theorem, a = c, inference(mp, [status(thm)], [lemma_10, s12])).
% SZS output end Proof
