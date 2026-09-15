% SZS output start Proof
fof(f22, axiom, ! [X0]: add(X0, X0) = additive_identity, file('Problems/RNG/RNG039-1.p', unknown)).
fof(f24, axiom, ! [X0]: multiply(X0, X0) = X0, file('Problems/RNG/RNG039-1.p', unknown)).
fof(f33, axiom, ! [X0, X1]: product(a, multiply(b, X0), multiply(X1, X0)), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f59, negated_conjecture, product(a, b, c), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f17, axiom, ! [X2, X3, X0, X1]: (~ product(X0, X1, X3) | ~ product(X0, X1, X2) | X2 = X3), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f54, axiom, product(add(a, b), b, add(c, b)), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f3, axiom, ! [X0, X1]: product(X0, X1, multiply(X0, X1)), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f26, axiom, multiply(b, a) = d, file('Problems/RNG/RNG039-1.p', unknown)).
fof(f46, axiom, ! [X0]: product(multiply(X0, b), a, multiply(X0, d)), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f60, negated_conjecture, product(b, a, d), file('Problems/RNG/RNG039-1.p', unknown)).
fof(f21, axiom, ! [X0]: add(X0, additive_identity) = X0, file('Problems/RNG/RNG039-1.p', unknown)).
fof(f57, axiom, product(add(a, b), a, add(a, d)), file('Problems/RNG/RNG039-1.p', unknown)).
fof(s1, plain, ! [X] : product(a,multiply(b,b),multiply(X,b)), inference(instantiate, [status(thm)], [f33])).
fof(lemma_13, lemma, ! [X] : product(a,b,multiply(X,b)), inference(rewrite, [status(thm)], [f24, s1])).
fof(s2, plain, product(a,multiply(b,b),multiply(b,b)), inference(instantiate, [status(thm)], [f33])).
fof(s3, plain, ! [X] : product(a,multiply(b,b),multiply(X,b)), inference(instantiate, [status(thm)], [f33])).
fof(s4, plain, ! [X] : multiply(X,b) = multiply(b,b), inference(mp, [status(thm)], [f17, s2, s3])).
fof(lemma_14, lemma, ! [X] : b = multiply(X,b), inference(rewrite, [status(thm)], [f24, s4])).
fof(s5, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [f33])).
fof(s6, plain, product(multiply(a,a),multiply(b,a),multiply(a,a)), inference(rewrite, [status(thm)], [f24, s5])).
fof(s7, plain, product(multiply(a,a),multiply(b,a),a), inference(rewrite, [status(thm)], [f24, s6])).
fof(s8, plain, product(multiply(a,a),d,a), inference(rewrite, [status(thm)], [f26, s7])).
fof(s9, plain, product(multiply(a,a),d,multiply(a,a)), inference(rewrite, [status(thm)], [f24, s8])).
fof(s10, plain, product(multiply(a,a),d,multiply(multiply(a,a),multiply(a,a))), inference(rewrite, [status(thm)], [f24, s9])).
fof(s11, plain, product(a,d,multiply(multiply(a,a),multiply(a,a))), inference(rewrite, [status(thm)], [f24, s10])).
fof(s12, plain, product(a,d,multiply(a,multiply(a,a))), inference(rewrite, [status(thm)], [f24, s11])).
fof(lemma_15, lemma, product(a,d,multiply(a,a)), inference(rewrite, [status(thm)], [f24, s12])).
fof(s13, plain, product(a,multiply(b,a),multiply(b,a)), inference(instantiate, [status(thm)], [f33])).
fof(s14, plain, product(a,multiply(b,a),d), inference(rewrite, [status(thm)], [f26, s13])).
fof(lemma_16, lemma, product(a,d,d), inference(rewrite, [status(thm)], [f26, s14])).
fof(s15, plain, d = multiply(a,a), inference(mp, [status(thm)], [f17, lemma_15, lemma_16])).
fof(lemma_17, lemma, a = d, inference(rewrite, [status(thm)], [f24, s15])).
fof(lemma_18, lemma, product(a,b,b), inference(rewrite, [status(thm)], [lemma_14, lemma_13])).
fof(lemma_19, lemma, b = c, inference(mp, [status(thm)], [f17, f59, lemma_18])).
fof(s16, plain, product(add(a,b),c,multiply(add(a,b),c)), inference(instantiate, [status(thm)], [f3])).
fof(s17, plain, product(add(a,b),c,multiply(add(a,b),b)), inference(rewrite, [status(thm)], [lemma_19, s16])).
fof(s18, plain, product(add(a,b),c,b), inference(rewrite, [status(thm)], [lemma_14, s17])).
fof(s19, plain, product(add(a,b),c,c), inference(rewrite, [status(thm)], [lemma_19, s18])).
fof(s20, plain, product(add(d,b),c,c), inference(rewrite, [status(thm)], [lemma_17, s19])).
fof(s21, plain, product(add(d,b),b,c), inference(rewrite, [status(thm)], [lemma_19, s20])).
fof(s22, plain, product(add(d,b),b,b), inference(rewrite, [status(thm)], [lemma_19, s21])).
fof(lemma_20, lemma, product(add(a,b),b,b), inference(rewrite, [status(thm)], [lemma_17, s22])).
fof(s23, plain, product(add(d,b),b,add(c,b)), inference(rewrite, [status(thm)], [lemma_17, f54])).
fof(s24, plain, product(add(d,c),b,add(c,b)), inference(rewrite, [status(thm)], [lemma_19, s23])).
fof(s25, plain, product(add(d,c),c,add(c,b)), inference(rewrite, [status(thm)], [lemma_19, s24])).
fof(s26, plain, product(add(d,c),c,add(c,c)), inference(rewrite, [status(thm)], [lemma_19, s25])).
fof(s27, plain, product(add(d,b),c,add(c,c)), inference(rewrite, [status(thm)], [lemma_19, s26])).
fof(s28, plain, product(add(a,b),c,add(c,c)), inference(rewrite, [status(thm)], [lemma_17, s27])).
fof(s29, plain, product(add(a,b),c,additive_identity), inference(rewrite, [status(thm)], [f22, s28])).
fof(s30, plain, product(add(d,b),c,additive_identity), inference(rewrite, [status(thm)], [lemma_17, s29])).
fof(s31, plain, product(add(d,b),b,additive_identity), inference(rewrite, [status(thm)], [lemma_19, s30])).
fof(lemma_21, lemma, product(add(a,b),b,additive_identity), inference(rewrite, [status(thm)], [lemma_17, s31])).
fof(lemma_22, lemma, additive_identity = b, inference(mp, [status(thm)], [f17, lemma_20, lemma_21])).
fof(s32, plain, product(add(d,b),a,add(a,d)), inference(rewrite, [status(thm)], [lemma_17, f57])).
fof(s33, plain, product(add(d,b),d,add(a,d)), inference(rewrite, [status(thm)], [lemma_17, s32])).
fof(s34, plain, product(add(d,b),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_17, s33])).
fof(s35, plain, product(add(d,additive_identity),d,add(d,d)), inference(rewrite, [status(thm)], [lemma_22, s34])).
fof(s36, plain, product(d,d,add(d,d)), inference(rewrite, [status(thm)], [f21, s35])).
fof(s37, plain, product(d,d,additive_identity), inference(rewrite, [status(thm)], [f22, s36])).
fof(s38, plain, product(d,d,b), inference(rewrite, [status(thm)], [lemma_22, s37])).
fof(lemma_23, lemma, product(a,d,b), inference(rewrite, [status(thm)], [lemma_17, s38])).
fof(s39, plain, product(a,multiply(b,d),multiply(c,d)), inference(instantiate, [status(thm)], [f33])).
fof(s40, plain, product(d,multiply(b,d),multiply(c,d)), inference(rewrite, [status(thm)], [lemma_17, s39])).
fof(s41, plain, product(d,multiply(c,d),multiply(c,d)), inference(rewrite, [status(thm)], [lemma_19, s40])).
fof(s42, plain, product(d,multiply(c,d),multiply(c,a)), inference(rewrite, [status(thm)], [lemma_17, s41])).
fof(s43, plain, product(d,multiply(c,d),multiply(b,a)), inference(rewrite, [status(thm)], [lemma_19, s42])).
fof(s44, plain, product(d,multiply(c,d),d), inference(rewrite, [status(thm)], [f26, s43])).
fof(s45, plain, product(d,multiply(c,a),d), inference(rewrite, [status(thm)], [lemma_17, s44])).
fof(s46, plain, product(d,multiply(b,a),d), inference(rewrite, [status(thm)], [lemma_19, s45])).
fof(s47, plain, product(d,d,d), inference(rewrite, [status(thm)], [f26, s46])).
fof(lemma_24, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_17, s47])).
fof(s48, plain, b = d, inference(mp, [status(thm)], [f17, lemma_24, lemma_23])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_19, s48])).
% SZS output end Proof
