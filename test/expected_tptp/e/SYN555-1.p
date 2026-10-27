% SZS output start Proof
cnf(p4_8, negated_conjecture, p4(X1, X2) | ~ p4(X3, X1) | ~ p4(X3, X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN555-1.p', p4_8)).
cnf(p4_2, negated_conjecture, p4(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN555-1.p', p4_2)).
cnf(p4_12, negated_conjecture, p4(f5(c7, X1, X2), X2) | ~ p4(f5(c7, X1, X3), X3) | ~ p4(f5(c7, f6(X1, X3, X2), X3), f5(c7, f6(X1, X3, X2), X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN555-1.p', p4_12)).
cnf(p4_6, negated_conjecture, p4(f5(c7, X1, c8), f5(c7, X1, c9)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN555-1.p', p4_6)).
cnf(p4_4, negated_conjecture, p4(f5(c7, c10, c9), c9), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN555-1.p', p4_4)).
fof(s1, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c9)), inference(instantiate, [status(thm)], [p4_6])).
fof(s2, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c8)), inference(instantiate, [status(thm)], [p4_2])).
fof(lemma_6, lemma, p4(f5(c7,f6(c10,c9,c8),c9),f5(c7,f6(c10,c9,c8),c8)), inference(mp, [status(thm)], [p4_8, s1, s2])).
fof(goal_1, theorem, p4(f5(c7,c10,c8),c8), inference(mp, [status(thm)], [p4_12, p4_4, lemma_6])).
% SZS output end Proof
