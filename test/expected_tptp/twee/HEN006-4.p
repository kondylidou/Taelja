% SZS output start Proof
cnf(c2, axiom, less_equal(divide(divide(X, Z), divide(Y, Z)), divide(divide(X, Y), Z)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', quotient_property)).
cnf(c3, axiom, ~ less_equal(X2, Y2) | divide(X2, Y2) = zero, file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', quotient_less_equal1)).
cnf(c5, hypothesis, less_equal(divide(a, b), d), file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', a_divide_b_LE_d)).
cnf(c8, axiom, less_equal(zero, X2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', zero_is_smallest)).
cnf(c9, axiom, ~ less_equal(X2, Y2) | ~ less_equal(Y2, X2) | X2 = Y2, file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', less_equal_and_equal)).
cnf(c13, axiom, divide(zero, X2) = zero, file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', zero_divide_anything_is_zero)).
cnf(c15, axiom, less_equal(divide(X2, Y2), X2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', quotient_smaller_than_numerator)).
cnf(c16, axiom, divide(X2, X2) = zero, file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', x_divide_x_is_zero)).
cnf(c21, axiom, divide(X2, Y2) != zero | less_equal(X2, Y2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/HEN/HEN006-4.p', quotient_less_equal2)).
fof(lemma_10, lemma, divide(divide(a,b),d) = zero, inference(mp, [status(thm)], [c3, c5])).
fof(s1, plain, less_equal(divide(divide(a,d),divide(b,d)),divide(divide(a,b),d)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_11, lemma, less_equal(divide(divide(a,d),divide(b,d)),zero), inference(rewrite, [status(thm)], [lemma_10, s1])).
fof(s2, plain, less_equal(divide(b,d),b), inference(instantiate, [status(thm)], [c15])).
fof(lemma_12, lemma, divide(divide(b,d),b) = zero, inference(mp, [status(thm)], [c3, s2])).
fof(s3, plain, less_equal(zero,divide(divide(a,d),divide(b,d))), inference(instantiate, [status(thm)], [c8])).
fof(lemma_13, lemma, zero = divide(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [c9, s3, lemma_11])).
fof(s4, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_14, lemma, divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)) = zero, inference(mp, [status(thm)], [c3, s4])).
fof(s5, plain, less_equal(zero,divide(divide(b,d),b)), inference(instantiate, [status(thm)], [c8])).
fof(s6, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [lemma_14, s5])).
fof(s7, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(zero,b)),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [lemma_13, s6])).
fof(s8, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [c13, s7])).
fof(s9, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b))),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [lemma_14, s8])).
fof(s10, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(zero,b))),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [lemma_13, s9])).
fof(s11, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero)),divide(divide(b,d),b)), inference(rewrite, [status(thm)], [c13, s10])).
fof(lemma_15, lemma, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero)),zero), inference(rewrite, [status(thm)], [lemma_12, s11])).
fof(s12, plain, less_equal(zero,divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero))), inference(instantiate, [status(thm)], [c8])).
fof(s13, plain, divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero)) = zero, inference(mp, [status(thm)], [c9, lemma_15, s12])).
fof(s14, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero)), inference(mp, [status(thm)], [c21, s13])).
fof(s15, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero),divide(divide(divide(a,d),b),divide(divide(b,d),b))), inference(instantiate, [status(thm)], [c15])).
fof(lemma_16, lemma, divide(divide(divide(a,d),b),divide(divide(b,d),b)) = divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero), inference(mp, [status(thm)], [c9, s14, s15])).
fof(s16, plain, less_equal(zero,zero), inference(instantiate, [status(thm)], [c8])).
fof(s17, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)),zero), inference(rewrite, [status(thm)], [lemma_14, s16])).
fof(s18, plain, less_equal(divide(divide(divide(divide(a,d),b),zero),divide(divide(divide(a,d),divide(b,d)),b)),zero), inference(rewrite, [status(thm)], [lemma_12, s17])).
fof(s19, plain, less_equal(divide(divide(divide(divide(a,d),b),zero),divide(zero,b)),zero), inference(rewrite, [status(thm)], [lemma_13, s18])).
fof(s20, plain, less_equal(divide(divide(divide(divide(a,d),b),zero),zero),zero), inference(rewrite, [status(thm)], [c13, s19])).
fof(s21, plain, less_equal(divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero),zero), inference(rewrite, [status(thm)], [lemma_12, s20])).
fof(s22, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero), inference(rewrite, [status(thm)], [lemma_16, s21])).
fof(s23, plain, less_equal(divide(divide(divide(a,d),b),zero),zero), inference(rewrite, [status(thm)], [lemma_12, s22])).
fof(s24, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b))),zero), inference(rewrite, [status(thm)], [lemma_14, s23])).
fof(s25, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(divide(a,d),b),zero),divide(divide(divide(a,d),divide(b,d)),b))),zero), inference(rewrite, [status(thm)], [lemma_12, s24])).
fof(s26, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(divide(a,d),b),zero),divide(zero,b))),zero), inference(rewrite, [status(thm)], [lemma_13, s25])).
fof(s27, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(divide(a,d),b),zero),zero)),zero), inference(rewrite, [status(thm)], [c13, s26])).
fof(s28, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero)),zero), inference(rewrite, [status(thm)], [lemma_12, s27])).
fof(s29, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(a,d),b),divide(divide(b,d),b))),zero), inference(rewrite, [status(thm)], [lemma_16, s28])).
fof(lemma_17, lemma, less_equal(divide(divide(divide(a,d),b),divide(divide(divide(a,d),b),zero)),zero), inference(rewrite, [status(thm)], [lemma_12, s29])).
fof(s30, plain, less_equal(zero,divide(divide(divide(a,d),b),divide(divide(divide(a,d),b),zero))), inference(instantiate, [status(thm)], [c8])).
fof(s31, plain, divide(divide(divide(a,d),b),divide(divide(divide(a,d),b),zero)) = zero, inference(mp, [status(thm)], [c9, lemma_17, s30])).
fof(s32, plain, less_equal(divide(divide(a,d),b),divide(divide(divide(a,d),b),zero)), inference(mp, [status(thm)], [c21, s31])).
fof(s33, plain, less_equal(divide(divide(divide(a,d),b),zero),divide(divide(a,d),b)), inference(instantiate, [status(thm)], [c15])).
fof(lemma_18, lemma, divide(divide(a,d),b) = divide(divide(divide(a,d),b),zero), inference(mp, [status(thm)], [c9, s32, s33])).
fof(s34, plain, divide(divide(a,d),b) = divide(divide(divide(a,d),b),divide(zero,b)), inference(rewrite, [status(thm)], [c13, lemma_18])).
fof(s35, plain, divide(divide(a,d),b) = divide(divide(divide(a,d),b),divide(divide(divide(a,d),divide(b,d)),b)), inference(rewrite, [status(thm)], [lemma_13, s34])).
fof(s36, plain, divide(divide(a,d),b) = divide(divide(divide(divide(a,d),b),zero),divide(divide(divide(a,d),divide(b,d)),b)), inference(rewrite, [status(thm)], [lemma_18, s35])).
fof(s37, plain, divide(divide(a,d),b) = divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)), inference(rewrite, [status(thm)], [lemma_12, s36])).
fof(lemma_19, lemma, divide(divide(a,d),b) = zero, inference(rewrite, [status(thm)], [lemma_14, s37])).
fof(goal_1, theorem, less_equal(divide(a,d),b), inference(mp, [status(thm)], [c21, lemma_19])).
% SZS output end Proof
