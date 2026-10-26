% SZS output start Proof
fof(c_51, plain, ! [X0, X1]: axiom(implies(X0, or(X1, X0))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', axiom_1_3)).
fof(c_55, plain, ! [X0, X1]: or(not(X0), X1) = implies(X0, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', implies_definition)).
fof(c_56, plain, ! [X0]: (~ axiom(X0) | theorem(X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', rule_1)).
fof(c_57, plain, ! [X0, X1]: (~ theorem(implies(X0, X1)) | ~ theorem(X0) | theorem(X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', rule_2)).
fof(s1, plain, ! [X,Y] : axiom(implies(X,or(not(Y),X))), inference(instantiate, [status(thm)], [c_51])).
fof(s2, plain, ! [X,Y] : theorem(implies(X,or(not(Y),X))), inference(mp, [status(thm)], [c_56, s1])).
fof(lemma_5, lemma, ! [X,Y] : theorem(implies(X,implies(Y,X))), inference(rewrite, [status(thm)], [c_55, s2])).
fof(s3, plain, theorem(implies(implies(q,implies(implies(p,q),q)),implies(not(p),implies(q,implies(implies(p,q),q))))), inference(instantiate, [status(thm)], [lemma_5])).
fof(s4, plain, theorem(implies(q,implies(implies(p,q),q))), inference(instantiate, [status(thm)], [lemma_5])).
fof(goal_1, theorem, theorem(implies(not(p),implies(q,implies(implies(p,q),q)))), inference(mp, [status(thm)], [c_57, s3, s4])).
% SZS output end Proof
