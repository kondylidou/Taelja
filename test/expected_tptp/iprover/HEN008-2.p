% SZS output start Proof
fof(c_50, plain, ! [X0]: quotient(zero, X0, zero), file('Problems/HEN/HEN008-2.p', zero_divide_anything_is_zero)).
fof(c_52, plain, ! [X0]: quotient(X0, zero, X0), file('Problems/HEN/HEN008-2.p', x_divde_zero_is_x)).
fof(c_54, plain, ! [X0, X1, X2, X3, X4]: (~ quotient(X0, X1, X2) | ~ quotient(X0, X3, X4) | ~ less_equal(X2, X3) | less_equal(X4, X1)), file('Problems/HEN/HEN008-2.p', xQyLEz_implies_xQzLEy)).
fof(c_56, plain, less_equal(a, b), file('Problems/HEN/HEN008-2.p', aLEb)).
fof(c_57, plain, quotient(a, c, aQc), file('Problems/HEN/HEN008-2.p', aQc)).
fof(c_58, plain, quotient(b, c, bQc), file('Problems/HEN/HEN008-2.p', bQc)).
fof(c_60, plain, ! [X0, X1]: (~ less_equal(X0, X1) | quotient(X0, X1, zero)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', quotient_less_equal)).
fof(c_63, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7]: (~ quotient(X0, X1, X2) | ~ quotient(X0, X3, X4) | ~ quotient(X1, X3, X5) | ~ quotient(X2, X3, X6) | ~ quotient(X4, X5, X7) | less_equal(X7, X6)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', quotient_property)).
fof(c_67, plain, ! [X0, X1]: quotient(X0, X1, divide(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/HEN001-0.ax', closure)).
fof(lemma_10, lemma, quotient(a,b,zero), inference(mp, [status(thm)], [c_60, c_56])).
fof(s1, plain, quotient(zero,c,zero), inference(instantiate, [status(thm)], [c_50])).
fof(s2, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [c_67])).
fof(lemma_11, lemma, less_equal(divide(aQc,bQc),zero), inference(mp, [status(thm)], [c_63, lemma_10, c_57, c_58, s1, s2])).
fof(s3, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [c_67])).
fof(s4, plain, quotient(aQc,zero,aQc), inference(instantiate, [status(thm)], [c_52])).
fof(goal_1, theorem, less_equal(aQc,bQc), inference(mp, [status(thm)], [c_54, s3, s4, lemma_11])).
% SZS output end Proof
