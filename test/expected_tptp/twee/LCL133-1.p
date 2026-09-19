% SZS output start Proof
cnf(c2, axiom, implies(truth, X) = X, file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_1)).
cnf(c4, negated_conjecture, implies(X2, Y) = implies(Y, X2), file('TPTP/Problems/LCL/LCL133-1.p', lemma_antecedent)).
cnf(c6, axiom, implies(implies(X2, Y2), Y2) = implies(implies(Y2, X2), X2), file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_3)).
cnf(c13, axiom, implies(implies(X2, Y2), implies(implies(Y2, Z), implies(X2, Z))) = truth, file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_2)).
fof(s1, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(X,implies(X,Y))), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(truth,implies(X,implies(X,Y)))), inference(rewrite, [status(thm)], [c2, s1])).
fof(s3, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(truth,implies(truth,implies(X,implies(X,Y))))), inference(rewrite, [status(thm)], [c2, s2])).
fof(s4, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(truth,implies(truth,implies(truth,implies(X,implies(X,Y)))))), inference(rewrite, [status(thm)], [c2, s3])).
fof(s5, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(truth,implies(implies(truth,implies(X,implies(X,Y))),truth))), inference(rewrite, [status(thm)], [c4, s4])).
fof(s6, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(implies(implies(truth,implies(X,implies(X,Y))),truth),truth)), inference(rewrite, [status(thm)], [c4, s5])).
fof(s7, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(implies(truth,implies(truth,implies(X,implies(X,Y)))),implies(truth,implies(X,implies(X,Y))))), inference(rewrite, [status(thm)], [c6, s6])).
fof(s8, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(implies(truth,implies(X,implies(X,Y))),implies(truth,implies(truth,implies(X,implies(X,Y)))))), inference(rewrite, [status(thm)], [c4, s7])).
fof(s9, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(truth,implies(implies(truth,implies(X,implies(X,Y))),implies(truth,implies(X,implies(X,Y))))), inference(rewrite, [status(thm)], [c2, s8])).
fof(s10, plain, ! [X,Y] : implies(X,implies(X,Y)) = implies(implies(truth,truth),implies(implies(truth,implies(X,implies(X,Y))),implies(truth,implies(X,implies(X,Y))))), inference(rewrite, [status(thm)], [c2, s9])).
fof(lemma_5, lemma, ! [X,Y] : implies(X,implies(X,Y)) = truth, inference(rewrite, [status(thm)], [c13, s10])).
fof(s11, plain, x = implies(truth,x), inference(instantiate, [status(thm)], [c2])).
fof(s12, plain, x = implies(truth,implies(truth,x)), inference(rewrite, [status(thm)], [c2, s11])).
fof(s13, plain, x = truth, inference(rewrite, [status(thm)], [lemma_5, s12])).
fof(s14, plain, x = implies(truth,implies(truth,y)), inference(rewrite, [status(thm)], [lemma_5, s13])).
fof(s15, plain, x = implies(truth,y), inference(rewrite, [status(thm)], [c2, s14])).
fof(goal_1, theorem, x = y, inference(rewrite, [status(thm)], [c2, s15])).
% SZS output end Proof
