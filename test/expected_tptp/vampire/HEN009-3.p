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
fof(lemma_11, lemma, ! [X] : zero = divide(X,identity), inference(mp, [status(thm)], [f1, f7])).
fof(lemma_12, lemma, ! [X] : zero = divide(zero,X), inference(mp, [status(thm)], [f1, f5])).
fof(s1, plain, ! [X] : less_equal(divide(divide(X,a),divide(identity,a)),divide(divide(X,identity),a)), inference(instantiate, [status(thm)], [f4])).
fof(s2, plain, ! [X] : less_equal(divide(divide(X,a),b),divide(divide(X,identity),a)), inference(rewrite, [status(thm)], [f9, s1])).
fof(s3, plain, ! [X] : less_equal(divide(divide(X,a),b),divide(zero,a)), inference(rewrite, [status(thm)], [lemma_11, s2])).
fof(lemma_13, lemma, ! [X] : less_equal(divide(divide(X,a),b),zero), inference(rewrite, [status(thm)], [lemma_12, s3])).
fof(s4, plain, ! [X] : less_equal(divide(divide(X,b),divide(identity,b)),divide(divide(X,identity),b)), inference(instantiate, [status(thm)], [f4])).
fof(s5, plain, ! [X] : less_equal(divide(divide(X,b),c),divide(divide(X,identity),b)), inference(rewrite, [status(thm)], [f10, s4])).
fof(s6, plain, ! [X] : less_equal(divide(divide(X,b),c),divide(zero,b)), inference(rewrite, [status(thm)], [lemma_11, s5])).
fof(lemma_14, lemma, ! [X] : less_equal(divide(divide(X,b),c),zero), inference(rewrite, [status(thm)], [lemma_12, s6])).
fof(s7, plain, less_equal(divide(divide(identity,a),b),zero), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_15, lemma, less_equal(divide(b,b),zero), inference(rewrite, [status(thm)], [f9, s7])).
fof(s8, plain, less_equal(zero,divide(b,b)), inference(instantiate, [status(thm)], [f5])).
fof(lemma_16, lemma, divide(b,b) = zero, inference(mp, [status(thm)], [f6, s8, lemma_15])).
fof(s9, plain, less_equal(divide(divide(identity,b),divide(a,b)),divide(divide(identity,a),b)), inference(instantiate, [status(thm)], [f4])).
fof(s10, plain, less_equal(divide(c,divide(a,b)),divide(divide(identity,a),b)), inference(rewrite, [status(thm)], [f10, s9])).
fof(s11, plain, less_equal(divide(c,divide(a,b)),divide(b,b)), inference(rewrite, [status(thm)], [f9, s10])).
fof(lemma_17, lemma, less_equal(divide(c,divide(a,b)),zero), inference(rewrite, [status(thm)], [lemma_16, s11])).
fof(s12, plain, less_equal(zero,divide(divide(a,b),c)), inference(instantiate, [status(thm)], [f5])).
fof(s13, plain, less_equal(divide(divide(a,b),c),zero), inference(instantiate, [status(thm)], [lemma_14])).
fof(s14, plain, divide(divide(a,b),c) = zero, inference(mp, [status(thm)], [f6, s12, s13])).
fof(lemma_18, lemma, less_equal(divide(a,b),c), inference(mp, [status(thm)], [f2, s14])).
fof(s15, plain, less_equal(divide(a,b),a), inference(instantiate, [status(thm)], [f3])).
fof(lemma_19, lemma, divide(divide(a,b),a) = zero, inference(mp, [status(thm)], [f1, s15])).
fof(s16, plain, less_equal(zero,divide(c,divide(a,b))), inference(instantiate, [status(thm)], [f5])).
fof(s17, plain, divide(c,divide(a,b)) = zero, inference(mp, [status(thm)], [f6, s16, lemma_17])).
fof(s18, plain, less_equal(c,divide(a,b)), inference(mp, [status(thm)], [f2, s17])).
fof(lemma_20, lemma, divide(a,b) = c, inference(mp, [status(thm)], [f6, s18, lemma_18])).
fof(s19, plain, zero = divide(divide(a,b),a), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_21, lemma, zero = divide(c,a), inference(rewrite, [status(thm)], [lemma_20, s19])).
fof(s20, plain, less_equal(divide(divide(identity,a),divide(c,a)),divide(divide(identity,c),a)), inference(instantiate, [status(thm)], [f4])).
fof(s21, plain, less_equal(divide(b,divide(c,a)),divide(divide(identity,c),a)), inference(rewrite, [status(thm)], [f9, s20])).
fof(s22, plain, less_equal(divide(b,divide(c,a)),divide(d,a)), inference(rewrite, [status(thm)], [f11, s21])).
fof(lemma_22, lemma, divide(divide(b,divide(c,a)),divide(d,a)) = zero, inference(mp, [status(thm)], [f1, s22])).
fof(s23, plain, less_equal(zero,divide(divide(b,divide(d,a)),zero)), inference(instantiate, [status(thm)], [f5])).
fof(s24, plain, less_equal(divide(divide(b,divide(c,a)),divide(d,a)),divide(divide(b,divide(d,a)),zero)), inference(rewrite, [status(thm)], [lemma_22, s23])).
fof(s25, plain, less_equal(divide(divide(b,zero),divide(d,a)),divide(divide(b,divide(d,a)),zero)), inference(rewrite, [status(thm)], [lemma_21, s24])).
fof(lemma_23, lemma, less_equal(divide(divide(b,zero),divide(d,a)),divide(divide(b,divide(d,a)),divide(zero,divide(d,a)))), inference(rewrite, [status(thm)], [lemma_12, s25])).
fof(s26, plain, less_equal(divide(divide(b,divide(d,a)),divide(zero,divide(d,a))),divide(divide(b,zero),divide(d,a))), inference(instantiate, [status(thm)], [f4])).
fof(s27, plain, divide(divide(b,zero),divide(d,a)) = divide(divide(b,divide(d,a)),divide(zero,divide(d,a))), inference(mp, [status(thm)], [f6, s26, lemma_23])).
fof(s28, plain, divide(divide(b,zero),divide(d,a)) = divide(divide(b,divide(d,a)),zero), inference(rewrite, [status(thm)], [lemma_12, s27])).
fof(s29, plain, divide(divide(b,divide(c,a)),divide(d,a)) = divide(divide(b,divide(d,a)),zero), inference(rewrite, [status(thm)], [lemma_21, s28])).
fof(s30, plain, zero = divide(divide(b,divide(d,a)),zero), inference(rewrite, [status(thm)], [lemma_22, s29])).
fof(lemma_24, lemma, less_equal(divide(b,divide(d,a)),zero), inference(mp, [status(thm)], [f2, s30])).
fof(s31, plain, less_equal(zero,divide(divide(d,a),b)), inference(instantiate, [status(thm)], [f5])).
fof(s32, plain, less_equal(divide(divide(d,a),b),zero), inference(instantiate, [status(thm)], [lemma_13])).
fof(s33, plain, divide(divide(d,a),b) = zero, inference(mp, [status(thm)], [f6, s31, s32])).
fof(lemma_25, lemma, less_equal(divide(d,a),b), inference(mp, [status(thm)], [f2, s33])).
fof(s34, plain, less_equal(divide(divide(b,c),divide(identity,c)),divide(divide(b,identity),c)), inference(instantiate, [status(thm)], [f4])).
fof(s35, plain, less_equal(divide(divide(b,c),d),divide(divide(b,identity),c)), inference(rewrite, [status(thm)], [f11, s34])).
fof(s36, plain, less_equal(divide(divide(b,c),d),divide(zero,c)), inference(rewrite, [status(thm)], [lemma_11, s35])).
fof(lemma_26, lemma, less_equal(divide(divide(b,c),d),zero), inference(rewrite, [status(thm)], [lemma_12, s36])).
fof(s37, plain, less_equal(divide(divide(identity,b),c),zero), inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_27, lemma, less_equal(divide(c,c),zero), inference(rewrite, [status(thm)], [f10, s37])).
fof(s38, plain, less_equal(zero,divide(c,c)), inference(instantiate, [status(thm)], [f5])).
fof(lemma_28, lemma, divide(c,c) = zero, inference(mp, [status(thm)], [f6, s38, lemma_27])).
fof(s39, plain, less_equal(divide(divide(identity,c),divide(b,c)),divide(divide(identity,b),c)), inference(instantiate, [status(thm)], [f4])).
fof(s40, plain, less_equal(divide(d,divide(b,c)),divide(divide(identity,b),c)), inference(rewrite, [status(thm)], [f11, s39])).
fof(s41, plain, less_equal(divide(d,divide(b,c)),divide(c,c)), inference(rewrite, [status(thm)], [f10, s40])).
fof(lemma_29, lemma, less_equal(divide(d,divide(b,c)),zero), inference(rewrite, [status(thm)], [lemma_28, s41])).
fof(s42, plain, less_equal(zero,divide(divide(b,c),d)), inference(instantiate, [status(thm)], [f5])).
fof(s43, plain, divide(divide(b,c),d) = zero, inference(mp, [status(thm)], [f6, s42, lemma_26])).
fof(lemma_30, lemma, less_equal(divide(b,c),d), inference(mp, [status(thm)], [f2, s43])).
fof(s44, plain, less_equal(zero,divide(b,divide(d,a))), inference(instantiate, [status(thm)], [f5])).
fof(s45, plain, divide(b,divide(d,a)) = zero, inference(mp, [status(thm)], [f6, s44, lemma_24])).
fof(s46, plain, less_equal(b,divide(d,a)), inference(mp, [status(thm)], [f2, s45])).
fof(lemma_31, lemma, divide(d,a) = b, inference(mp, [status(thm)], [f6, s46, lemma_25])).
fof(s47, plain, less_equal(zero,divide(d,divide(b,c))), inference(instantiate, [status(thm)], [f5])).
fof(s48, plain, divide(d,divide(b,c)) = zero, inference(mp, [status(thm)], [f6, s47, lemma_29])).
fof(s49, plain, less_equal(d,divide(b,c)), inference(mp, [status(thm)], [f2, s48])).
fof(lemma_32, lemma, divide(b,c) = d, inference(mp, [status(thm)], [f6, s49, lemma_30])).
fof(s50, plain, less_equal(divide(d,a),d), inference(instantiate, [status(thm)], [f3])).
fof(s51, plain, less_equal(b,d), inference(rewrite, [status(thm)], [lemma_31, s50])).
fof(lemma_33, lemma, less_equal(b,divide(b,c)), inference(rewrite, [status(thm)], [lemma_32, s51])).
fof(s52, plain, less_equal(divide(b,c),b), inference(instantiate, [status(thm)], [f3])).
fof(s53, plain, b = divide(b,c), inference(mp, [status(thm)], [f6, s52, lemma_33])).
fof(goal_1, theorem, b = d, inference(rewrite, [status(thm)], [lemma_32, s53])).
% SZS output end Proof
