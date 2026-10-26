% SZS output start Proof
fof(c_50, plain, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal1)).
fof(c_51, plain, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal2)).
fof(c_52, plain, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_smaller_than_numerator)).
fof(c_53, plain, ! [X0, X1, X2]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_property)).
fof(c_54, plain, ! [X0]: less_equal(zero, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', zero_is_smallest)).
fof(c_55, plain, ! [X0, X1]: (~ less_equal(X0, X1) | ~ less_equal(X1, X0) | X0 = X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', less_equal_and_equal)).
fof(lemma_7, lemma, ! [X,Y] : divide(divide(X,Y),X) = zero, inference(mp, [status(thm)], [c_50, c_52])).
fof(s1, plain, ! [X] : (less_equal(X,zero) => less_equal(X,zero)), inference(assumption, [status(thm)], [])).
fof(lemma_8, lemma, ! [X] : (less_equal(X,zero) => X = zero), inference(mp, [status(thm)], [c_55, c_54, s1])).
fof(s2, plain, less_equal(divide(divide(a,a),divide(divide(a,a),a)),divide(divide(a,divide(a,a)),a)), inference(instantiate, [status(thm)], [c_53])).
fof(s3, plain, less_equal(divide(divide(a,a),divide(divide(a,a),a)),zero), inference(rewrite, [status(thm)], [lemma_7, s2])).
fof(s4, plain, less_equal(divide(divide(a,a),zero),zero), inference(rewrite, [status(thm)], [lemma_7, s3])).
fof(s5, plain, divide(divide(a,a),zero) = zero, inference(mp, [status(thm)], [lemma_8, s4])).
fof(s6, plain, less_equal(divide(a,a),zero), inference(mp, [status(thm)], [c_51, s5])).
fof(goal_1, theorem, divide(a,a) = zero, inference(mp, [status(thm)], [lemma_8, s6])).
% SZS output end Proof
