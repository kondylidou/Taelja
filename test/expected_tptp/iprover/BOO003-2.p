% SZS output start Proof
fof(c_50, plain, ! [X0, X1]: add(X0, X1) = add(X1, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', commutativity_of_add)).
fof(c_52, plain, ! [X0, X1, X2]: multiply(add(X0, X1), add(X2, X1)) = add(multiply(X0, X2), X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', distributivity1)).
fof(c_53, plain, ! [X0, X1, X2]: multiply(add(X0, X1), add(X0, X2)) = add(X0, multiply(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', distributivity2)).
fof(c_55, plain, ! [X0, X1, X2]: add(multiply(X0, X1), multiply(X0, X2)) = multiply(X0, add(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', distributivity4)).
fof(c_56, plain, ! [X0]: add(X0, inverse(X0)) = multiplicative_identity, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', additive_inverse1)).
fof(c_58, plain, ! [X0]: multiply(X0, inverse(X0)) = additive_identity, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', multiplicative_inverse1)).
fof(c_60, plain, ! [X0]: multiply(X0, multiplicative_identity) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', multiplicative_id1)).
fof(c_62, plain, ! [X0]: add(X0, additive_identity) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/BOO003-0.ax', additive_id1)).
fof(s1, plain, ! [X,Y] : multiply(add(X,Y),add(X,inverse(Y))) = add(X,multiply(Y,inverse(Y))), inference(instantiate, [status(thm)], [c_53])).
fof(s2, plain, ! [X,Y] : multiply(add(X,Y),add(X,inverse(Y))) = add(X,additive_identity), inference(rewrite, [status(thm)], [c_58, s1])).
fof(lemma_9, lemma, ! [X,Y] : multiply(add(X,Y),add(X,inverse(Y))) = X, inference(rewrite, [status(thm)], [c_62, s2])).
fof(s3, plain, ! [X,Y] : multiply(add(X,Y),add(Y,inverse(X))) = multiply(add(Y,X),add(Y,inverse(X))), inference(instantiate, [status(thm)], [c_50])).
fof(lemma_10, lemma, ! [X,Y] : multiply(add(X,Y),add(Y,inverse(X))) = Y, inference(rewrite, [status(thm)], [lemma_9, s3])).
fof(s4, plain, ! [X] : add(X,X) = multiply(add(X,X),multiplicative_identity), inference(instantiate, [status(thm)], [c_60])).
fof(s5, plain, ! [X] : add(X,X) = multiply(add(X,X),add(X,inverse(X))), inference(rewrite, [status(thm)], [c_56, s4])).
fof(lemma_11, lemma, ! [X] : add(X,X) = X, inference(rewrite, [status(thm)], [lemma_9, s5])).
fof(s6, plain, multiply(a,a) = multiply(multiply(a,multiplicative_identity),a), inference(instantiate, [status(thm)], [c_60])).
fof(s7, plain, multiply(a,a) = multiply(multiply(a,add(a,inverse(a))),a), inference(rewrite, [status(thm)], [c_56, s6])).
fof(s8, plain, multiply(a,a) = multiply(multiply(a,add(a,inverse(a))),multiply(add(a,a),add(a,inverse(a)))), inference(rewrite, [status(thm)], [lemma_10, s7])).
fof(s9, plain, multiply(a,a) = multiply(multiply(a,add(a,inverse(a))),add(a,multiply(a,inverse(a)))), inference(rewrite, [status(thm)], [c_53, s8])).
fof(s10, plain, multiply(a,a) = multiply(multiply(add(a,a),add(a,inverse(a))),add(a,multiply(a,inverse(a)))), inference(rewrite, [status(thm)], [lemma_11, s9])).
fof(s11, plain, multiply(a,a) = multiply(add(a,multiply(a,inverse(a))),add(a,multiply(a,inverse(a)))), inference(rewrite, [status(thm)], [c_53, s10])).
fof(s12, plain, multiply(a,a) = add(multiply(a,a),multiply(a,inverse(a))), inference(rewrite, [status(thm)], [c_52, s11])).
fof(s13, plain, multiply(a,a) = multiply(a,add(a,inverse(a))), inference(rewrite, [status(thm)], [c_55, s12])).
fof(s14, plain, multiply(a,a) = multiply(a,multiplicative_identity), inference(rewrite, [status(thm)], [c_56, s13])).
fof(goal_1, theorem, multiply(a,a) = a, inference(rewrite, [status(thm)], [c_60, s14])).
% SZS output end Proof
