% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (~ less_equal(X0, X1) | divide(X0, X1) = zero), file('Problems/HEN/HEN009-3.p')).
fof(f2, axiom, ! [X0, X1]: (divide(X0, X1) != zero | less_equal(X0, X1)), file('Problems/HEN/HEN009-3.p')).
fof(f3, axiom, ! [X0, X1]: less_equal(divide(X0, X1), X0), file('Problems/HEN/HEN009-3.p')).
fof(f4, axiom, ! [X2, X0, X1]: less_equal(divide(divide(X0, X1), divide(X2, X1)), divide(divide(X0, X2), X1)), file('Problems/HEN/HEN009-3.p')).
fof(f5, axiom, ! [X0]: less_equal(zero, X0), file('Problems/HEN/HEN009-3.p')).
fof(f6, axiom, ! [X0, X1]: (~ less_equal(X1, X0) | ~ less_equal(X0, X1) | X0 = X1), file('Problems/HEN/HEN009-3.p')).
fof(f7, axiom, ! [X0]: less_equal(X0, identity), file('Problems/HEN/HEN009-3.p')).
fof(f9, axiom, divide(identity, a) = b, file('Problems/HEN/HEN009-3.p')).
fof(f10, axiom, divide(identity, b) = c, file('Problems/HEN/HEN009-3.p')).
fof(f11, axiom, divide(identity, c) = d, file('Problems/HEN/HEN009-3.p')).
fof(lemma_11, lemma, ! [X] : zero = divide(zero,X), inference(mp, [status(thm)], [f1, f5])).
fof(s1, plain, ! [X] : divide(X,identity) = zero, inference(mp, [status(thm)], [f1, f7])).
fof(lemma_12, lemma, ! [X] : divide(X,identity) = divide(zero,X), inference(rewrite, [status(thm)], [lemma_11, s1])).
fof(s2, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),divide(divide(X,identity),a)), inference(instantiate, [status(thm)], [f4])).
fof(s3, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),divide(divide(zero,X),a)), inference(rewrite, [status(thm)], [lemma_12, s2])).
fof(s4, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),divide(zero,a)), inference(rewrite, [status(thm)], [lemma_11, s3])).
fof(s5, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),zero), inference(rewrite, [status(thm)], [lemma_11, s4])).
fof(lemma_13, lemma, ! [X] : less_equal(divide(divide(X,a),b),zero), inference(rewrite, [status(thm)], [f9, s5])).
fof(lemma_14, lemma, ! [X] : less_equal(divide(divide(X,a),b),zero), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_15, lemma, ! [X] : zero = divide(zero,X), inference(mp, [status(thm)], [f1, f5])).
fof(s6, plain, ! [X] : divide(X,identity) = zero, inference(mp, [status(thm)], [f1, f7])).
fof(lemma_16, lemma, ! [X] : divide(X,identity) = divide(zero,X), inference(rewrite, [status(thm)], [lemma_15, s6])).
fof(s7, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),divide(divide(X,identity),b)), inference(instantiate, [status(thm)], [f4])).
fof(s8, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),divide(divide(zero,X),b)), inference(rewrite, [status(thm)], [lemma_16, s7])).
fof(s9, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),divide(zero,b)), inference(rewrite, [status(thm)], [lemma_15, s8])).
fof(s10, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),zero), inference(rewrite, [status(thm)], [lemma_15, s9])).
fof(lemma_17, lemma, ! [X] : less_equal(divide(divide(X,b),c),zero), inference(rewrite, [status(thm)], [f10, s10])).
fof(lemma_18, lemma, ! [X] : less_equal(divide(divide(X,b),c),zero), inference(instantiate, [status(thm)], [lemma_17])).
fof(lemma_19, lemma, ! [X] : zero = divide(zero,X), inference(mp, [status(thm)], [f1, f5])).
fof(lemma_20, lemma, ! [X] : zero = divide(X,identity), inference(mp, [status(thm)], [f1, f7])).
fof(s11, plain, less_equal(divide(divide(identity,a),divide(c,a)),divide(divide(identity,c),a)), inference(instantiate, [status(thm)], [f4])).
fof(s12, plain, less_equal(divide(divide(identity,a),divide(c,a)),divide(d,a)), inference(rewrite, [status(thm)], [f11, s11])).
fof(lemma_21, lemma, less_equal(divide(b,divide(c,a)),divide(d,a)), inference(rewrite, [status(thm)], [f9, s12])).
fof(s13, plain, less_equal(divide(divide(identity,a),b),zero), inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_22, lemma, less_equal(divide(b,b),zero), inference(rewrite, [status(thm)], [f9, s13])).
fof(s14, plain, less_equal(zero,divide(b,b)), inference(instantiate, [status(thm)], [f5])).
fof(lemma_23, lemma, divide(b,b) = zero, inference(mp, [status(thm)], [f6, s14, lemma_22])).
fof(s15, plain, less_equal(divide(divide(identity,b),divide(a,b)),divide(divide(identity,a),b)), inference(instantiate, [status(thm)], [f4])).
fof(s16, plain, less_equal(divide(divide(identity,b),divide(a,b)),divide(b,b)), inference(rewrite, [status(thm)], [f9, s15])).
fof(s17, plain, less_equal(divide(c,divide(a,b)),divide(b,b)), inference(rewrite, [status(thm)], [f10, s16])).
fof(lemma_24, lemma, less_equal(divide(c,divide(a,b)),zero), inference(rewrite, [status(thm)], [lemma_23, s17])).
fof(s18, plain, less_equal(zero,divide(divide(a,b),c)), inference(instantiate, [status(thm)], [f5])).
fof(s19, plain, less_equal(divide(divide(a,b),c),zero), inference(instantiate, [status(thm)], [lemma_18])).
fof(s20, plain, divide(divide(a,b),c) = zero, inference(mp, [status(thm)], [f6, s18, s19])).
fof(lemma_25, lemma, less_equal(divide(a,b),c), inference(mp, [status(thm)], [f2, s20])).
fof(s21, plain, less_equal(zero,divide(c,divide(a,b))), inference(instantiate, [status(thm)], [f5])).
fof(s22, plain, divide(c,divide(a,b)) = zero, inference(mp, [status(thm)], [f6, s21, lemma_24])).
fof(s23, plain, less_equal(c,divide(a,b)), inference(mp, [status(thm)], [f2, s22])).
fof(lemma_26, lemma, divide(a,b) = c, inference(mp, [status(thm)], [f6, s23, lemma_25])).
fof(s24, plain, less_equal(divide(a,b),a), inference(instantiate, [status(thm)], [f3])).
fof(s25, plain, divide(divide(a,b),a) = zero, inference(mp, [status(thm)], [f1, s24])).
fof(lemma_27, lemma, zero = divide(c,a), inference(rewrite, [status(thm)], [lemma_26, s25])).
fof(s26, plain, divide(divide(b,divide(c,a)),divide(d,a)) = zero, inference(mp, [status(thm)], [f1, lemma_21])).
fof(lemma_28, lemma, divide(divide(b,divide(c,a)),divide(d,a)) = divide(c,a), inference(rewrite, [status(thm)], [lemma_27, s26])).
fof(s27, plain, less_equal(zero,divide(divide(b,divide(d,a)),divide(zero,divide(d,a)))), inference(instantiate, [status(thm)], [f5])).
fof(s28, plain, less_equal(divide(c,a),divide(divide(b,divide(d,a)),divide(zero,divide(d,a)))), inference(rewrite, [status(thm)], [lemma_27, s27])).
fof(s29, plain, less_equal(divide(divide(b,divide(c,a)),divide(d,a)),divide(divide(b,divide(d,a)),divide(zero,divide(d,a)))), inference(rewrite, [status(thm)], [lemma_28, s28])).
fof(lemma_29, lemma, less_equal(divide(divide(b,zero),divide(d,a)),divide(divide(b,divide(d,a)),divide(zero,divide(d,a)))), inference(rewrite, [status(thm)], [lemma_27, s29])).
fof(s30, plain, zero = divide(divide(b,divide(c,a)),divide(d,a)), inference(rewrite, [status(thm)], [lemma_28, lemma_27])).
fof(lemma_30, lemma, zero = divide(divide(b,zero),divide(d,a)), inference(rewrite, [status(thm)], [lemma_27, s30])).
fof(s31, plain, less_equal(divide(divide(b,divide(d,a)),divide(zero,divide(d,a))),divide(divide(b,zero),divide(d,a))), inference(instantiate, [status(thm)], [f4])).
fof(s32, plain, divide(divide(b,zero),divide(d,a)) = divide(divide(b,divide(d,a)),divide(zero,divide(d,a))), inference(mp, [status(thm)], [f6, s31, lemma_29])).
fof(s33, plain, zero = divide(divide(b,divide(d,a)),divide(zero,divide(d,a))), inference(rewrite, [status(thm)], [lemma_30, s32])).
fof(s34, plain, zero = divide(divide(b,divide(d,a)),zero), inference(rewrite, [status(thm)], [lemma_19, s33])).
fof(lemma_31, lemma, less_equal(divide(b,divide(d,a)),zero), inference(mp, [status(thm)], [f2, s34])).
fof(s35, plain, less_equal(zero,divide(divide(d,a),b)), inference(instantiate, [status(thm)], [f5])).
fof(s36, plain, less_equal(divide(divide(d,a),b),zero), inference(instantiate, [status(thm)], [lemma_14])).
fof(s37, plain, divide(divide(d,a),b) = zero, inference(mp, [status(thm)], [f6, s35, s36])).
fof(lemma_32, lemma, less_equal(divide(d,a),b), inference(mp, [status(thm)], [f2, s37])).
fof(s38, plain, less_equal(zero,divide(b,divide(d,a))), inference(instantiate, [status(thm)], [f5])).
fof(s39, plain, divide(b,divide(d,a)) = zero, inference(mp, [status(thm)], [f6, s38, lemma_31])).
fof(s40, plain, less_equal(b,divide(d,a)), inference(mp, [status(thm)], [f2, s39])).
fof(lemma_33, lemma, divide(d,a) = b, inference(mp, [status(thm)], [f6, s40, lemma_32])).
fof(s41, plain, less_equal(divide(d,a),d), inference(instantiate, [status(thm)], [f3])).
fof(lemma_34, lemma, less_equal(b,d), inference(rewrite, [status(thm)], [lemma_33, s41])).
fof(s42, plain, ! [X] : less_equal(divide(divide(X,c),divide(identity,c)),divide(divide(X,identity),c)), inference(instantiate, [status(thm)], [f4])).
fof(s43, plain, ! [X] : less_equal(divide(divide(X,c),d),divide(divide(X,identity),c)), inference(rewrite, [status(thm)], [f11, s42])).
fof(s44, plain, ! [X] : less_equal(divide(divide(X,c),d),divide(zero,c)), inference(rewrite, [status(thm)], [lemma_20, s43])).
fof(lemma_35, lemma, ! [X] : less_equal(divide(divide(X,c),d),zero), inference(rewrite, [status(thm)], [lemma_19, s44])).
fof(s45, plain, less_equal(divide(divide(identity,b),c),zero), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_36, lemma, less_equal(divide(c,c),zero), inference(rewrite, [status(thm)], [f10, s45])).
fof(s46, plain, less_equal(zero,divide(c,c)), inference(instantiate, [status(thm)], [f5])).
fof(lemma_37, lemma, divide(c,c) = zero, inference(mp, [status(thm)], [f6, s46, lemma_36])).
fof(s47, plain, less_equal(divide(divide(identity,c),divide(b,c)),divide(divide(identity,b),c)), inference(instantiate, [status(thm)], [f4])).
fof(s48, plain, less_equal(divide(divide(identity,c),divide(b,c)),divide(c,c)), inference(rewrite, [status(thm)], [f10, s47])).
fof(s49, plain, less_equal(divide(d,divide(b,c)),divide(c,c)), inference(rewrite, [status(thm)], [f11, s48])).
fof(lemma_38, lemma, less_equal(divide(d,divide(b,c)),zero), inference(rewrite, [status(thm)], [lemma_37, s49])).
fof(s50, plain, less_equal(zero,divide(divide(b,c),d)), inference(instantiate, [status(thm)], [f5])).
fof(s51, plain, less_equal(divide(divide(b,c),d),zero), inference(instantiate, [status(thm)], [lemma_35])).
fof(s52, plain, divide(divide(b,c),d) = zero, inference(mp, [status(thm)], [f6, s50, s51])).
fof(lemma_39, lemma, less_equal(divide(b,c),d), inference(mp, [status(thm)], [f2, s52])).
fof(s53, plain, less_equal(zero,divide(d,divide(b,c))), inference(instantiate, [status(thm)], [f5])).
fof(s54, plain, divide(d,divide(b,c)) = zero, inference(mp, [status(thm)], [f6, s53, lemma_38])).
fof(s55, plain, less_equal(d,divide(b,c)), inference(mp, [status(thm)], [f2, s54])).
fof(lemma_40, lemma, divide(b,c) = d, inference(mp, [status(thm)], [f6, s55, lemma_39])).
fof(lemma_41, lemma, less_equal(b,divide(b,c)), inference(rewrite, [status(thm)], [lemma_40, lemma_34])).
fof(s56, plain, less_equal(divide(b,c),b), inference(instantiate, [status(thm)], [f3])).
fof(lemma_42, lemma, b = divide(b,c), inference(mp, [status(thm)], [f6, s56, lemma_41])).
fof(s57, plain, less_equal(zero,divide(d,divide(b,c))), inference(instantiate, [status(thm)], [f5])).
fof(s58, plain, divide(d,divide(b,c)) = zero, inference(mp, [status(thm)], [f6, s57, lemma_38])).
fof(s59, plain, less_equal(d,divide(b,c)), inference(mp, [status(thm)], [f2, s58])).
fof(s60, plain, less_equal(d,b), inference(rewrite, [status(thm)], [lemma_42, s59])).
fof(goal_1, theorem, b = d, inference(mp, [status(thm)], [f6, s60, lemma_34])).
% SZS output end Proof
