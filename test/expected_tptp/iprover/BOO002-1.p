% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2, X3, X4]: multiply(multiply(X0, X1, X2), X3, multiply(X0, X1, X4)) = multiply(X0, X1, multiply(X2, X3, X4)), file('Problems/BOO/BOO002-1.p', associativity)).
fof(c_50, plain, ! [X0, X1]: multiply(X0, X1, X1) = X1, file('Problems/BOO/BOO002-1.p', ternary_multiply_1)).
fof(c_51, plain, ! [X0, X1]: multiply(X0, X0, X1) = X0, file('Problems/BOO/BOO002-1.p', ternary_multiply_2)).
fof(c_52, plain, ! [X0, X1]: multiply(inverse(X0), X0, X1) = X1, file('Problems/BOO/BOO002-1.p', left_inverse)).
fof(lemma_5, lemma, ! [X] : multiply(inverse(a),a,X) = X, inference(instantiate, [status(thm)], [c_52])).
fof(s1, plain, ! [X] : multiply(multiply(a,inverse(a),b),b,multiply(a,inverse(a),X)) = multiply(a,inverse(a),multiply(b,b,X)), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_6, lemma, ! [X] : multiply(multiply(a,inverse(a),b),b,multiply(a,inverse(a),X)) = multiply(a,inverse(a),b), inference(rewrite, [status(thm)], [c_51, s1])).
fof(s2, plain, multiply(multiply(a,inverse(a),b),b,inverse(a)) = multiply(multiply(a,inverse(a),b),b,multiply(a,inverse(a),inverse(a))), inference(instantiate, [status(thm)], [c_50])).
fof(lemma_7, lemma, multiply(multiply(a,inverse(a),b),b,inverse(a)) = multiply(a,inverse(a),b), inference(rewrite, [status(thm)], [lemma_6, s2])).
fof(s3, plain, ! [X,Y] : multiply(X,Y,X) = multiply(X,Y,multiply(X,X,X)), inference(instantiate, [status(thm)], [c_51])).
fof(s4, plain, ! [X,Y] : multiply(X,Y,X) = multiply(multiply(X,X,X),Y,multiply(X,X,X)), inference(rewrite, [status(thm)], [c_50, s3])).
fof(s5, plain, ! [X,Y] : multiply(X,Y,X) = multiply(X,X,multiply(X,Y,X)), inference(rewrite, [status(thm)], [c_49, s4])).
fof(lemma_8, lemma, ! [X,Y] : multiply(X,Y,X) = X, inference(rewrite, [status(thm)], [c_51, s5])).
fof(s6, plain, multiply(multiply(a,inverse(a),b),b,a) = multiply(multiply(a,inverse(a),b),b,multiply(a,inverse(a),a)), inference(instantiate, [status(thm)], [lemma_8])).
fof(lemma_9, lemma, multiply(multiply(a,inverse(a),b),b,a) = multiply(a,inverse(a),b), inference(rewrite, [status(thm)], [lemma_6, s6])).
fof(s7, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),b,a), inference(instantiate, [status(thm)], [lemma_9])).
fof(s8, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),b,multiply(a,a,b)), inference(rewrite, [status(thm)], [c_51, s7])).
fof(s9, plain, multiply(a,inverse(a),b) = multiply(multiply(multiply(a,inverse(a),b),b,a),a,multiply(multiply(a,inverse(a),b),b,b)), inference(rewrite, [status(thm)], [c_49, s8])).
fof(s10, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),a,multiply(multiply(a,inverse(a),b),b,b)), inference(rewrite, [status(thm)], [lemma_9, s9])).
fof(s11, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),a,b), inference(rewrite, [status(thm)], [c_50, s10])).
fof(s12, plain, multiply(a,inverse(a),b) = multiply(multiply(multiply(a,inverse(a),b),b,inverse(a)),a,b), inference(rewrite, [status(thm)], [lemma_7, s11])).
fof(s13, plain, multiply(a,inverse(a),b) = multiply(multiply(multiply(a,inverse(a),b),b,inverse(a)),a,multiply(multiply(a,inverse(a),b),b,b)), inference(rewrite, [status(thm)], [c_50, s12])).
fof(s14, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),b,multiply(inverse(a),a,b)), inference(rewrite, [status(thm)], [c_49, s13])).
fof(s15, plain, multiply(a,inverse(a),b) = multiply(multiply(a,inverse(a),b),b,b), inference(rewrite, [status(thm)], [lemma_5, s14])).
fof(goal_1, theorem, multiply(a,inverse(a),b) = b, inference(rewrite, [status(thm)], [c_50, s15])).
% SZS output end Proof
