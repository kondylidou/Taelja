% SZS output start Proof
cnf(p4_4, negated_conjecture, p4(f5(c7, c10, c9), c9), file('Problems/SYN/SYN555-1.p', p4_4)).
cnf(p4_6, negated_conjecture, p4(f5(c7, X1, c8), f5(c7, X1, c9)), file('Problems/SYN/SYN555-1.p', p4_6)).
cnf(p4_2, negated_conjecture, p4(X1, X1), file('Problems/SYN/SYN555-1.p', p4_2)).
cnf(p4_8, negated_conjecture, p4(X1, X2) | ~ p4(X3, X1) | ~ p4(X3, X2), file('Problems/SYN/SYN555-1.p', p4_8)).
cnf(p4_12, negated_conjecture, p4(f5(c7, X1, X2), X2) | ~ p4(f5(c7, X1, X3), X3) | ~ p4(f5(c7, f6(X1, X3, X2), X3), f5(c7, f6(X1, X3, X2), X2)), file('Problems/SYN/SYN555-1.p', p4_12)).
cnf(p2_1, negated_conjecture, p2(X1, X1), file('Problems/SYN/SYN555-1.p', p2_1)).
cnf(p3_3, negated_conjecture, p3(X1, X1), file('Problems/SYN/SYN555-1.p', p3_3)).
cnf(p4_11, negated_conjecture, p4(f5(X1, X2, X3), f5(X4, X5, X6)) | ~ p3(X2, X5) | ~ p4(X3, X6) | ~ p2(X1, X4), file('Problems/SYN/SYN555-1.p', p4_11)).
fof(s1, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c9)), inference(instantiate, [status(thm)], [p4_6])).
fof(s2, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c8)), inference(instantiate, [status(thm)], [p4_2])).
fof(lemma_9, lemma, p4(f5(c7,f6(c10,c9,c8),c9),f5(c7,f6(c10,c9,c8),c8)), inference(mp, [status(thm)], [p4_8, s1, s2])).
fof(goal_1, theorem, p4(f5(c7,c10,c8),c8), inference(mp, [status(thm)], [p4_12, p4_4, lemma_9])).
% SZS output end Proof
