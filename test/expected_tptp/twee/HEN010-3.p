% SZS output start Proof
cnf(c2, axiom, less_equal(divide(X, Y), X), file('TPTP/Problems/HEN/HEN010-3.p', quotient_smaller_than_numerator)).
cnf(c3, axiom, less_equal(zero, X2), file('TPTP/Problems/HEN/HEN010-3.p', zero_is_smallest)).
cnf(c4, axiom, less_equal(divide(divide(X2, Z), divide(Y2, Z)), divide(divide(X2, Y2), Z)), file('TPTP/Problems/HEN/HEN010-3.p', quotient_property)).
cnf(c5, axiom, ~ less_equal(X2, Y2) | ~ less_equal(Y2, X2) | X2 = Y2, file('TPTP/Problems/HEN/HEN010-3.p', less_equal_and_equal)).
cnf(c6, axiom, ~ less_equal(X2, Y2) | divide(X2, Y2) = zero, file('TPTP/Problems/HEN/HEN010-3.p', quotient_less_equal1)).
cnf(c13, axiom, divide(X2, Y2) != zero | less_equal(X2, Y2), file('TPTP/Problems/HEN/HEN010-3.p', quotient_less_equal2)).
fof(lemma_7, lemma, ! [X,Y] : divide(divide(X,Y),X) = zero, inference(mp, [status(thm)], [c6, c2])).
fof(lemma_8, lemma, ! [X] : divide(zero,X) = zero, inference(mp, [status(thm)], [c6, c3])).
fof(s1, plain, ! [X] : less_equal(divide(divide(X,X),divide(zero,X)),divide(divide(X,zero),X)), inference(instantiate, [status(thm)], [c4])).
fof(lemma_9, lemma, ! [X] : less_equal(divide(divide(X,X),divide(zero,X)),zero), inference(rewrite, [status(thm)], [lemma_7, s1])).
fof(s2, plain, ! [X] : less_equal(zero,divide(divide(X,X),divide(zero,X))), inference(instantiate, [status(thm)], [c3])).
fof(s3, plain, ! [X] : zero = divide(divide(X,X),divide(zero,X)), inference(mp, [status(thm)], [c5, s2, lemma_9])).
fof(s4, plain, ! [X] : zero = divide(divide(X,X),zero), inference(rewrite, [status(thm)], [lemma_8, s3])).
fof(lemma_10, lemma, ! [X] : less_equal(divide(X,X),zero), inference(mp, [status(thm)], [c13, s4])).
fof(s5, plain, ! [X] : less_equal(zero,divide(X,X)), inference(instantiate, [status(thm)], [c3])).
fof(lemma_11, lemma, ! [X] : divide(X,X) = zero, inference(mp, [status(thm)], [c5, s5, lemma_10])).
fof(s6, plain, ! [X,Y] : less_equal(divide(divide(X,Y),divide(Y,Y)),divide(divide(X,Y),Y)), inference(instantiate, [status(thm)], [c4])).
fof(s7, plain, ! [X,Y] : less_equal(divide(divide(X,Y),zero),divide(divide(X,Y),Y)), inference(rewrite, [status(thm)], [lemma_11, s6])).
fof(lemma_12, lemma, ! [X,Y] : divide(divide(divide(X,Y),zero),divide(divide(X,Y),Y)) = zero, inference(mp, [status(thm)], [c6, s7])).
fof(s8, plain, ! [X,Y] : less_equal(divide(divide(divide(X,Y),divide(divide(X,Y),Y)),divide(zero,divide(divide(X,Y),Y))),divide(divide(divide(X,Y),zero),divide(divide(X,Y),Y))), inference(instantiate, [status(thm)], [c4])).
fof(lemma_13, lemma, ! [X,Y] : less_equal(divide(divide(divide(X,Y),divide(divide(X,Y),Y)),divide(zero,divide(divide(X,Y),Y))),zero), inference(rewrite, [status(thm)], [lemma_12, s8])).
fof(s9, plain, ! [X,Y] : less_equal(zero,divide(divide(divide(X,Y),divide(divide(X,Y),Y)),divide(zero,divide(divide(X,Y),Y)))), inference(instantiate, [status(thm)], [c3])).
fof(s10, plain, ! [X,Y] : zero = divide(divide(divide(X,Y),divide(divide(X,Y),Y)),divide(zero,divide(divide(X,Y),Y))), inference(mp, [status(thm)], [c5, s9, lemma_13])).
fof(s11, plain, ! [X,Y] : zero = divide(divide(divide(X,Y),divide(divide(X,Y),Y)),zero), inference(rewrite, [status(thm)], [lemma_8, s10])).
fof(s12, plain, ! [X,Y] : less_equal(divide(divide(X,Y),divide(divide(X,Y),Y)),zero), inference(mp, [status(thm)], [c13, s11])).
fof(s13, plain, ! [X,Y] : less_equal(zero,divide(divide(X,Y),divide(divide(X,Y),Y))), inference(instantiate, [status(thm)], [c3])).
fof(s14, plain, ! [X,Y] : divide(divide(X,Y),divide(divide(X,Y),Y)) = zero, inference(mp, [status(thm)], [c5, s12, s13])).
fof(s15, plain, ! [X,Y] : less_equal(divide(X,Y),divide(divide(X,Y),Y)), inference(mp, [status(thm)], [c13, s14])).
fof(s16, plain, ! [X,Y] : less_equal(divide(divide(X,Y),Y),divide(X,Y)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_14, lemma, ! [X,Y] : divide(divide(X,Y),Y) = divide(X,Y), inference(mp, [status(thm)], [c5, s15, s16])).
fof(s17, plain, ! [X] : less_equal(divide(divide(X,divide(X,zero)),divide(zero,divide(X,zero))),divide(divide(X,zero),divide(X,zero))), inference(instantiate, [status(thm)], [c4])).
fof(lemma_15, lemma, ! [X] : less_equal(divide(divide(X,divide(X,zero)),zero),divide(divide(X,zero),divide(X,zero))), inference(rewrite, [status(thm)], [lemma_8, s17])).
fof(s18, plain, ! [X] : less_equal(zero,divide(divide(X,divide(X,zero)),zero)), inference(instantiate, [status(thm)], [c3])).
fof(s19, plain, ! [X] : less_equal(divide(divide(X,zero),divide(X,zero)),divide(divide(X,divide(X,zero)),zero)), inference(rewrite, [status(thm)], [lemma_11, s18])).
fof(s20, plain, ! [X] : divide(divide(X,zero),divide(X,zero)) = divide(divide(X,divide(X,zero)),zero), inference(mp, [status(thm)], [c5, s19, lemma_15])).
fof(s21, plain, ! [X] : zero = divide(divide(X,divide(X,zero)),zero), inference(rewrite, [status(thm)], [lemma_11, s20])).
fof(s22, plain, ! [X] : less_equal(divide(X,divide(X,zero)),zero), inference(mp, [status(thm)], [c13, s21])).
fof(s23, plain, ! [X] : less_equal(zero,divide(X,divide(X,zero))), inference(instantiate, [status(thm)], [c3])).
fof(s24, plain, ! [X] : divide(X,divide(X,zero)) = zero, inference(mp, [status(thm)], [c5, s22, s23])).
fof(s25, plain, ! [X] : less_equal(X,divide(X,zero)), inference(mp, [status(thm)], [c13, s24])).
fof(s26, plain, ! [X] : less_equal(divide(X,zero),X), inference(instantiate, [status(thm)], [c2])).
fof(lemma_16, lemma, ! [X] : divide(X,zero) = X, inference(mp, [status(thm)], [c5, s25, s26])).
fof(s27, plain, less_equal(divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a)),divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),divide(identity,a)),a)), inference(instantiate, [status(thm)], [c4])).
fof(lemma_17, lemma, less_equal(divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a)),divide(zero,a)), inference(rewrite, [status(thm)], [lemma_7, s27])).
fof(s28, plain, less_equal(divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))),divide(divide(identity,a),divide(identity,a))), inference(instantiate, [status(thm)], [c4])).
fof(lemma_18, lemma, less_equal(divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))),zero), inference(rewrite, [status(thm)], [lemma_11, s28])).
fof(s29, plain, less_equal(zero,divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a)))), inference(instantiate, [status(thm)], [c3])).
fof(lemma_19, lemma, zero = divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))), inference(mp, [status(thm)], [c5, s29, lemma_18])).
fof(s30, plain, less_equal(divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a)),divide(divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))),a)), inference(instantiate, [status(thm)], [c4])).
fof(lemma_20, lemma, divide(divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a)),divide(divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))),a)) = zero, inference(mp, [status(thm)], [c6, s30])).
fof(s31, plain, less_equal(zero,divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a))), inference(instantiate, [status(thm)], [c3])).
fof(s32, plain, less_equal(divide(zero,a),divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a))), inference(rewrite, [status(thm)], [lemma_8, s31])).
fof(s33, plain, divide(zero,a) = divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a)), inference(mp, [status(thm)], [c5, s32, lemma_17])).
fof(s34, plain, zero = divide(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a)), inference(rewrite, [status(thm)], [lemma_8, s33])).
fof(lemma_21, lemma, less_equal(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),a)), inference(mp, [status(thm)], [c13, s34])).
fof(s35, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(identity,divide(identity,a)),a)),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(instantiate, [status(thm)], [c4])).
fof(s36, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(divide(identity,divide(identity,a)),a),zero)),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_16, s35])).
fof(s37, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a))),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_7, s36])).
fof(s38, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a)),zero)),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_16, s37])).
fof(s39, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a)),divide(zero,a))),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_8, s38])).
fof(s40, plain, less_equal(divide(divide(divide(identity,a),a),divide(divide(divide(divide(identity,divide(identity,a)),a),divide(divide(a,divide(identity,a)),a)),divide(divide(divide(identity,divide(identity,a)),divide(a,divide(identity,a))),a))),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_19, s39])).
fof(s41, plain, less_equal(divide(divide(divide(identity,a),a),zero),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_20, s40])).
fof(s42, plain, less_equal(divide(divide(identity,a),a),divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a)), inference(rewrite, [status(thm)], [lemma_16, s41])).
fof(s43, plain, divide(divide(identity,a),a) = divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a), inference(mp, [status(thm)], [c5, s42, lemma_21])).
fof(lemma_22, lemma, divide(identity,a) = divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a), inference(rewrite, [status(thm)], [lemma_14, s43])).
fof(s44, plain, less_equal(divide(divide(divide(identity,a),divide(identity,divide(identity,a))),a),divide(divide(identity,a),divide(identity,divide(identity,a)))), inference(instantiate, [status(thm)], [c2])).
fof(lemma_23, lemma, less_equal(divide(identity,a),divide(divide(identity,a),divide(identity,divide(identity,a)))), inference(rewrite, [status(thm)], [lemma_22, s44])).
fof(s45, plain, less_equal(divide(divide(identity,a),divide(identity,divide(identity,a))),divide(identity,a)), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, divide(identity,a) = divide(divide(identity,a),divide(identity,divide(identity,a))), inference(mp, [status(thm)], [c5, s45, lemma_23])).
% SZS output end Proof
