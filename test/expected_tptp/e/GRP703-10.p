% SZS output start Proof
cnf(f05, axiom, mult(X1, unit) = X1, file('Problems/GRP/GRP703-10.p', f05)).
cnf(f12, axiom, op_e = mult(mult(rd(op_c, mult(X1, X2)), X2), X1), file('Problems/GRP/GRP703-10.p', f12)).
cnf(f06, axiom, mult(unit, X1) = X1, file('Problems/GRP/GRP703-10.p', f06)).
cnf(f03, axiom, mult(rd(X1, X2), X2) = X1, file('Problems/GRP/GRP703-10.p', f03)).
cnf(f08, axiom, mult(op_c, mult(X1, X2)) = mult(mult(op_c, X1), X2), file('Problems/GRP/GRP703-10.p', f08)).
fof(s1, plain, ! [Z] : op_e = mult(mult(rd(op_c,mult(unit,Z)),Z),unit), inference(instantiate, [status(thm)], [f12])).
fof(s2, plain, ! [Z] : op_e = mult(rd(op_c,mult(unit,Z)),Z), inference(rewrite, [status(thm)], [f05, s1])).
fof(s3, plain, ! [Z] : op_e = mult(rd(op_c,Z),Z), inference(rewrite, [status(thm)], [f06, s2])).
fof(lemma_6, lemma, op_e = op_c, inference(rewrite, [status(thm)], [f03, s3])).
fof(s4, plain, mult(op_e,mult(x2,x3)) = mult(op_c,mult(x2,x3)), inference(instantiate, [status(thm)], [lemma_6])).
fof(s5, plain, mult(op_e,mult(x2,x3)) = mult(mult(op_c,x2),x3), inference(rewrite, [status(thm)], [f08, s4])).
fof(goal_1, theorem, mult(op_e,mult(x2,x3)) = mult(mult(op_e,x2),x3), inference(rewrite, [status(thm)], [lemma_6, s5])).
% SZS output end Proof
