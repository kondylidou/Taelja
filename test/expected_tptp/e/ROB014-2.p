% SZS output start Proof
cnf(lemma_3_2, axiom, X1 = X2 | negate(add(X1, negate(add(X2, X3)))) != negate(add(X2, negate(add(X1, X3)))), file('Problems/ROB/ROB014-2.p', lemma_3_2)).
cnf(robbins_axiom, axiom, negate(add(negate(add(X1, X2)), negate(add(X1, negate(X2))))) = X1, file('TPTP/Axioms/ROB001-0.ax', robbins_axiom)).
cnf(commutativity_of_add, axiom, add(X1, X2) = add(X2, X1), file('TPTP/Axioms/ROB001-0.ax', commutativity_of_add)).
cnf(condition, hypothesis, negate(add(negate(e), negate(add(d, negate(e))))) = d, file('Problems/ROB/ROB014-2.p', condition)).
cnf(associativity_of_add, axiom, add(add(X1, X2), X3) = add(X1, add(X2, X3)), file('TPTP/Axioms/ROB001-0.ax', associativity_of_add)).
cnf(one_times_x, axiom, multiply(one, X1) = X1, file('TPTP/Axioms/ROB001-1.ax', one_times_x)).
cnf(lemma_3_4, axiom, negate(add(X1, negate(add(X2, multiply(X4, add(X1, X3)))))) = X3 | negate(add(X1, negate(X2))) != X3 | ~ positive_integer(X4), file('Problems/ROB/ROB014-2.p', lemma_3_4)).
cnf(one, axiom, positive_integer(one), file('TPTP/Axioms/ROB001-1.ax', one)).
fof(s1, plain, ! [X,Y,Z] : add(X,add(Y,Z)) = add(add(X,Y),Z), inference(instantiate, [status(thm)], [associativity_of_add])).
fof(s2, plain, ! [X,Y,Z] : add(X,add(Y,Z)) = add(add(Y,X),Z), inference(rewrite, [status(thm)], [commutativity_of_add, s1])).
fof(lemma_9, lemma, ! [X,Y,Z] : add(X,add(Y,Z)) = add(Y,add(X,Z)), inference(rewrite, [status(thm)], [associativity_of_add, s2])).
fof(s3, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(d,negate(add(negate(add(d,negate(e))),e)))), inference(instantiate, [status(thm)], [commutativity_of_add])).
fof(s4, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(negate(add(d,negate(e))),e)),d)), inference(rewrite, [status(thm)], [commutativity_of_add, s3])).
fof(s5, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(negate(add(d,negate(e))),e)),negate(add(negate(e),negate(add(d,negate(e))))))), inference(rewrite, [status(thm)], [condition, s4])).
fof(s6, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(negate(add(d,negate(e))),e)),negate(add(negate(add(d,negate(e))),negate(e))))), inference(rewrite, [status(thm)], [commutativity_of_add, s5])).
fof(lemma_10, lemma, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(d,negate(e))), inference(rewrite, [status(thm)], [robbins_axiom, s6])).
fof(s7, plain, negate(add(d,negate(add(e,multiply(one,add(d,negate(add(d,negate(e))))))))) = negate(add(d,negate(e))), inference(mp, [status(thm)], [lemma_3_4, one])).
fof(lemma_11, lemma, negate(add(d,negate(add(e,add(d,negate(add(d,negate(e)))))))) = negate(add(d,negate(e))), inference(rewrite, [status(thm)], [one_times_x, s7])).
fof(s8, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(negate(e),negate(add(negate(add(d,add(e,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))), inference(instantiate, [status(thm)], [lemma_9])).
fof(s9, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(negate(e),negate(add(negate(add(d,add(e,negate(add(d,negate(e)))))),negate(add(d,negate(add(e,negate(add(d,negate(e))))))))))), inference(rewrite, [status(thm)], [lemma_10, s8])).
fof(s10, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(negate(e),d)), inference(rewrite, [status(thm)], [robbins_axiom, s9])).
fof(s11, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(d,negate(e))), inference(rewrite, [status(thm)], [commutativity_of_add, s10])).
fof(s12, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(d,negate(add(e,add(d,negate(add(d,negate(e)))))))), inference(rewrite, [status(thm)], [lemma_11, s11])).
fof(s13, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)), inference(rewrite, [status(thm)], [commutativity_of_add, s12])).
fof(lemma_12, lemma, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))))) = negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),negate(add(d,negate(e))))))), inference(rewrite, [status(thm)], [condition, s13])).
fof(s14, plain, negate(e) = negate(add(e,add(d,negate(add(d,negate(e)))))), inference(mp, [status(thm)], [lemma_3_2, lemma_12])).
fof(goal_1, theorem, negate(add(e,multiply(one,add(d,negate(add(d,negate(e))))))) = negate(e), inference(rewrite, [status(thm)], [one_times_x, s14])).
% SZS output end Proof
