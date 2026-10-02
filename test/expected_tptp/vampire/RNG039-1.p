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
fof(s1, plain, ! [X] : product(a,multiply(b,b),multiply(X,b)), inference(instantiate, [status(thm)], [f33])).
fof(lemma_13, lemma, ! [X] : product(a,b,multiply(X,b)), inference(rewrite, [status(thm)], [f24, s1])).
fof(s2, plain, product(a,b,multiply(b,b)), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_14, lemma, product(a,b,b), inference(rewrite, [status(thm)], [f24, s2])).
fof(lemma_15, lemma, b = c, inference(mp, [status(thm)], [f17, f59, lemma_14])).
fof(s3, plain, ! [X] : multiply(X,b) = c, inference(mp, [status(thm)], [f17, f59, lemma_13])).
fof(lemma_16, lemma, ! [X] : b = multiply(X,b), inference(rewrite, [status(thm)], [lemma_15, s3])).
fof(s4, plain, product(add(a,b),b,multiply(add(a,b),b)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_17, lemma, product(add(a,b),b,b), inference(rewrite, [status(thm)], [lemma_16, s4])).
fof(s5, plain, product(add(a,b),b,add(b,b)), inference(rewrite, [status(thm)], [lemma_15, f54])).
fof(lemma_18, lemma, product(add(a,b),b,additive_identity), inference(rewrite, [status(thm)], [f22, s5])).
fof(lemma_19, lemma, additive_identity = b, inference(mp, [status(thm)], [f17, lemma_17, lemma_18])).
fof(s6, plain, product(multiply(a,b),a,multiply(a,d)), inference(instantiate, [status(thm)], [f46])).
fof(lemma_20, lemma, product(b,a,multiply(a,d)), inference(rewrite, [status(thm)], [lemma_16, s6])).
fof(lemma_21, lemma, multiply(a,d) = d, inference(mp, [status(thm)], [f17, f60, lemma_20])).
fof(s7, plain, product(a,d,multiply(a,d)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_22, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_21, s7])).
fof(s8, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [f33])).
fof(s9, plain, product(a,d,multiply(a,a)), inference(rewrite, [status(thm)], [f26, s8])).
fof(lemma_23, lemma, product(a,d,a), inference(rewrite, [status(thm)], [f24, s9])).
fof(lemma_24, lemma, a = d, inference(mp, [status(thm)], [f17, lemma_22, lemma_23])).
fof(s10, plain, product(multiply(a,b),a,multiply(a,d)), inference(instantiate, [status(thm)], [f46])).
fof(lemma_25, lemma, product(b,a,multiply(a,d)), inference(rewrite, [status(thm)], [lemma_16, s10])).
fof(lemma_26, lemma, multiply(a,d) = d, inference(mp, [status(thm)], [f17, f60, lemma_25])).
fof(s11, plain, ! [X] : add(X,b) = add(X,additive_identity), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_27, lemma, ! [X] : add(X,b) = X, inference(rewrite, [status(thm)], [f21, s11])).
fof(s12, plain, product(a,d,multiply(a,d)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_28, lemma, product(a,d,d), inference(rewrite, [status(thm)], [lemma_26, s12])).
fof(s13, plain, product(a,a,add(a,d)), inference(rewrite, [status(thm)], [lemma_27, f57])).
fof(s14, plain, product(a,a,add(a,a)), inference(rewrite, [status(thm)], [lemma_24, s13])).
fof(s15, plain, product(a,a,additive_identity), inference(rewrite, [status(thm)], [f22, s14])).
fof(lemma_29, lemma, product(a,a,b), inference(rewrite, [status(thm)], [lemma_19, s15])).
fof(lemma_30, lemma, product(a,d,b), inference(rewrite, [status(thm)], [lemma_24, lemma_29])).
fof(s16, plain, b = d, inference(mp, [status(thm)], [f17, lemma_28, lemma_30])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_15, s16])).
% SZS output end Proof
