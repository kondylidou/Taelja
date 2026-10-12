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
fof(s2, plain, ! [X] : (product(a,b,X) => product(a,b,X)), inference(assumption, [status(thm)], [])).
fof(lemma_14, lemma, ! [X] : (product(a,b,X) => c = X), inference(mp, [status(thm)], [f17, f59, s2])).
fof(s3, plain, product(a,b,multiply(b,b)), inference(instantiate, [status(thm)], [lemma_13])).
fof(s4, plain, product(a,b,b), inference(rewrite, [status(thm)], [f24, s3])).
fof(lemma_15, lemma, b = c, inference(mp, [status(thm)], [lemma_14, s4])).
fof(s5, plain, ! [X] : c = multiply(X,b), inference(mp, [status(thm)], [lemma_14, lemma_13])).
fof(lemma_16, lemma, ! [X] : b = multiply(X,b), inference(rewrite, [status(thm)], [lemma_15, s5])).
fof(s6, plain, product(add(a,b),b,add(b,b)), inference(rewrite, [status(thm)], [lemma_15, f54])).
fof(lemma_17, lemma, product(add(a,b),b,additive_identity), inference(rewrite, [status(thm)], [f22, s6])).
fof(s7, plain, product(add(a,b),b,multiply(add(a,b),b)), inference(instantiate, [status(thm)], [f3])).
fof(s8, plain, product(add(a,b),b,b), inference(rewrite, [status(thm)], [lemma_16, s7])).
fof(lemma_18, lemma, additive_identity = b, inference(mp, [status(thm)], [f17, s8, lemma_17])).
fof(lemma_19, lemma, ! [X] : product(b,a,multiply(X,d)), inference(rewrite, [status(thm)], [lemma_16, f46])).
fof(lemma_20, lemma, ! [X] : multiply(X,d) = d, inference(mp, [status(thm)], [f17, f60, lemma_19])).
fof(s9, plain, ! [X,Y] : (product(X,d,Y) => product(X,d,multiply(X,d))), inference(instantiate, [status(thm)], [f3])).
fof(s10, plain, ! [X,Y] : (product(X,d,Y) => product(X,d,d)), inference(rewrite, [status(thm)], [lemma_20, s9])).
fof(s11, plain, ! [X,Y] : (product(X,d,Y) => product(X,d,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_21, lemma, ! [X,Y] : (product(X,d,Y) => d = Y), inference(mp, [status(thm)], [f17, s10, s11])).
fof(s12, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [f33])).
fof(s13, plain, product(a,d,multiply(a,a)), inference(rewrite, [status(thm)], [f26, s12])).
fof(s14, plain, product(a,d,a), inference(rewrite, [status(thm)], [f24, s13])).
fof(lemma_22, lemma, a = d, inference(mp, [status(thm)], [lemma_21, s14])).
fof(s15, plain, ! [X] : add(X,b) = add(X,additive_identity), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_23, lemma, ! [X] : add(X,b) = X, inference(rewrite, [status(thm)], [f21, s15])).
fof(s16, plain, product(a,a,add(a,d)), inference(rewrite, [status(thm)], [lemma_23, f57])).
fof(s17, plain, product(a,a,add(a,a)), inference(rewrite, [status(thm)], [lemma_22, s16])).
fof(s18, plain, product(a,a,additive_identity), inference(rewrite, [status(thm)], [f22, s17])).
fof(s19, plain, product(a,a,b), inference(rewrite, [status(thm)], [lemma_18, s18])).
fof(s20, plain, product(a,d,b), inference(rewrite, [status(thm)], [lemma_22, s19])).
fof(s21, plain, d = b, inference(mp, [status(thm)], [lemma_21, s20])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_15, s21])).
% SZS output end Proof
