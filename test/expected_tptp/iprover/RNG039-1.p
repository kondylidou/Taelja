% SZS output start Proof
fof(c_51, plain, ! [X0]: sum(X0, X0, additive_identity), file('Problems/RNG/RNG039-1.p', clause32)).
fof(c_53, plain, ! [X0]: add(X0, X0) = additive_identity, file('Problems/RNG/RNG039-1.p', clause34)).
fof(c_54, plain, ! [X0]: multiply(X0, X0) = X0, file('Problems/RNG/RNG039-1.p', clause35)).
fof(c_56, plain, multiply(b, a) = d, file('Problems/RNG/RNG039-1.p', clause37)).
fof(c_62, plain, ! [X0, X1]: product(X0, multiply(X0, X1), multiply(X0, X1)), file('Problems/RNG/RNG039-1.p', clause43)).
fof(c_63, plain, ! [X0, X1]: product(a, multiply(b, X0), multiply(X1, X0)), file('Problems/RNG/RNG039-1.p', clause44)).
fof(c_85, plain, product(add(b, a), b, add(b, c)), file('Problems/RNG/RNG039-1.p', clause68)).
fof(c_88, plain, ! [X0]: product(X0, X0, X0), file('Problems/RNG/RNG039-1.p', clause71)).
fof(c_89, plain, product(a, b, c), file('Problems/RNG/RNG039-1.p', a_times_b)).
fof(c_90, plain, product(b, a, d), file('Problems/RNG/RNG039-1.p', b_times_a)).
fof(c_93, plain, ! [X0]: sum(X0, additive_identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', additive_identity2)).
fof(c_105, plain, ! [X0, X1, X2, X3, X4, X5, X6]: (~ sum(X0, X1, X2) | ~ product(X0, X3, X4) | ~ product(X1, X3, X5) | ~ product(X2, X3, X6) | sum(X4, X5, X6)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', distributivity3)).
fof(c_107, plain, ! [X0, X1, X2, X3]: (~ sum(X0, X1, X2) | ~ sum(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', addition_is_well_defined)).
fof(c_108, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', multiplication_is_well_defined)).
fof(s1, plain, product(a,multiply(b,a),multiply(a,a)), inference(instantiate, [status(thm)], [c_63])).
fof(s2, plain, product(a,d,multiply(a,a)), inference(rewrite, [status(thm)], [c_56, s1])).
fof(lemma_15, lemma, product(a,d,a), inference(rewrite, [status(thm)], [c_54, s2])).
fof(s3, plain, product(a,multiply(b,a),multiply(b,a)), inference(instantiate, [status(thm)], [c_63])).
fof(s4, plain, product(a,multiply(b,a),d), inference(rewrite, [status(thm)], [c_56, s3])).
fof(s5, plain, product(a,d,d), inference(rewrite, [status(thm)], [c_56, s4])).
fof(lemma_16, lemma, a = d, inference(mp, [status(thm)], [c_108, s5, lemma_15])).
fof(s6, plain, ! [X] : product(a,multiply(b,b),multiply(X,b)), inference(instantiate, [status(thm)], [c_63])).
fof(lemma_17, lemma, ! [X] : product(a,b,multiply(X,b)), inference(rewrite, [status(thm)], [c_54, s6])).
fof(s7, plain, ! [X] : (product(a,b,X) => product(a,b,X)), inference(assumption, [status(thm)], [])).
fof(lemma_18, lemma, ! [X] : (product(a,b,X) => X = c), inference(mp, [status(thm)], [c_108, c_89, s7])).
fof(s8, plain, product(a,b,multiply(b,b)), inference(instantiate, [status(thm)], [lemma_17])).
fof(s9, plain, product(a,b,b), inference(rewrite, [status(thm)], [c_54, s8])).
fof(lemma_19, lemma, b = c, inference(mp, [status(thm)], [lemma_18, s9])).
fof(lemma_20, lemma, ! [X] : multiply(X,b) = c, inference(mp, [status(thm)], [lemma_18, lemma_17])).
fof(lemma_21, lemma, ! [X] : multiply(X,b) = b, inference(rewrite, [status(thm)], [lemma_19, lemma_20])).
fof(s10, plain, product(add(b,a),b,add(b,b)), inference(rewrite, [status(thm)], [lemma_19, c_85])).
fof(lemma_22, lemma, product(add(b,a),b,additive_identity), inference(rewrite, [status(thm)], [c_53, s10])).
fof(s11, plain, product(add(b,a),multiply(add(b,a),b),multiply(add(b,a),b)), inference(instantiate, [status(thm)], [c_62])).
fof(s12, plain, product(add(b,a),multiply(add(b,a),b),b), inference(rewrite, [status(thm)], [lemma_21, s11])).
fof(s13, plain, product(add(b,a),b,b), inference(rewrite, [status(thm)], [lemma_21, s12])).
fof(lemma_23, lemma, additive_identity = b, inference(mp, [status(thm)], [c_108, s13, lemma_22])).
fof(lemma_24, lemma, product(b,a,a), inference(rewrite, [status(thm)], [lemma_16, c_90])).
fof(s14, plain, sum(a,additive_identity,a), inference(instantiate, [status(thm)], [c_93])).
fof(s15, plain, sum(a,b,a), inference(rewrite, [status(thm)], [lemma_23, s14])).
fof(s16, plain, product(a,a,a), inference(instantiate, [status(thm)], [c_88])).
fof(s17, plain, product(a,a,a), inference(instantiate, [status(thm)], [c_88])).
fof(lemma_25, lemma, sum(a,a,a), inference(mp, [status(thm)], [c_105, s15, s16, lemma_24, s17])).
fof(s18, plain, sum(a,a,additive_identity), inference(instantiate, [status(thm)], [c_51])).
fof(s19, plain, additive_identity = a, inference(mp, [status(thm)], [c_107, s18, lemma_25])).
fof(s20, plain, b = a, inference(rewrite, [status(thm)], [lemma_23, s19])).
fof(s21, plain, b = d, inference(rewrite, [status(thm)], [lemma_16, s20])).
fof(goal_1, theorem, c = d, inference(rewrite, [status(thm)], [lemma_19, s21])).
% SZS output end Proof
