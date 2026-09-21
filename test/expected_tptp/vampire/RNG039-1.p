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
fof(lemma_16, lemma, multiply(add(a,b),b) = c, inference(mp, [status(thm)], [f17, f59, lemma_15])).
fof(s11, plain, product(add(a,b),c,multiply(add(a,b),c)), inference(instantiate, [status(thm)], [f3])).
fof(s12, plain, product(add(a,b),c,multiply(add(a,b),b)), inference(rewrite, [status(thm)], [lemma_14, s11])).
fof(s13, plain, product(add(a,b),c,c), inference(rewrite, [status(thm)], [lemma_16, s12])).
fof(s14, plain, product(add(a,b),b,c), inference(rewrite, [status(thm)], [lemma_14, s13])).
fof(lemma_17, lemma, product(add(a,b),b,b), inference(rewrite, [status(thm)], [lemma_14, s14])).
fof(s15, plain, product(add(a,c),b,add(c,b)), inference(rewrite, [status(thm)], [lemma_14, f54])).
fof(s16, plain, product(add(a,c),c,add(c,b)), inference(rewrite, [status(thm)], [lemma_14, s15])).
fof(s17, plain, product(add(a,c),c,add(c,c)), inference(rewrite, [status(thm)], [lemma_14, s16])).
fof(s18, plain, product(add(a,b),c,add(c,c)), inference(rewrite, [status(thm)], [lemma_14, s17])).
fof(s19, plain, product(add(a,b),c,additive_identity), inference(rewrite, [status(thm)], [f22, s18])).
fof(lemma_18, lemma, product(add(a,b),b,additive_identity), inference(rewrite, [status(thm)], [lemma_14, s19])).
fof(lemma_19, lemma, additive_identity = b, inference(mp, [status(thm)], [f17, lemma_17, lemma_18])).
fof(s20, plain, product(a,multiply(b,b),multiply(b,b)), inference(instantiate, [status(thm)], [f33])).
fof(s21, plain, product(a,multiply(b,b),b), inference(rewrite, [status(thm)], [f24, s20])).
fof(lemma_20, lemma, product(a,b,b), inference(rewrite, [status(thm)], [f24, s21])).
fof(lemma_21, lemma, b = c, inference(mp, [status(thm)], [f17, f59, lemma_20])).
fof(s22, plain, product(a,b,multiply(a,b)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_22, lemma, multiply(a,b) = c, inference(mp, [status(thm)], [f17, f59, s22])).
fof(s23, plain, product(multiply(a,b),a,multiply(a,d)), inference(instantiate, [status(thm)], [f46])).
fof(s24, plain, product(c,a,multiply(a,d)), inference(rewrite, [status(thm)], [lemma_22, s23])).
fof(lemma_23, lemma, product(b,a,multiply(a,d)), inference(rewrite, [status(thm)], [lemma_21, s24])).
fof(lemma_24, lemma, multiply(a,d) = d, inference(mp, [status(thm)], [f17, f60, lemma_23])).
fof(s25, plain, product(a,d,multiply(a,d)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_25, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_24, s25])).
fof(s26, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [f33])).
fof(s27, plain, product(a,multiply(c,a),multiply(a,a)), inference(rewrite, [status(thm)], [lemma_21, s26])).
fof(s28, plain, product(a,multiply(c,a),a), inference(rewrite, [status(thm)], [f24, s27])).
fof(s29, plain, product(a,multiply(b,a),a), inference(rewrite, [status(thm)], [lemma_21, s28])).
fof(lemma_26, lemma, product(a,d,a), inference(rewrite, [status(thm)], [f26, s29])).
fof(lemma_27, lemma, a = d, inference(mp, [status(thm)], [f17, lemma_25, lemma_26])).
fof(s30, plain, product(a,multiply(b,b),multiply(b,b)), inference(instantiate, [status(thm)], [f33])).
fof(s31, plain, product(a,multiply(b,b),b), inference(rewrite, [status(thm)], [f24, s30])).
fof(lemma_28, lemma, product(a,b,b), inference(rewrite, [status(thm)], [f24, s31])).
fof(lemma_29, lemma, b = c, inference(mp, [status(thm)], [f17, f59, lemma_28])).
fof(s32, plain, product(a,multiply(b,d),multiply(additive_identity,d)), inference(instantiate, [status(thm)], [f33])).
fof(s33, plain, product(d,multiply(b,d),multiply(additive_identity,d)), inference(rewrite, [status(thm)], [lemma_27, s32])).
fof(s34, plain, product(d,multiply(additive_identity,d),multiply(additive_identity,d)), inference(rewrite, [status(thm)], [lemma_19, s33])).
fof(s35, plain, product(d,multiply(additive_identity,d),multiply(additive_identity,a)), inference(rewrite, [status(thm)], [lemma_27, s34])).
fof(s36, plain, product(d,multiply(additive_identity,d),multiply(b,a)), inference(rewrite, [status(thm)], [lemma_19, s35])).
fof(s37, plain, product(d,multiply(additive_identity,d),d), inference(rewrite, [status(thm)], [f26, s36])).
fof(s38, plain, product(d,multiply(additive_identity,a),d), inference(rewrite, [status(thm)], [lemma_27, s37])).
fof(s39, plain, product(d,multiply(b,a),d), inference(rewrite, [status(thm)], [lemma_19, s38])).
fof(s40, plain, product(d,d,d), inference(rewrite, [status(thm)], [f26, s39])).
fof(lemma_30, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_27, s40])).
fof(s41, plain, product(add(d,b),a,add(a,d)), inference(rewrite, [status(thm)], [lemma_27, f57])).
fof(s42, plain, product(add(d,b),d,add(a,d)), inference(rewrite, [status(thm)], [lemma_27, s41])).
fof(s43, plain, product(add(d,b),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_27, s42])).
fof(s44, plain, product(add(d,additive_identity),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_19, s43])).
fof(s45, plain, product(d,d,add(d,d)), inference(rewrite, [status(thm)], [f21, s44])).
fof(s46, plain, product(d,d,additive_identity), inference(rewrite, [status(thm)], [f22, s45])).
fof(s47, plain, product(d,d,b), inference(rewrite, [status(thm)], [lemma_19, s46])).
fof(lemma_31, lemma, product(a,d,b), inference(rewrite, [status(thm)], [lemma_27, s47])).
fof(s48, plain, b = d, inference(mp, [status(thm)], [f17, lemma_30, lemma_31])).
fof(lemma_32, lemma, b = a, inference(rewrite, [status(thm)], [lemma_27, s48])).
fof(s49, plain, c = b, inference(instantiate, [status(thm)], [lemma_29])).
fof(s50, plain, c = a, inference(rewrite, [status(thm)], [lemma_32, s49])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_27, s50])).
% SZS output end Proof
