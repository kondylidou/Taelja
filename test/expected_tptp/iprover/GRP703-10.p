% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: mult(X0, ld(X0, X1)) = X1, file('Problems/GRP/GRP703-10.p', f01)).
fof(c_50, plain, ! [X0, X1]: ld(X0, mult(X0, X1)) = X1, file('Problems/GRP/GRP703-10.p', f02)).
fof(c_51, plain, ! [X0, X1]: mult(rd(X0, X1), X1) = X0, file('Problems/GRP/GRP703-10.p', f03)).
fof(c_53, plain, ! [X0]: mult(X0, unit) = X0, file('Problems/GRP/GRP703-10.p', f05)).
fof(c_54, plain, ! [X0]: mult(unit, X0) = X0, file('Problems/GRP/GRP703-10.p', f06)).
fof(c_56, plain, ! [X0, X1]: mult(mult(op_c, X0), X1) = mult(op_c, mult(X0, X1)), file('Problems/GRP/GRP703-10.p', f08)).
fof(c_60, plain, ! [X0, X1]: mult(mult(rd(op_c, mult(X0, X1)), X1), X0) = op_e, file('Problems/GRP/GRP703-10.p', f12)).
fof(s1, plain, op_c = mult(rd(op_c,op_c),op_c), inference(instantiate, [status(thm)], [c_51])).
fof(s2, plain, op_c = mult(rd(op_c,mult(unit,op_c)),op_c), inference(rewrite, [status(thm)], [c_54, s1])).
fof(s3, plain, op_c = mult(mult(rd(op_c,mult(unit,op_c)),op_c),unit), inference(rewrite, [status(thm)], [c_53, s2])).
fof(lemma_8, lemma, op_c = op_e, inference(rewrite, [status(thm)], [c_60, s3])).
fof(s4, plain, ld(op_c,mult(op_e,x2)) = ld(op_e,mult(op_e,x2)), inference(instantiate, [status(thm)], [lemma_8])).
fof(lemma_9, lemma, ld(op_c,mult(op_e,x2)) = x2, inference(rewrite, [status(thm)], [c_50, s4])).
fof(s5, plain, mult(mult(op_e,x2),x3) = mult(mult(op_c,ld(op_c,mult(op_e,x2))),x3), inference(instantiate, [status(thm)], [c_49])).
fof(s6, plain, mult(mult(op_e,x2),x3) = mult(op_c,mult(ld(op_c,mult(op_e,x2)),x3)), inference(rewrite, [status(thm)], [c_56, s5])).
fof(s7, plain, mult(mult(op_e,x2),x3) = mult(op_c,mult(x2,x3)), inference(rewrite, [status(thm)], [lemma_9, s6])).
fof(goal_1, theorem, mult(mult(op_e,x2),x3) = mult(op_e,mult(x2,x3)), inference(rewrite, [status(thm)], [lemma_8, s7])).
% SZS output end Proof
