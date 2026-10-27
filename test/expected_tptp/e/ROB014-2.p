% SZS output start Proof
cnf(robbins_axiom, axiom, negate(add(negate(add(X1, X2)), negate(add(X1, negate(X2))))) = X1, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', robbins_axiom)).
cnf(commutativity_of_add, axiom, add(X1, X2) = add(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', commutativity_of_add)).
cnf(condition, hypothesis, negate(add(negate(e), negate(add(d, negate(e))))) = d, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/ROB/ROB014-2.p', condition)).
cnf(lemma_3_2, axiom, X1 = X2 | negate(add(X1, negate(add(X2, X3)))) != negate(add(X2, negate(add(X1, X3)))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/ROB/ROB014-2.p', lemma_3_2)).
cnf(associativity_of_add, axiom, add(add(X1, X2), X3) = add(X1, add(X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', associativity_of_add)).
cnf(one_times_x, axiom, multiply(one, X1) = X1, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-1.ax', one_times_x)).
fof(s1, plain, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(negate(Y),X)))) = negate(add(negate(add(X,Y)),negate(add(X,negate(Y))))), inference(instantiate, [status(thm)], [commutativity_of_add])).
fof(lemma_7, lemma, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(negate(Y),X)))) = X, inference(rewrite, [status(thm)], [robbins_axiom, s1])).
fof(s2, plain, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(Y,negate(X))))) = negate(add(negate(add(Y,X)),negate(add(Y,negate(X))))), inference(instantiate, [status(thm)], [commutativity_of_add])).
fof(lemma_8, lemma, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(Y,negate(X))))) = Y, inference(rewrite, [status(thm)], [robbins_axiom, s2])).
fof(s3, plain, ! [X,Y,Z] : add(X,add(Y,Z)) = add(add(X,Y),Z), inference(instantiate, [status(thm)], [associativity_of_add])).
fof(s4, plain, ! [X,Y,Z] : add(X,add(Y,Z)) = add(add(Y,X),Z), inference(rewrite, [status(thm)], [commutativity_of_add, s3])).
fof(lemma_9, lemma, ! [X,Y,Z] : add(X,add(Y,Z)) = add(Y,add(X,Z)), inference(rewrite, [status(thm)], [associativity_of_add, s4])).
fof(s5, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(e,negate(add(d,negate(e))))),d)), inference(instantiate, [status(thm)], [commutativity_of_add])).
fof(s6, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(negate(add(d,negate(e))),e)),d)), inference(rewrite, [status(thm)], [commutativity_of_add, s5])).
fof(s7, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(negate(add(d,negate(e))),e)),negate(add(negate(e),negate(add(d,negate(e))))))), inference(rewrite, [status(thm)], [condition, s6])).
fof(lemma_10, lemma, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(d,negate(e))), inference(rewrite, [status(thm)], [lemma_7, s7])).
fof(s8, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(e),negate(add(negate(add(add(e,d),negate(add(d,negate(e))))),d)))), inference(instantiate, [status(thm)], [associativity_of_add])).
fof(s9, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(e),negate(add(negate(add(negate(add(d,negate(e))),add(e,d))),d)))), inference(rewrite, [status(thm)], [commutativity_of_add, s8])).
fof(s10, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(e),negate(add(negate(add(negate(add(d,negate(e))),add(e,d))),negate(add(negate(add(e,d)),negate(add(d,negate(e))))))))), inference(rewrite, [status(thm)], [lemma_8, s9])).
fof(s11, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(e),negate(add(d,negate(e))))), inference(rewrite, [status(thm)], [lemma_7, s10])).
fof(s12, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = d, inference(rewrite, [status(thm)], [condition, s11])).
fof(s13, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(add(d,add(e,negate(add(d,negate(e)))))),negate(add(d,negate(add(e,negate(add(d,negate(e))))))))), inference(rewrite, [status(thm)], [robbins_axiom, s12])).
fof(s14, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(add(d,add(e,negate(add(d,negate(e)))))),negate(add(d,negate(e))))), inference(rewrite, [status(thm)], [lemma_10, s13])).
fof(s15, plain, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(d,negate(e))))), inference(rewrite, [status(thm)], [lemma_9, s14])).
fof(lemma_11, lemma, negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))) = negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))), inference(rewrite, [status(thm)], [commutativity_of_add, s15])).
fof(s16, plain, negate(e) = negate(add(e,add(d,negate(add(d,negate(e)))))), inference(mp, [status(thm)], [lemma_3_2, lemma_11])).
fof(goal_1, theorem, negate(add(e,multiply(one,add(d,negate(add(d,negate(e))))))) = negate(e), inference(rewrite, [status(thm)], [one_times_x, s16])).
% SZS output end Proof
