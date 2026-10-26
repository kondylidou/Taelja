% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2]: (negate(add(X0, negate(add(X1, X2)))) != negate(add(X1, negate(add(X0, X2)))) | X0 = X1), file('Problems/ROB/ROB014-2.p', lemma_3_2)).
fof(c_51, plain, negate(add(negate(e), negate(add(d, negate(e))))) = d, file('Problems/ROB/ROB014-2.p', condition)).
fof(c_53, plain, ! [X0]: multiply(one, X0) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-1.ax', one_times_x)).
fof(c_57, plain, ! [X0, X1]: add(X0, X1) = add(X1, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', commutativity_of_add)).
fof(c_58, plain, ! [X0, X1, X2]: add(add(X0, X1), X2) = add(X0, add(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', associativity_of_add)).
fof(c_59, plain, ! [X0, X1]: negate(add(negate(add(X0, X1)), negate(add(X0, negate(X1))))) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/ROB001-0.ax', robbins_axiom)).
fof(s1, plain, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(Y,negate(X))))) = negate(add(negate(add(Y,X)),negate(add(Y,negate(X))))), inference(instantiate, [status(thm)], [c_57])).
fof(lemma_7, lemma, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(Y,negate(X))))) = Y, inference(rewrite, [status(thm)], [c_59, s1])).
fof(s2, plain, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(negate(X),Y)))) = negate(add(negate(add(X,Y)),negate(add(Y,negate(X))))), inference(instantiate, [status(thm)], [c_57])).
fof(lemma_8, lemma, ! [X,Y] : negate(add(negate(add(X,Y)),negate(add(negate(X),Y)))) = Y, inference(rewrite, [status(thm)], [lemma_7, s2])).
fof(s3, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(e,negate(add(d,negate(e))))),d)), inference(instantiate, [status(thm)], [c_57])).
fof(s4, plain, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(negate(add(e,negate(add(d,negate(e))))),negate(add(negate(e),negate(add(d,negate(e))))))), inference(rewrite, [status(thm)], [c_51, s3])).
fof(lemma_9, lemma, negate(add(d,negate(add(e,negate(add(d,negate(e))))))) = negate(add(d,negate(e))), inference(rewrite, [status(thm)], [lemma_8, s4])).
fof(s5, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(negate(e),d)),negate(add(e,add(d,negate(add(d,negate(e)))))))), inference(instantiate, [status(thm)], [c_57])).
fof(s6, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(d,negate(e))),negate(add(e,add(d,negate(add(d,negate(e)))))))), inference(rewrite, [status(thm)], [c_57, s5])).
fof(s7, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(d,negate(e))),negate(add(e,add(negate(add(d,negate(e))),d))))), inference(rewrite, [status(thm)], [c_57, s6])).
fof(s8, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(d,negate(e))),negate(add(add(e,negate(add(d,negate(e)))),d)))), inference(rewrite, [status(thm)], [c_58, s7])).
fof(s9, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(add(e,negate(add(d,negate(e)))),d)),negate(add(d,negate(e))))), inference(rewrite, [status(thm)], [c_57, s8])).
fof(s10, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(add(add(e,negate(add(d,negate(e)))),d)),negate(add(d,negate(add(e,negate(add(d,negate(e))))))))), inference(rewrite, [status(thm)], [lemma_9, s9])).
fof(s11, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = d, inference(rewrite, [status(thm)], [lemma_7, s10])).
fof(s12, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(d,negate(e))))), inference(rewrite, [status(thm)], [c_51, s11])).
fof(s13, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(negate(add(add(e,d),negate(add(d,negate(e))))),negate(add(negate(add(e,d)),negate(add(d,negate(e))))))))), inference(rewrite, [status(thm)], [lemma_8, s12])).
fof(s14, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(negate(add(add(e,d),negate(add(d,negate(e))))),d)))), inference(rewrite, [status(thm)], [lemma_7, s13])).
fof(s15, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(d,negate(add(add(e,d),negate(add(d,negate(e))))))))), inference(rewrite, [status(thm)], [c_57, s14])).
fof(s16, plain, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(d,negate(add(e,add(d,negate(add(d,negate(e)))))))))), inference(rewrite, [status(thm)], [c_58, s15])).
fof(lemma_10, lemma, negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),negate(add(negate(e),d)))) = negate(add(negate(e),negate(add(negate(add(e,add(d,negate(add(d,negate(e)))))),d)))), inference(rewrite, [status(thm)], [c_57, s16])).
fof(s17, plain, negate(add(e,add(d,negate(add(d,negate(e)))))) = negate(e), inference(mp, [status(thm)], [c_49, lemma_10])).
fof(goal_1, theorem, negate(add(e,multiply(one,add(d,negate(add(d,negate(e))))))) = negate(e), inference(rewrite, [status(thm)], [c_53, s17])).
% SZS output end Proof
