% SZS output start Proof
cnf(c2, axiom, less_equal(divide(X, Y), X), file('TPTP/Problems/HEN/HEN004-6.p', quotient_smaller_than_numerator)).
cnf(c3, axiom, less_equal(zero, X2), file('TPTP/Problems/HEN/HEN004-6.p', zero_is_smallest)).
cnf(c4, axiom, less_equal(divide(divide(X2, Z), divide(Y2, Z)), divide(divide(X2, Y2), Z)), file('TPTP/Problems/HEN/HEN004-6.p', quotient_property)).
cnf(c5, axiom, ~ less_equal(X2, Y2) | ~ less_equal(Y2, X2) | X2 = Y2, file('TPTP/Problems/HEN/HEN004-6.p', less_equal_and_equal)).
cnf(c6, axiom, ~ less_equal(X2, Y2) | divide(X2, Y2) = zero, file('TPTP/Problems/HEN/HEN004-6.p', quotient_less_equal1)).
cnf(c9, axiom, divide(zero, X2) = zero, file('TPTP/Problems/HEN/HEN004-6.p', zero_divide_anything_is_zero)).
cnf(c20, axiom, divide(X2, Y2) != zero | less_equal(X2, Y2), file('TPTP/Problems/HEN/HEN004-6.p', quotient_less_equal2)).
fof(s1, plain, less_equal(divide(a,zero),a), inference(instantiate, [status(thm)], [c2])).
fof(lemma_8, lemma, divide(divide(a,zero),a) = zero, inference(mp, [status(thm)], [c6, s1])).
fof(s2, plain, less_equal(zero,divide(divide(a,a),zero)), inference(instantiate, [status(thm)], [c3])).
fof(lemma_9, lemma, less_equal(divide(divide(a,zero),a),divide(divide(a,a),zero)), inference(rewrite, [status(thm)], [lemma_8, s2])).
fof(s3, plain, less_equal(divide(divide(a,a),divide(zero,a)),divide(divide(a,zero),a)), inference(instantiate, [status(thm)], [c4])).
fof(s4, plain, less_equal(divide(divide(a,a),zero),divide(divide(a,zero),a)), inference(rewrite, [status(thm)], [c9, s3])).
fof(s5, plain, divide(divide(a,a),zero) = divide(divide(a,zero),a), inference(mp, [status(thm)], [c5, s4, lemma_9])).
fof(lemma_10, lemma, divide(divide(a,a),zero) = zero, inference(rewrite, [status(thm)], [lemma_8, s5])).
fof(s6, plain, less_equal(zero,divide(divide(a,zero),divide(a,zero))), inference(instantiate, [status(thm)], [c3])).
fof(lemma_11, lemma, less_equal(divide(divide(a,a),zero),divide(divide(a,zero),divide(a,zero))), inference(rewrite, [status(thm)], [lemma_10, s6])).
fof(s7, plain, less_equal(divide(divide(a,zero),divide(a,zero)),divide(divide(a,a),zero)), inference(instantiate, [status(thm)], [c4])).
fof(s8, plain, divide(divide(a,zero),divide(a,zero)) = divide(divide(a,a),zero), inference(mp, [status(thm)], [c5, s7, lemma_11])).
fof(lemma_12, lemma, divide(divide(a,zero),divide(a,zero)) = zero, inference(rewrite, [status(thm)], [lemma_10, s8])).
fof(s9, plain, less_equal(zero,divide(divide(a,divide(a,zero)),zero)), inference(instantiate, [status(thm)], [c3])).
fof(lemma_13, lemma, less_equal(divide(divide(a,zero),divide(a,zero)),divide(divide(a,divide(a,zero)),zero)), inference(rewrite, [status(thm)], [lemma_12, s9])).
fof(s10, plain, less_equal(divide(divide(a,divide(a,zero)),divide(zero,divide(a,zero))),divide(divide(a,zero),divide(a,zero))), inference(instantiate, [status(thm)], [c4])).
fof(s11, plain, less_equal(divide(divide(a,divide(a,zero)),zero),divide(divide(a,zero),divide(a,zero))), inference(rewrite, [status(thm)], [c9, s10])).
fof(s12, plain, divide(divide(a,divide(a,zero)),zero) = divide(divide(a,zero),divide(a,zero)), inference(mp, [status(thm)], [c5, s11, lemma_13])).
fof(s13, plain, divide(divide(a,divide(a,zero)),zero) = zero, inference(rewrite, [status(thm)], [lemma_12, s12])).
fof(s14, plain, less_equal(divide(a,divide(a,zero)),zero), inference(mp, [status(thm)], [c20, s13])).
fof(s15, plain, less_equal(zero,divide(a,divide(a,zero))), inference(instantiate, [status(thm)], [c3])).
fof(s16, plain, divide(a,divide(a,zero)) = zero, inference(mp, [status(thm)], [c5, s14, s15])).
fof(s17, plain, less_equal(a,divide(a,zero)), inference(mp, [status(thm)], [c20, s16])).
fof(s18, plain, less_equal(divide(a,zero),a), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, divide(a,zero) = a, inference(mp, [status(thm)], [c5, s17, s18])).
% SZS output end Proof
