% SZS output start Proof
fof(c_53, plain, ! [X0, X1, X2]: (~ less_equal(X0, X1) | ~ less_equal(X1, X2) | less_equal(X0, X2)), file('Problems/HEN/HEN006-4.p', transitivity_of_less_equal)).
fof(c_54, plain, less_equal(divide(a, b), d), file('Problems/HEN/HEN006-4.p', a_divide_b_LE_d)).
fof(c_56, plain, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal1)).
fof(c_57, plain, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal2)).
fof(c_58, plain, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_smaller_than_numerator)).
fof(c_59, plain, ! [X0, X1, X2]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_property)).
fof(c_60, plain, ! [X0]: less_equal(zero, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', zero_is_smallest)).
fof(c_61, plain, ! [X0, X1]: (~ less_equal(X0, X1) | ~ less_equal(X1, X0) | X0 = X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', less_equal_and_equal)).
fof(lemma_9, lemma, divide(divide(a,b),d) = zero, inference(mp, [status(thm)], [c_56, c_54])).
fof(s1, plain, less_equal(divide(divide(a,d),divide(b,d)),divide(divide(a,b),d)), inference(instantiate, [status(thm)], [c_59])).
fof(lemma_10, lemma, less_equal(divide(divide(a,d),divide(b,d)),zero), inference(rewrite, [status(thm)], [lemma_9, s1])).
fof(s2, plain, less_equal(zero,divide(divide(a,d),divide(b,d))), inference(instantiate, [status(thm)], [c_60])).
fof(s3, plain, zero = divide(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [c_61, s2, lemma_10])).
fof(s4, plain, less_equal(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [c_57, s3])).
fof(s5, plain, less_equal(divide(b,d),b), inference(instantiate, [status(thm)], [c_58])).
fof(goal_1, theorem, less_equal(divide(a,d),b), inference(mp, [status(thm)], [c_53, s4, s5])).
% SZS output end Proof
