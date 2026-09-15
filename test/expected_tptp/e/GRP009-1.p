% SZS output start Proof
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(right_inverse, axiom, product(X1, inverse(X1), identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
cnf(c_is_an_inverse_of_b, hypothesis, product(c, b, identity), file('Problems/GRP/GRP009-1.p', c_is_an_inverse_of_b)).
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(a_is_an_inverse_of_b, hypothesis, product(a, b, identity), file('Problems/GRP/GRP009-1.p', a_is_an_inverse_of_b)).
cnf(left_inverse, axiom, product(inverse(X1), X1, identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
fof(s1, plain, ! [X] : product(identity,X,multiply(identity,X)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_10, lemma, ! [X] : multiply(identity,X) = X, inference(mp, [status(thm)], [total_function2, left_identity, s1])).
fof(s2, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s3, plain, product(c,identity,c), inference(instantiate, [status(thm)], [right_identity])).
fof(lemma_11, lemma, product(identity,inverse(b),c), inference(mp, [status(thm)], [associativity2, c_is_an_inverse_of_b, s2, s3])).
fof(s4, plain, product(inverse(a),a,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s5, plain, product(inverse(a),identity,inverse(a)), inference(instantiate, [status(thm)], [right_identity])).
fof(lemma_12, lemma, product(identity,b,inverse(a)), inference(mp, [status(thm)], [associativity2, s4, a_is_an_inverse_of_b, s5])).
fof(s6, plain, product(identity,b,multiply(identity,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_13, lemma, multiply(identity,b) = inverse(a), inference(mp, [status(thm)], [total_function2, s6, lemma_12])).
fof(s7, plain, product(inverse(a),a,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s8, plain, product(multiply(identity,b),a,identity), inference(rewrite, [status(thm)], [lemma_13, s7])).
fof(lemma_14, lemma, product(b,a,identity), inference(rewrite, [status(thm)], [lemma_10, s8])).
fof(s9, plain, product(identity,inverse(b),multiply(identity,inverse(b))), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_15, lemma, multiply(identity,inverse(b)) = c, inference(mp, [status(thm)], [total_function2, s9, lemma_11])).
fof(s10, plain, product(inverse(b),b,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s11, plain, product(inverse(b),identity,inverse(b)), inference(instantiate, [status(thm)], [right_identity])).
fof(lemma_16, lemma, product(identity,a,inverse(b)), inference(mp, [status(thm)], [associativity2, s10, lemma_14, s11])).
fof(s12, plain, product(identity,a,multiply(identity,inverse(b))), inference(rewrite, [status(thm)], [lemma_10, lemma_16])).
fof(lemma_17, lemma, product(identity,a,c), inference(rewrite, [status(thm)], [lemma_15, s12])).
fof(s13, plain, product(identity,a,multiply(identity,a)), inference(instantiate, [status(thm)], [total_function1])).
fof(s14, plain, multiply(identity,a) = c, inference(mp, [status(thm)], [total_function2, s13, lemma_17])).
fof(goal_1, theorem, a = c, inference(rewrite, [status(thm)], [lemma_10, s14])).
% SZS output end Proof
