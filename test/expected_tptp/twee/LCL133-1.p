% SZS output start Proof
cnf(c2, axiom, implies(truth, X) = X, file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_1)).
cnf(c4, negated_conjecture, implies(X2, Y) = implies(Y, X2), file('TPTP/Problems/LCL/LCL133-1.p', lemma_antecedent)).
cnf(c6, axiom, implies(implies(X2, Y2), Y2) = implies(implies(Y2, X2), X2), file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_3)).
cnf(c13, axiom, implies(implies(X2, Y2), implies(implies(Y2, Z), implies(X2, Z))) = truth, file('TPTP/Problems/LCL/LCL133-1.p', wajsberg_2)).
fof(s1, plain, x = implies(truth,x), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, x = implies(truth,implies(truth,x)), inference(rewrite, [status(thm)], [c2, s1])).
fof(s3, plain, x = implies(truth,implies(truth,implies(truth,x))), inference(rewrite, [status(thm)], [c2, s2])).
fof(s4, plain, x = implies(truth,implies(truth,implies(truth,implies(truth,x)))), inference(rewrite, [status(thm)], [c2, s3])).
fof(s5, plain, x = implies(truth,implies(truth,implies(implies(truth,x),truth))), inference(rewrite, [status(thm)], [c4, s4])).
fof(s6, plain, x = implies(truth,implies(implies(implies(truth,x),truth),truth)), inference(rewrite, [status(thm)], [c4, s5])).
fof(s7, plain, x = implies(truth,implies(implies(truth,implies(truth,x)),implies(truth,x))), inference(rewrite, [status(thm)], [c6, s6])).
fof(s8, plain, x = implies(truth,implies(implies(truth,x),implies(truth,implies(truth,x)))), inference(rewrite, [status(thm)], [c4, s7])).
fof(s9, plain, x = implies(truth,implies(implies(truth,x),implies(truth,x))), inference(rewrite, [status(thm)], [c2, s8])).
fof(s10, plain, x = implies(implies(truth,truth),implies(implies(truth,x),implies(truth,x))), inference(rewrite, [status(thm)], [c2, s9])).
fof(s11, plain, x = truth, inference(rewrite, [status(thm)], [c13, s10])).
fof(s12, plain, x = implies(implies(truth,truth),implies(implies(truth,y),implies(truth,y))), inference(rewrite, [status(thm)], [c13, s11])).
fof(s13, plain, x = implies(truth,implies(implies(truth,y),implies(truth,y))), inference(rewrite, [status(thm)], [c2, s12])).
fof(s14, plain, x = implies(truth,implies(implies(truth,y),implies(truth,implies(truth,y)))), inference(rewrite, [status(thm)], [c2, s13])).
fof(s15, plain, x = implies(truth,implies(implies(truth,implies(truth,y)),implies(truth,y))), inference(rewrite, [status(thm)], [c4, s14])).
fof(s16, plain, x = implies(truth,implies(implies(implies(truth,y),truth),truth)), inference(rewrite, [status(thm)], [c6, s15])).
fof(s17, plain, x = implies(truth,implies(truth,implies(implies(truth,y),truth))), inference(rewrite, [status(thm)], [c4, s16])).
fof(s18, plain, x = implies(truth,implies(truth,implies(truth,implies(truth,y)))), inference(rewrite, [status(thm)], [c4, s17])).
fof(s19, plain, x = implies(truth,implies(truth,implies(truth,y))), inference(rewrite, [status(thm)], [c2, s18])).
fof(s20, plain, x = implies(truth,implies(truth,y)), inference(rewrite, [status(thm)], [c2, s19])).
fof(s21, plain, x = implies(truth,y), inference(rewrite, [status(thm)], [c2, s20])).
fof(goal_1, theorem, x = y, inference(rewrite, [status(thm)], [c2, s21])).
% SZS output end Proof
