% SZS output start Proof
cnf(c2, negated_conjecture, p2(X0, X0), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN553-1.p', p2_1)).
cnf(c3, negated_conjecture, p2(f8(X11, X12), f8(X12, X11)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN553-1.p', p2_5)).
cnf(c4, negated_conjecture, p2(f8(X4, X5), f8(X6, X7)) | ~ p2(X4, X6) | ~ p2(X5, X7), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN553-1.p', p2_8)).
cnf(c7, negated_conjecture, p2(X1, X2) | ~ p2(X1, X3) | ~ p2(X3, X2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN553-1.p', p2_6)).
cnf(c10, negated_conjecture, p2(f8(X8, f8(X9, X10)), f8(f8(X8, X9), X10)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN553-1.p', p2_7)).
fof(s1, plain, p2(f9(c3),f9(c3)), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, p2(f8(f9(c4),c4),f8(c4,f9(c4))), inference(instantiate, [status(thm)], [c3])).
fof(lemma_6, lemma, p2(f8(f9(c3),f8(f9(c4),c4)),f8(f9(c3),f8(c4,f9(c4)))), inference(mp, [status(thm)], [c4, s1, s2])).
fof(s3, plain, p2(f8(f9(c3),f8(c4,f9(c4))),f8(f8(f9(c3),c4),f9(c4))), inference(instantiate, [status(thm)], [c10])).
fof(s4, plain, p2(f8(f8(f9(c3),c4),f9(c4)),f8(f9(c4),f8(f9(c3),c4))), inference(instantiate, [status(thm)], [c3])).
fof(lemma_7, lemma, p2(f8(f9(c3),f8(c4,f9(c4))),f8(f9(c4),f8(f9(c3),c4))), inference(mp, [status(thm)], [c7, s3, s4])).
fof(s5, plain, p2(f8(f8(f9(c4),c4),f9(c3)),f8(f9(c3),f8(f9(c4),c4))), inference(instantiate, [status(thm)], [c3])).
fof(s6, plain, p2(f8(f8(f9(c4),c4),f9(c3)),f8(f9(c3),f8(c4,f9(c4)))), inference(mp, [status(thm)], [c7, s5, lemma_6])).
fof(goal_1, theorem, p2(f8(f8(f9(c4),c4),f9(c3)),f8(f9(c4),f8(f9(c3),c4))), inference(mp, [status(thm)], [c7, s6, lemma_7])).
% SZS output end Proof
