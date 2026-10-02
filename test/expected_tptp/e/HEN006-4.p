% SZS output start Proof
cnf(quotient_less_equal1, axiom, divide(X1, X2) = zero | ~ less_equal(X1, X2), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal1)).
cnf(a_divide_b_LE_d, hypothesis, less_equal(divide(a, b), d), file('Problems/HEN/HEN006-4.p', a_divide_b_LE_d)).
cnf(less_equal_and_equal, axiom, X1 = X2 | ~ less_equal(X1, X2) | ~ less_equal(X2, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', less_equal_and_equal)).
cnf(quotient_property, axiom, less_equal(divide(divide(X1, X2), divide(X3, X2)), divide(divide(X1, X3), X2)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_property)).
cnf(transitivity_of_less_equal, axiom, less_equal(X1, X3) | ~ less_equal(X1, X2) | ~ less_equal(X2, X3), file('Problems/HEN/HEN006-4.p', transitivity_of_less_equal)).
cnf(quotient_less_equal2, axiom, less_equal(X1, X2) | divide(X1, X2) != zero, file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal2)).
cnf(zero_is_smallest, axiom, less_equal(zero, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', zero_is_smallest)).
cnf(quotient_smaller_than_numerator, axiom, less_equal(divide(X1, X2), X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_smaller_than_numerator)).
fof(lemma_9, lemma, divide(divide(a,b),d) = zero, inference(mp, [status(thm)], [quotient_less_equal1, a_divide_b_LE_d])).
fof(s1, plain, less_equal(divide(divide(a,d),divide(b,d)),divide(divide(a,b),d)), inference(instantiate, [status(thm)], [quotient_property])).
fof(lemma_10, lemma, less_equal(divide(divide(a,d),divide(b,d)),zero), inference(rewrite, [status(thm)], [lemma_9, s1])).
fof(s2, plain, less_equal(zero,divide(divide(a,d),divide(b,d))), inference(instantiate, [status(thm)], [zero_is_smallest])).
fof(s3, plain, divide(divide(a,d),divide(b,d)) = zero, inference(mp, [status(thm)], [less_equal_and_equal, lemma_10, s2])).
fof(s4, plain, less_equal(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [quotient_less_equal2, s3])).
fof(s5, plain, less_equal(divide(b,d),b), inference(instantiate, [status(thm)], [quotient_smaller_than_numerator])).
fof(goal_1, theorem, less_equal(divide(a,d),b), inference(mp, [status(thm)], [transitivity_of_less_equal, s4, s5])).
% SZS output end Proof
