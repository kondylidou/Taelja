% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('Problems/HEN/HEN003-3.p')).
fof(f2, axiom, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('Problems/HEN/HEN003-3.p')).
fof(f3, axiom, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('Problems/HEN/HEN003-3.p')).
fof(f4, axiom, ! [X2, X0, X1]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('Problems/HEN/HEN003-3.p')).
fof(f5, axiom, ! [X0]: less_equal(zero, X0), file('Problems/HEN/HEN003-3.p')).
fof(f6, axiom, ! [X0, X1]: (~ less_equal(X1, X0) | ~ less_equal(X0, X1) | X0 = X1), file('Problems/HEN/HEN003-3.p')).
fof(lemma_7, lemma, ! [X,Y] : zero = divide(divide(X,Y),X), inference(mp, [status(thm)], [f1, f3])).
fof(s1, plain, ! [X] : (less_equal(X,zero) => less_equal(X,zero)), inference(assumption, [status(thm)], [])).
fof(lemma_8, lemma, ! [X] : (less_equal(X,zero) => zero = X), inference(mp, [status(thm)], [f6, f5, s1])).
fof(s2, plain, less_equal(divide(divide(a,a),divide(divide(a,a),a)),divide(divide(a,divide(a,a)),a)), inference(instantiate, [status(thm)], [f4])).
fof(s3, plain, less_equal(divide(divide(a,a),divide(divide(a,a),a)),zero), inference(rewrite, [status(thm)], [lemma_7, s2])).
fof(s4, plain, less_equal(divide(divide(a,a),zero),zero), inference(rewrite, [status(thm)], [lemma_7, s3])).
fof(s5, plain, zero = divide(divide(a,a),zero), inference(mp, [status(thm)], [lemma_8, s4])).
fof(s6, plain, less_equal(divide(a,a),zero), inference(mp, [status(thm)], [f2, s5])).
fof(goal_1, theorem, divide(a,a) = zero, inference(mp, [status(thm)], [lemma_8, s6])).
% SZS output end Proof
