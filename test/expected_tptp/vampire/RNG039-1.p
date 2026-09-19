% SZS output start Proof
fof(f3, axiom, ! [X0, X1]: product(X0, X1, multiply(X0, X1)), file('Problems/RNG/RNG039-1.p')).
fof(f17, axiom, ! [X2, X3, X0, X1]: (~ product(X0, X1, X3) | ~ product(X0, X1, X2) | X2 = X3), file('Problems/RNG/RNG039-1.p')).
fof(f21, axiom, ! [X0]: add(X0, additive_identity) = X0, file('Problems/RNG/RNG039-1.p')).
fof(f22, axiom, ! [X0]: add(X0, X0) = additive_identity, file('Problems/RNG/RNG039-1.p')).
fof(f24, axiom, ! [X0]: multiply(X0, X0) = X0, file('Problems/RNG/RNG039-1.p')).
fof(f26, axiom, multiply(b, a) = d, file('Problems/RNG/RNG039-1.p')).
fof(f33, axiom, ! [X0, X1]: product(a, multiply(b, X0), multiply(X1, X0)), file('Problems/RNG/RNG039-1.p')).
fof(f46, axiom, ! [X0]: product(multiply(X0, b), a, multiply(X0, d)), file('Problems/RNG/RNG039-1.p')).
fof(f54, axiom, product(add(a, b), b, add(c, b)), file('Problems/RNG/RNG039-1.p')).
fof(f57, axiom, product(add(a, b), a, add(a, d)), file('Problems/RNG/RNG039-1.p')).
fof(f59, negated_conjecture, product(a, b, c), file('Problems/RNG/RNG039-1.p')).
fof(f60, negated_conjecture, product(b, a, d), file('Problems/RNG/RNG039-1.p')).
fof(s1, plain, product(a,multiply(b,b),multiply(b,b)), inference(instantiate, [status(thm)], [f33])).
fof(s2, plain, product(a,multiply(b,b),b), inference(rewrite, [status(thm)], [f24, s1])).
fof(lemma_13, lemma, product(a,b,b), inference(rewrite, [status(thm)], [f24, s2])).
fof(lemma_14, lemma, b = c, inference(mp, [status(thm)], [f17, f59, lemma_13])).
fof(s3, plain, product(a,multiply(b,c),multiply(add(a,b),c)), inference(instantiate, [status(thm)], [f33])).
fof(s4, plain, product(a,multiply(c,c),multiply(add(a,b),c)), inference(rewrite, [status(thm)], [lemma_14, s3])).
fof(s5, plain, product(a,multiply(c,c),multiply(add(a,b),b)), inference(rewrite, [status(thm)], [lemma_14, s4])).
fof(s6, plain, product(a,c,multiply(add(a,b),b)), inference(rewrite, [status(thm)], [f24, s5])).
fof(s7, plain, product(a,c,multiply(add(a,b),c)), inference(rewrite, [status(thm)], [lemma_14, s6])).
fof(s8, plain, product(a,c,multiply(add(a,c),c)), inference(rewrite, [status(thm)], [lemma_14, s7])).
fof(s9, plain, product(a,b,multiply(add(a,c),c)), inference(rewrite, [status(thm)], [lemma_14, s8])).
fof(s10, plain, product(a,b,multiply(add(a,b),c)), inference(rewrite, [status(thm)], [lemma_14, s9])).
fof(lemma_15, lemma, product(a,b,multiply(add(a,b),b)), inference(rewrite, [status(thm)], [lemma_14, s10])).
fof(lemma_16, lemma, multiply(add(a,b),b) = b, inference(mp, [status(thm)], [f17, lemma_13, lemma_15])).
fof(s11, plain, product(add(a,b),c,multiply(add(a,b),c)), inference(instantiate, [status(thm)], [f3])).
fof(s12, plain, product(add(a,b),c,multiply(add(a,b),b)), inference(rewrite, [status(thm)], [lemma_14, s11])).
fof(s13, plain, product(add(a,b),c,b), inference(rewrite, [status(thm)], [lemma_16, s12])).
fof(s14, plain, product(add(a,b),c,c), inference(rewrite, [status(thm)], [lemma_14, s13])).
fof(s15, plain, product(add(a,b),b,c), inference(rewrite, [status(thm)], [lemma_14, s14])).
fof(lemma_17, lemma, product(add(a,b),b,b), inference(rewrite, [status(thm)], [lemma_14, s15])).
fof(lemma_18, lemma, add(c,b) = b, inference(mp, [status(thm)], [f17, lemma_17, f54])).
fof(s16, plain, additive_identity = add(c,c), inference(instantiate, [status(thm)], [f22])).
fof(s17, plain, additive_identity = add(c,b), inference(rewrite, [status(thm)], [lemma_14, s16])).
fof(lemma_19, lemma, additive_identity = b, inference(rewrite, [status(thm)], [lemma_18, s17])).
fof(s18, plain, product(a,multiply(b,a),multiply(b,a)), inference(instantiate, [status(thm)], [f33])).
fof(s19, plain, product(a,multiply(b,a),d), inference(rewrite, [status(thm)], [f26, s18])).
fof(lemma_20, lemma, product(a,d,d), inference(rewrite, [status(thm)], [f26, s19])).
fof(s20, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [f33])).
fof(s21, plain, product(multiply(a,a),multiply(b,a),multiply(a,a)), inference(rewrite, [status(thm)], [f24, s20])).
fof(s22, plain, product(multiply(a,a),multiply(b,a),a), inference(rewrite, [status(thm)], [f24, s21])).
fof(s23, plain, product(multiply(a,a),d,a), inference(rewrite, [status(thm)], [f26, s22])).
fof(s24, plain, product(multiply(a,a),d,multiply(a,a)), inference(rewrite, [status(thm)], [f24, s23])).
fof(s25, plain, product(multiply(a,a),d,multiply(multiply(a,a),multiply(a,a))), inference(rewrite, [status(thm)], [f24, s24])).
fof(s26, plain, product(a,d,multiply(multiply(a,a),multiply(a,a))), inference(rewrite, [status(thm)], [f24, s25])).
fof(s27, plain, product(a,d,multiply(a,multiply(a,a))), inference(rewrite, [status(thm)], [f24, s26])).
fof(lemma_21, lemma, product(a,d,multiply(a,a)), inference(rewrite, [status(thm)], [f24, s27])).
fof(s28, plain, product(a,d,multiply(a,d)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_22, lemma, multiply(a,a) = multiply(a,d), inference(mp, [status(thm)], [f17, s28, lemma_21])).
fof(s29, plain, product(a,d,multiply(a,d)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_23, lemma, multiply(a,d) = d, inference(mp, [status(thm)], [f17, lemma_20, s29])).
fof(s30, plain, a = multiply(a,a), inference(instantiate, [status(thm)], [f24])).
fof(s31, plain, a = multiply(a,d), inference(rewrite, [status(thm)], [lemma_22, s30])).
fof(lemma_24, lemma, a = d, inference(rewrite, [status(thm)], [lemma_23, s31])).
fof(s32, plain, product(a,multiply(b,multiply(b,b)),multiply(multiply(b,b),multiply(b,b))), inference(instantiate, [status(thm)], [f33])).
fof(s33, plain, product(a,multiply(multiply(b,b),multiply(b,b)),multiply(multiply(b,b),multiply(b,b))), inference(rewrite, [status(thm)], [f24, s32])).
fof(s34, plain, product(a,multiply(multiply(b,b),multiply(b,b)),multiply(b,b)), inference(rewrite, [status(thm)], [f24, s33])).
fof(s35, plain, product(a,multiply(b,b),multiply(b,b)), inference(rewrite, [status(thm)], [f24, s34])).
fof(s36, plain, product(a,multiply(b,b),multiply(multiply(b,b),multiply(b,b))), inference(rewrite, [status(thm)], [f24, s35])).
fof(s37, plain, product(a,b,multiply(multiply(b,b),multiply(b,b))), inference(rewrite, [status(thm)], [f24, s36])).
fof(s38, plain, product(a,b,multiply(b,multiply(b,b))), inference(rewrite, [status(thm)], [f24, s37])).
fof(lemma_25, lemma, product(a,b,multiply(b,b)), inference(rewrite, [status(thm)], [f24, s38])).
fof(s39, plain, multiply(b,b) = c, inference(mp, [status(thm)], [f17, f59, lemma_25])).
fof(lemma_26, lemma, b = c, inference(rewrite, [status(thm)], [f24, s39])).
fof(s40, plain, product(add(d,b),a,add(a,d)), inference(rewrite, [status(thm)], [lemma_24, f57])).
fof(s41, plain, product(add(d,b),d,add(a,d)), inference(rewrite, [status(thm)], [lemma_24, s40])).
fof(s42, plain, product(add(d,b),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_24, s41])).
fof(s43, plain, product(add(d,additive_identity),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_19, s42])).
fof(s44, plain, product(d,d,add(d,d)), inference(rewrite, [status(thm)], [f21, s43])).
fof(s45, plain, product(d,d,additive_identity), inference(rewrite, [status(thm)], [f22, s44])).
fof(s46, plain, product(d,d,b), inference(rewrite, [status(thm)], [lemma_19, s45])).
fof(lemma_27, lemma, product(a,d,b), inference(rewrite, [status(thm)], [lemma_24, s46])).
fof(s47, plain, product(a,multiply(b,d),multiply(additive_identity,d)), inference(instantiate, [status(thm)], [f33])).
fof(s48, plain, product(d,multiply(b,d),multiply(additive_identity,d)), inference(rewrite, [status(thm)], [lemma_24, s47])).
fof(s49, plain, product(d,multiply(additive_identity,d),multiply(additive_identity,d)), inference(rewrite, [status(thm)], [lemma_19, s48])).
fof(s50, plain, product(d,multiply(additive_identity,d),multiply(additive_identity,a)), inference(rewrite, [status(thm)], [lemma_24, s49])).
fof(s51, plain, product(d,multiply(additive_identity,d),multiply(b,a)), inference(rewrite, [status(thm)], [lemma_19, s50])).
fof(s52, plain, product(d,multiply(additive_identity,d),d), inference(rewrite, [status(thm)], [f26, s51])).
fof(s53, plain, product(d,multiply(additive_identity,a),d), inference(rewrite, [status(thm)], [lemma_24, s52])).
fof(s54, plain, product(d,multiply(b,a),d), inference(rewrite, [status(thm)], [lemma_19, s53])).
fof(s55, plain, product(d,d,d), inference(rewrite, [status(thm)], [f26, s54])).
fof(lemma_28, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_24, s55])).
fof(s56, plain, b = d, inference(mp, [status(thm)], [f17, lemma_28, lemma_27])).
fof(lemma_29, lemma, b = a, inference(rewrite, [status(thm)], [lemma_24, s56])).
fof(s57, plain, c = b, inference(instantiate, [status(thm)], [lemma_26])).
fof(s58, plain, c = a, inference(rewrite, [status(thm)], [lemma_29, s57])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_24, s58])).
% SZS output end Proof
