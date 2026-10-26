% SZS output start Proof
fof(c_49, plain, less_equal(a, b), file('HEN008-1.p', aLEb)).
fof(c_50, plain, quotient(a, c, aQc), file('HEN008-1.p', aQc)).
fof(c_51, plain, quotient(b, c, bQc), file('HEN008-1.p', bQc)).
fof(c_53, plain, ! [X0, X1]: (~ less_equal(X0, X1) | quotient(X0, X1, zero)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', quotient_less_equal)).
fof(c_54, plain, ! [X0, X1]: (~ quotient(X0, X1, zero) | less_equal(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', less_equal_quotient)).
fof(c_55, plain, ! [X0, X1, X2]: (~ quotient(X0, X1, X2) | less_equal(X2, X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', divisor_existence)).
fof(c_56, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7]: (~ quotient(X0, X1, X2) | ~ quotient(X0, X3, X4) | ~ quotient(X1, X3, X5) | ~ quotient(X2, X3, X6) | ~ quotient(X4, X5, X7) | less_equal(X7, X6)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', quotient_property)).
fof(c_57, plain, ! [X0]: less_equal(zero, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', zero_is_smallest)).
fof(c_58, plain, ! [X0, X1]: (~ less_equal(X0, X1) | ~ less_equal(X1, X0) | X0 = X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', less_equal_and_equal)).
fof(c_60, plain, ! [X0, X1]: quotient(X0, X1, divide(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', closure)).
fof(s1, plain, ! [X] : (less_equal(X,zero) => less_equal(X,zero)), inference(assumption, [status(thm)], [])).
fof(lemma_11, lemma, ! [X] : (less_equal(X,zero) => X = zero), inference(mp, [status(thm)], [c_58, c_57, s1])).
fof(lemma_12, lemma, quotient(a,b,zero), inference(mp, [status(thm)], [c_53, c_49])).
fof(s2, plain, quotient(zero,c,divide(zero,c)), inference(instantiate, [status(thm)], [c_60])).
fof(s3, plain, less_equal(divide(zero,c),zero), inference(mp, [status(thm)], [c_55, s2])).
fof(lemma_13, lemma, divide(zero,c) = zero, inference(mp, [status(thm)], [lemma_11, s3])).
fof(s4, plain, quotient(zero,c,divide(zero,c)), inference(instantiate, [status(thm)], [c_60])).
fof(lemma_14, lemma, quotient(zero,c,zero), inference(rewrite, [status(thm)], [lemma_13, s4])).
fof(s5, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [c_60])).
fof(s6, plain, less_equal(divide(aQc,bQc),zero), inference(mp, [status(thm)], [c_56, lemma_12, c_50, c_51, lemma_14, s5])).
fof(lemma_15, lemma, divide(aQc,bQc) = zero, inference(mp, [status(thm)], [lemma_11, s6])).
fof(s7, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [c_60])).
fof(s8, plain, quotient(aQc,bQc,zero), inference(rewrite, [status(thm)], [lemma_15, s7])).
fof(goal_1, theorem, less_equal(aQc,bQc), inference(mp, [status(thm)], [c_54, s8])).
% SZS output end Proof
