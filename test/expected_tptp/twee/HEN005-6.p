% SZS output start Proof
cnf(c2, hypothesis, less_equal(b, c), file('HEN005-6.p', b_LE_c)).
cnf(c3, axiom, ~ less_equal(X, Y) | divide(X, Y) = zero, file('HEN005-6.p', quotient_less_equal1)).
cnf(c9, axiom, divide(zero, X2) = zero, file('HEN005-6.p', zero_divide_anything_is_zero)).
cnf(c6, hypothesis, less_equal(a, b), file('HEN005-6.p', a_LE_b)).
cnf(c5, axiom, less_equal(divide(divide(X2, Z), divide(Y2, Z)), divide(divide(X2, Y2), Z)), file('HEN005-6.p', quotient_property)).
cnf(c11, axiom, less_equal(zero, X2), file('HEN005-6.p', zero_is_smallest)).
cnf(c12, axiom, ~ less_equal(X2, Y2) | ~ less_equal(Y2, X2) | X2 = Y2, file('HEN005-6.p', less_equal_and_equal)).
cnf(c16, axiom, divide(X2, Y2) != zero | less_equal(X2, Y2), file('HEN005-6.p', quotient_less_equal2)).
fof(lemma_9, lemma, divide(a,b) = zero, inference(mp, [status(thm)], [c3, c6])).
fof(s1, plain, less_equal(divide(divide(a,c),divide(b,c)),divide(divide(a,b),c)), inference(instantiate, [status(thm)], [c5])).
fof(s2, plain, less_equal(divide(divide(a,c),divide(b,c)),divide(zero,c)), inference(rewrite, [status(thm)], [lemma_9, s1])).
fof(lemma_10, lemma, less_equal(divide(divide(a,c),divide(b,c)),zero), inference(rewrite, [status(thm)], [c9, s2])).
fof(lemma_11, lemma, divide(b,c) = zero, inference(mp, [status(thm)], [c3, c2])).
fof(s3, plain, less_equal(zero,divide(divide(a,c),divide(b,c))), inference(instantiate, [status(thm)], [c11])).
fof(s4, plain, zero = divide(divide(a,c),divide(b,c)), inference(mp, [status(thm)], [c12, s3, lemma_10])).
fof(s5, plain, zero = divide(divide(a,c),zero), inference(rewrite, [status(thm)], [lemma_11, s4])).
fof(lemma_12, lemma, less_equal(divide(a,c),zero), inference(mp, [status(thm)], [c16, s5])).
fof(s6, plain, less_equal(zero,divide(a,c)), inference(instantiate, [status(thm)], [c11])).
fof(s7, plain, zero = divide(a,c), inference(mp, [status(thm)], [c12, s6, lemma_12])).
fof(goal_1, theorem, less_equal(a,c), inference(mp, [status(thm)], [c16, s7])).
% SZS output end Proof
