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
fof(s1, plain, ! [X] : less_equal(zero,divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero)))), inference(instantiate, [status(thm)], [c8])).
fof(s2, plain, ! [X] : less_equal(divide(divide(X,zero),divide(X,zero)),divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero)))), inference(rewrite, [status(thm)], [c16, s1])).
fof(s3, plain, ! [X] : less_equal(divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero))),divide(divide(X,zero),divide(X,zero))), inference(instantiate, [status(thm)], [c2])).
fof(s4, plain, ! [X] : divide(divide(X,zero),divide(X,zero)) = divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero))), inference(mp, [status(thm)], [c9, s2, s3])).
fof(s5, plain, ! [X] : zero = divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero))), inference(rewrite, [status(thm)], [c16, s4])).
fof(s6, plain, ! [X] : zero = divide(divide(X,divide(X,zero)),zero), inference(rewrite, [status(thm)], [c13, s5])).
fof(s7, plain, ! [X] : less_equal(divide(X,divide(X,zero)),zero), inference(mp, [status(thm)], [c21, s6])).
fof(s8, plain, ! [X] : less_equal(zero,divide(X,divide(X,zero))), inference(instantiate, [status(thm)], [c8])).
fof(s9, plain, ! [X] : divide(X,divide(X,zero)) = zero, inference(mp, [status(thm)], [c9, s7, s8])).
fof(s10, plain, ! [X] : less_equal(X,divide(X,zero)), inference(mp, [status(thm)], [c21, s9])).
fof(s11, plain, ! [X] : less_equal(divide(X,zero),X), inference(instantiate, [status(thm)], [c15])).
fof(lemma_10, lemma, ! [X] : divide(X,zero) = X, inference(mp, [status(thm)], [c9, s10, s11])).
fof(lemma_11, lemma, divide(divide(a,b),d) = zero, inference(mp, [status(thm)], [c3, c5])).
fof(s12, plain, less_equal(divide(divide(a,d),divide(b,d)),divide(divide(a,b),d)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_12, lemma, less_equal(divide(divide(a,d),divide(b,d)),zero), inference(rewrite, [status(thm)], [lemma_11, s12])).
fof(s13, plain, less_equal(divide(b,d),b), inference(instantiate, [status(thm)], [c15])).
fof(lemma_13, lemma, divide(divide(b,d),b) = zero, inference(mp, [status(thm)], [c3, s13])).
fof(s14, plain, less_equal(zero,divide(divide(a,d),divide(b,d))), inference(instantiate, [status(thm)], [c8])).
fof(lemma_14, lemma, zero = divide(divide(a,d),divide(b,d)), inference(mp, [status(thm)], [c9, s14, lemma_12])).
fof(s15, plain, less_equal(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)), inference(instantiate, [status(thm)], [c2])).
fof(s16, plain, divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(divide(divide(a,d),divide(b,d)),b)) = zero, inference(mp, [status(thm)], [c3, s15])).
fof(s17, plain, divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),divide(zero,b)) = zero, inference(rewrite, [status(thm)], [lemma_14, s16])).
fof(s18, plain, divide(divide(divide(divide(a,d),b),divide(divide(b,d),b)),zero) = zero, inference(rewrite, [status(thm)], [c13, s17])).
fof(s19, plain, divide(divide(divide(a,d),b),divide(divide(b,d),b)) = zero, inference(rewrite, [status(thm)], [lemma_10, s18])).
fof(s20, plain, divide(divide(divide(a,d),b),zero) = zero, inference(rewrite, [status(thm)], [lemma_13, s19])).
fof(s21, plain, divide(divide(a,d),b) = zero, inference(rewrite, [status(thm)], [lemma_10, s20])).
fof(goal_1, theorem, less_equal(divide(a,d),b), inference(mp, [status(thm)], [c21, s21])).
% SZS output end Proof
