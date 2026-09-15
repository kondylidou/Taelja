% SZS output start Proof
fof(f3, axiom, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('Problems/HEN/HEN003-3.p', unknown)).
fof(f1, axiom, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('Problems/HEN/HEN003-3.p', unknown)).
fof(f4, axiom, ! [X2, X0, X1]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('Problems/HEN/HEN003-3.p', unknown)).
fof(f5, axiom, ! [X0]: less_equal(zero, X0), file('Problems/HEN/HEN003-3.p', unknown)).
fof(f6, axiom, ! [X0, X1]: (~ less_equal(X1, X0) | ~ less_equal(X0, X1) | X0 = X1), file('Problems/HEN/HEN003-3.p', unknown)).
fof(f2, axiom, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('Problems/HEN/HEN003-3.p', unknown)).
fof(lemma_7, lemma, ! [X,Y] : zero = divide(divide(X,Y),X), inference(mp, [status(thm)], [f1, f3])).
fof(s1, plain, ! [Z] : less_equal(divide(divide(a,a),divide(divide(a,Z),a)),divide(divide(a,divide(a,Z)),a)), inference(instantiate, [status(thm)], [f4])).
fof(s2, plain, ! [Z] : less_equal(divide(divide(a,a),divide(divide(a,Z),a)),zero), inference(rewrite, [status(thm)], [lemma_7, s1])).
fof(lemma_8, lemma, less_equal(divide(divide(a,a),zero),zero), inference(rewrite, [status(thm)], [lemma_7, s2])).
fof(s3, plain, less_equal(zero,divide(divide(a,a),zero)), inference(instantiate, [status(thm)], [f5])).
fof(s4, plain, divide(divide(a,a),zero) = zero, inference(mp, [status(thm)], [f6, s3, lemma_8])).
fof(lemma_9, lemma, less_equal(divide(a,a),zero), inference(mp, [status(thm)], [f2, s4])).
fof(s5, plain, less_equal(zero,divide(a,a)), inference(instantiate, [status(thm)], [f5])).
fof(goal_1, theorem, divide(a,a) = zero, inference(mp, [status(thm)], [f6, s5, lemma_9])).
% SZS output end Proof
