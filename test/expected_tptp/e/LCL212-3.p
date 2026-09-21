% SZS output start Proof
cnf(rule_2, axiom, theorem(X1) | ~ theorem(implies(X2, X1)) | ~ theorem(X2), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', rule_2)).
cnf(implies_definition, axiom, implies(X1, X2) = or(not(X1), X2), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', implies_definition)).
cnf(rule_1, axiom, theorem(X1) | ~ axiom(X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', rule_1)).
cnf(axiom_1_3, axiom, axiom(implies(X1, or(X2, X1))), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/LCL004-0.ax', axiom_1_3)).
fof(lemma_5, lemma, ! [X,Y] : axiom(or(not(X),or(Y,X))), inference(rewrite, [status(thm)], [implies_definition, axiom_1_3])).
fof(s1, plain, axiom(or(not(q),or(not(or(not(p),q)),q))), inference(instantiate, [status(thm)], [lemma_5])).
fof(lemma_6, lemma, theorem(or(not(q),or(not(or(not(p),q)),q))), inference(mp, [status(thm)], [rule_1, s1])).
fof(s2, plain, axiom(or(not(or(not(q),or(not(or(not(p),q)),q))),or(not(not(p)),or(not(q),or(not(or(not(p),q)),q))))), inference(instantiate, [status(thm)], [lemma_5])).
fof(s3, plain, theorem(or(not(or(not(q),or(not(or(not(p),q)),q))),or(not(not(p)),or(not(q),or(not(or(not(p),q)),q))))), inference(mp, [status(thm)], [rule_1, s2])).
fof(s4, plain, theorem(implies(or(not(q),or(not(or(not(p),q)),q)),or(not(not(p)),or(not(q),or(not(or(not(p),q)),q))))), inference(rewrite, [status(thm)], [implies_definition, s3])).
fof(lemma_7, lemma, theorem(or(not(not(p)),or(not(q),or(not(or(not(p),q)),q)))), inference(mp, [status(thm)], [rule_2, s4, lemma_6])).
fof(s5, plain, theorem(or(not(not(p)),or(not(q),or(not(implies(p,q)),q)))), inference(rewrite, [status(thm)], [implies_definition, lemma_7])).
fof(s6, plain, theorem(or(not(not(p)),or(not(q),implies(implies(p,q),q)))), inference(rewrite, [status(thm)], [implies_definition, s5])).
fof(s7, plain, theorem(or(not(not(p)),implies(q,implies(implies(p,q),q)))), inference(rewrite, [status(thm)], [implies_definition, s6])).
fof(goal_1, theorem, theorem(implies(not(p),implies(q,implies(implies(p,q),q)))), inference(rewrite, [status(thm)], [implies_definition, s7])).
% SZS output end Proof
