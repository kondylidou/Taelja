% SZS output start Proof
cnf(quotient_property, axiom, less_equal(X7, X8) | ~ quotient(X1, X2, X3) | ~ quotient(X2, X4, X5) | ~ quotient(X1, X4, X6) | ~ quotient(X6, X5, X7) | ~ quotient(X3, X4, X8), file('TPTP/Axioms/HEN001-0.ax', quotient_property)).
cnf(quotient_less_equal, axiom, quotient(X1, X2, zero) | ~ less_equal(X1, X2), file('TPTP/Axioms/HEN001-0.ax', quotient_less_equal)).
cnf(closure, axiom, quotient(X1, X2, divide(X1, X2)), file('TPTP/Axioms/HEN001-0.ax', closure)).
cnf(zero_is_smallest, axiom, less_equal(zero, X1), file('TPTP/Axioms/HEN001-0.ax', zero_is_smallest)).
cnf(aLEb, hypothesis, less_equal(a, b), file('Problems/HEN/HEN008-1.p', aLEb)).
cnf(less_equal_and_equal, axiom, X1 = X2 | ~ less_equal(X1, X2) | ~ less_equal(X2, X1), file('TPTP/Axioms/HEN001-0.ax', less_equal_and_equal)).
cnf(less_equal_quotient, axiom, less_equal(X1, X2) | ~ quotient(X1, X2, zero), file('TPTP/Axioms/HEN001-0.ax', less_equal_quotient)).
cnf(bQc, hypothesis, quotient(b, c, bQc), file('Problems/HEN/HEN008-1.p', bQc)).
cnf(well_defined, axiom, X3 = X4 | ~ quotient(X1, X2, X3) | ~ quotient(X1, X2, X4), file('TPTP/Axioms/HEN001-0.ax', well_defined)).
cnf(aQc, hypothesis, quotient(a, c, aQc), file('Problems/HEN/HEN008-1.p', aQc)).
fof(lemma_11, lemma, ! [X] : quotient(zero,X,zero), inference(mp, [status(thm)], [quotient_less_equal, zero_is_smallest])).
fof(s1, plain, quotient(a,b,zero), inference(mp, [status(thm)], [quotient_less_equal, aLEb])).
fof(s2, plain, quotient(a,c,divide(a,c)), inference(instantiate, [status(thm)], [closure])).
fof(s3, plain, quotient(divide(a,c),bQc,divide(divide(a,c),bQc)), inference(instantiate, [status(thm)], [closure])).
fof(s4, plain, quotient(zero,c,zero), inference(instantiate, [status(thm)], [lemma_11])).
fof(lemma_12, lemma, less_equal(divide(divide(a,c),bQc),zero), inference(mp, [status(thm)], [quotient_property, s1, bQc, s2, s3, s4])).
fof(s5, plain, quotient(a,c,divide(a,c)), inference(instantiate, [status(thm)], [closure])).
fof(lemma_13, lemma, aQc = divide(a,c), inference(mp, [status(thm)], [well_defined, aQc, s5])).
fof(s6, plain, quotient(zero,divide(divide(a,c),bQc),zero), inference(instantiate, [status(thm)], [lemma_11])).
fof(s7, plain, less_equal(zero,divide(divide(a,c),bQc)), inference(mp, [status(thm)], [less_equal_quotient, s6])).
fof(lemma_14, lemma, zero = divide(divide(a,c),bQc), inference(mp, [status(thm)], [less_equal_and_equal, s7, lemma_12])).
fof(s8, plain, quotient(divide(a,c),bQc,divide(divide(a,c),bQc)), inference(instantiate, [status(thm)], [closure])).
fof(s9, plain, quotient(divide(a,c),bQc,zero), inference(rewrite, [status(thm)], [lemma_14, s8])).
fof(s10, plain, quotient(aQc,bQc,zero), inference(rewrite, [status(thm)], [lemma_13, s9])).
fof(goal_1, theorem, less_equal(aQc,bQc), inference(mp, [status(thm)], [less_equal_quotient, s10])).
% SZS output end Proof
