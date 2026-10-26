% SZS output start Proof
fof(c_50, plain, divide(identity, a) = b, file('Problems/HEN/HEN009-3.p', id_divide_a_is_b)).
fof(c_51, plain, divide(identity, b) = c, file('Problems/HEN/HEN009-3.p', id_divide_b_is_c)).
fof(c_52, plain, divide(identity, c) = d, file('Problems/HEN/HEN009-3.p', id_divide_c_is_d)).
fof(c_54, plain, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal1)).
fof(c_55, plain, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_less_equal2)).
fof(c_56, plain, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_smaller_than_numerator)).
fof(c_57, plain, ! [X0, X1, X2]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', quotient_property)).
fof(c_58, plain, ! [X0]: less_equal(zero, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', zero_is_smallest)).
fof(c_59, plain, ! [X0, X1]: (~ less_equal(X0, X1) | ~ less_equal(X1, X0) | X0 = X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', less_equal_and_equal)).
fof(c_60, plain, ! [X0]: less_equal(X0, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN002-0.ax', identity_is_largest)).
fof(lemma_11, lemma, ! [X] : divide(X,identity) = zero, inference(mp, [status(thm)], [c_54, c_60])).
fof(lemma_12, lemma, ! [X] : divide(zero,X) = zero, inference(mp, [status(thm)], [c_54, c_58])).
fof(s1, plain, ! [X] : (less_equal(X,zero) => less_equal(X,zero)), inference(assumption, [status(thm)], [])).
fof(lemma_13, lemma, ! [X] : (less_equal(X,zero) => X = zero), inference(mp, [status(thm)], [c_59, c_58, s1])).
fof(s2, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),divide(divide(X,identity),a)), inference(instantiate, [status(thm)], [c_57])).
fof(s3, plain, ! [X] : less_equal(divide(divide(X,a),b),divide(divide(X,identity),a)), inference(rewrite, [status(thm)], [c_50, s2])).
fof(s4, plain, ! [X] : less_equal(divide(divide(X,a),b),divide(zero,a)), inference(rewrite, [status(thm)], [lemma_11, s3])).
fof(s5, plain, ! [X] : less_equal(divide(divide(X,a),b),zero), inference(rewrite, [status(thm)], [lemma_12, s4])).
fof(lemma_14, lemma, ! [X] : divide(divide(X,a),b) = zero, inference(mp, [status(thm)], [lemma_13, s5])).
fof(lemma_15, lemma, ! [X,Y] : divide(divide(X,Y),X) = zero, inference(mp, [status(thm)], [c_54, c_56])).
fof(s6, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),divide(divide(X,identity),b)), inference(instantiate, [status(thm)], [c_57])).
fof(s7, plain, ! [X] : less_equal(divide(divide(X,b),c),divide(divide(X,identity),b)), inference(rewrite, [status(thm)], [c_51, s6])).
fof(s8, plain, ! [X] : less_equal(divide(divide(X,b),c),divide(zero,b)), inference(rewrite, [status(thm)], [lemma_11, s7])).
fof(s9, plain, ! [X] : less_equal(divide(divide(X,b),c),zero), inference(rewrite, [status(thm)], [lemma_12, s8])).
fof(lemma_16, lemma, ! [X] : divide(divide(X,b),c) = zero, inference(mp, [status(thm)], [lemma_13, s9])).
fof(s10, plain, less_equal(divide(divide(divide(b,zero),divide(b,zero)),divide(divide(divide(b,zero),b),divide(b,zero))),divide(divide(divide(b,zero),divide(divide(b,zero),b)),divide(b,zero))), inference(instantiate, [status(thm)], [c_57])).
fof(s11, plain, less_equal(divide(divide(divide(b,zero),divide(b,zero)),divide(divide(divide(b,zero),b),divide(b,zero))),zero), inference(rewrite, [status(thm)], [lemma_15, s10])).
fof(s12, plain, less_equal(divide(divide(divide(b,zero),divide(b,zero)),zero),zero), inference(rewrite, [status(thm)], [lemma_15, s11])).
fof(s13, plain, divide(divide(divide(b,zero),divide(b,zero)),zero) = zero, inference(mp, [status(thm)], [lemma_13, s12])).
fof(s14, plain, less_equal(divide(divide(b,zero),divide(b,zero)),zero), inference(mp, [status(thm)], [c_55, s13])).
fof(lemma_17, lemma, divide(divide(b,zero),divide(b,zero)) = zero, inference(mp, [status(thm)], [lemma_13, s14])).
fof(s15, plain, divide(divide(a,b),c) = zero, inference(instantiate, [status(thm)], [lemma_16])).
fof(lemma_18, lemma, less_equal(divide(a,b),c), inference(mp, [status(thm)], [c_55, s15])).
fof(s16, plain, less_equal(divide(divide(identity,b),divide(a,b)),divide(divide(identity,a),b)), inference(instantiate, [status(thm)], [c_57])).
fof(s17, plain, less_equal(divide(divide(identity,b),divide(a,b)),zero), inference(rewrite, [status(thm)], [lemma_14, s16])).
fof(s18, plain, less_equal(divide(c,divide(a,b)),zero), inference(rewrite, [status(thm)], [c_51, s17])).
fof(s19, plain, divide(c,divide(a,b)) = zero, inference(mp, [status(thm)], [lemma_13, s18])).
fof(s20, plain, less_equal(c,divide(a,b)), inference(mp, [status(thm)], [c_55, s19])).
fof(lemma_19, lemma, c = divide(a,b), inference(mp, [status(thm)], [c_59, s20, lemma_18])).
fof(s21, plain, divide(c,a) = divide(divide(a,b),a), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_20, lemma, divide(c,a) = zero, inference(rewrite, [status(thm)], [lemma_15, s21])).
fof(s22, plain, less_equal(divide(divide(b,divide(b,zero)),divide(zero,divide(b,zero))),divide(divide(b,zero),divide(b,zero))), inference(instantiate, [status(thm)], [c_57])).
fof(s23, plain, less_equal(divide(divide(b,divide(b,zero)),zero),divide(divide(b,zero),divide(b,zero))), inference(rewrite, [status(thm)], [lemma_12, s22])).
fof(s24, plain, less_equal(divide(divide(b,divide(b,zero)),zero),zero), inference(rewrite, [status(thm)], [lemma_17, s23])).
fof(s25, plain, divide(divide(b,divide(b,zero)),zero) = zero, inference(mp, [status(thm)], [lemma_13, s24])).
fof(s26, plain, less_equal(divide(b,divide(b,zero)),zero), inference(mp, [status(thm)], [c_55, s25])).
fof(s27, plain, divide(b,divide(b,zero)) = zero, inference(mp, [status(thm)], [lemma_13, s26])).
fof(s28, plain, less_equal(b,divide(b,zero)), inference(mp, [status(thm)], [c_55, s27])).
fof(s29, plain, less_equal(divide(b,zero),b), inference(instantiate, [status(thm)], [c_56])).
fof(lemma_21, lemma, b = divide(b,zero), inference(mp, [status(thm)], [c_59, s28, s29])).
fof(s30, plain, divide(divide(d,a),b) = zero, inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_22, lemma, less_equal(divide(d,a),b), inference(mp, [status(thm)], [c_55, s30])).
fof(s31, plain, less_equal(divide(divide(b,c),divide(identity,c)),divide(divide(b,identity),c)), inference(instantiate, [status(thm)], [c_57])).
fof(s32, plain, less_equal(divide(divide(b,c),d),divide(divide(b,identity),c)), inference(rewrite, [status(thm)], [c_52, s31])).
fof(s33, plain, less_equal(divide(divide(b,c),d),divide(zero,c)), inference(rewrite, [status(thm)], [lemma_11, s32])).
fof(s34, plain, less_equal(divide(divide(b,c),d),zero), inference(rewrite, [status(thm)], [lemma_12, s33])).
fof(s35, plain, divide(divide(b,c),d) = zero, inference(mp, [status(thm)], [lemma_13, s34])).
fof(lemma_23, lemma, less_equal(divide(b,c),d), inference(mp, [status(thm)], [c_55, s35])).
fof(s36, plain, less_equal(divide(divide(identity,c),divide(b,c)),divide(divide(identity,b),c)), inference(instantiate, [status(thm)], [c_57])).
fof(s37, plain, less_equal(divide(divide(identity,c),divide(b,c)),zero), inference(rewrite, [status(thm)], [lemma_16, s36])).
fof(s38, plain, less_equal(divide(d,divide(b,c)),zero), inference(rewrite, [status(thm)], [c_52, s37])).
fof(s39, plain, divide(d,divide(b,c)) = zero, inference(mp, [status(thm)], [lemma_13, s38])).
fof(s40, plain, less_equal(d,divide(b,c)), inference(mp, [status(thm)], [c_55, s39])).
fof(lemma_24, lemma, d = divide(b,c), inference(mp, [status(thm)], [c_59, s40, lemma_23])).
fof(s41, plain, less_equal(divide(divide(identity,a),divide(c,a)),divide(divide(identity,c),a)), inference(instantiate, [status(thm)], [c_57])).
fof(s42, plain, less_equal(divide(b,divide(c,a)),divide(divide(identity,c),a)), inference(rewrite, [status(thm)], [c_50, s41])).
fof(s43, plain, less_equal(divide(b,divide(c,a)),divide(d,a)), inference(rewrite, [status(thm)], [c_52, s42])).
fof(s44, plain, less_equal(divide(b,zero),divide(d,a)), inference(rewrite, [status(thm)], [lemma_20, s43])).
fof(s45, plain, less_equal(b,divide(d,a)), inference(rewrite, [status(thm)], [lemma_21, s44])).
fof(lemma_25, lemma, b = divide(d,a), inference(mp, [status(thm)], [c_59, s45, lemma_22])).
fof(s46, plain, less_equal(divide(d,a),d), inference(instantiate, [status(thm)], [c_56])).
fof(lemma_26, lemma, less_equal(b,d), inference(rewrite, [status(thm)], [lemma_25, s46])).
fof(s47, plain, less_equal(divide(b,c),b), inference(instantiate, [status(thm)], [c_56])).
fof(s48, plain, less_equal(d,b), inference(rewrite, [status(thm)], [lemma_24, s47])).
fof(goal_1, theorem, b = d, inference(mp, [status(thm)], [c_59, s48, lemma_26])).
% SZS output end Proof
