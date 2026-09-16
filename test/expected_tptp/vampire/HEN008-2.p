% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (quotient(X0, X1, zero) | ~ less_equal(X0, X1)), file('Problems/HEN/HEN008-2.p')).
fof(f4, axiom, ! [X2, X3, X0, X1, X6, X7, X4, X5]: (~ quotient(X5, X4, X6) | ~ quotient(X1, X3, X4) | ~ quotient(X0, X3, X5) | ~ quotient(X0, X1, X2) | ~ quotient(X2, X3, X7) | less_equal(X6, X7)), file('Problems/HEN/HEN008-2.p')).
fof(f8, axiom, ! [X0, X1]: quotient(X0, X1, divide(X0, X1)), file('Problems/HEN/HEN008-2.p')).
fof(f9, axiom, ! [X2, X3, X0, X1]: (~ quotient(X0, X1, X3) | ~ quotient(X0, X1, X2) | X2 = X3), file('Problems/HEN/HEN008-2.p')).
fof(f11, axiom, ! [X0]: quotient(zero, X0, zero), file('Problems/HEN/HEN008-2.p')).
fof(f13, axiom, ! [X0]: quotient(X0, zero, X0), file('Problems/HEN/HEN008-2.p')).
fof(f15, axiom, ! [X2, X3, X0, X1, X4]: (~ quotient(X0, X3, X4) | ~ less_equal(X2, X3) | ~ quotient(X0, X1, X2) | less_equal(X4, X1)), file('Problems/HEN/HEN008-2.p')).
fof(f17, axiom, less_equal(a, b), file('Problems/HEN/HEN008-2.p')).
fof(f18, axiom, quotient(a, c, aQc), file('Problems/HEN/HEN008-2.p')).
fof(f19, axiom, quotient(b, c, bQc), file('Problems/HEN/HEN008-2.p')).
fof(lemma_11, lemma, quotient(a,b,zero), inference(mp, [status(thm)], [f1, f17])).
fof(s1, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [f8])).
fof(s2, plain, quotient(zero,c,zero), inference(instantiate, [status(thm)], [f11])).
fof(lemma_12, lemma, less_equal(divide(aQc,bQc),zero), inference(mp, [status(thm)], [f4, s1, f19, f18, lemma_11, s2])).
fof(s3, plain, quotient(aQc,zero,aQc), inference(instantiate, [status(thm)], [f13])).
fof(s4, plain, quotient(aQc,bQc,divide(aQc,bQc)), inference(instantiate, [status(thm)], [f8])).
fof(goal_1, theorem, less_equal(aQc,bQc), inference(mp, [status(thm)], [f15, s3, lemma_12, s4])).
% SZS output end Proof
