% SZS output start Proof
fof(f17, axiom, less_equal(divide(a, b), d), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f1, axiom, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f4, axiom, ! [X2, X0, X1]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f5, axiom, ! [X0]: less_equal(zero, X0), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f6, axiom, ! [X0, X1]: (~ less_equal(X1, X0) | ~ less_equal(X0, X1) | X0 = X1), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f2, axiom, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f3, axiom, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('Problems/HEN/HEN006-4.p', unknown)).
fof(f16, axiom, ! [X2, X0, X1]: (~ less_equal(X1, X2) | ~ less_equal(X0, X1) | less_equal(X0, X2)), file('Problems/HEN/HEN006-4.p', unknown)).
fof(lemma_9, lemma, divide(divide(a,b),d) = zero, inference(mp, [status(thm)], [f1, f17])).
fof(s1, plain, less_equal(divide(divide(a,d),divide(b,d)),divide(divide(a,b),d)), inference(instantiate, [status(thm)], [f4])).
fof(lemma_10, lemma, less_equal(divide(divide(a,d),divide(b,d)),zero), inference(rewrite, [status(thm)], [lemma_9, s1])).
fof(s2, plain, less_equal(zero,divide(divide(a,d),divide(b,d))), inference(instantiate, [status(thm)], [f5])).
fof(s3, plain, divide(divide(a,d),divide(b,d)) = zero, inference(mp, [status(thm)], [f6, s2, lemma_10])).
fof(lemma_11, lemma, less_equal(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [f2, s3])).
fof(s4, plain, less_equal(divide(b,d),b), inference(instantiate, [status(thm)], [f3])).
fof(goal_1, theorem, less_equal(divide(a,d),b), inference(mp, [status(thm)], [f16, s4, lemma_11])).
% SZS output end Proof
