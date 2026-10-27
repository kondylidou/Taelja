% SZS output start Proof
cnf(p2_14, negated_conjecture, p2(X1, X2) | ~ p2(X3, X1) | ~ p2(X3, X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_14)).
cnf(p2_1, negated_conjecture, p2(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_1)).
cnf(p2_12, negated_conjecture, p2(f5(f6(c9), c20), c18), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_12)).
cnf(p2_9, negated_conjecture, p2(f4(c15, c14), c17), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_9)).
cnf(p7_5, negated_conjecture, p7(c9, c10), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p7_5)).
cnf(p2_11, negated_conjecture, p2(f5(f6(c9), c19), c17), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_11)).
cnf(p2_8, negated_conjecture, p2(f4(c16, c14), c18), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN577-1.p', p2_8)).
fof(s1, plain, ! [X,Y] : (p2(X,Y) => p2(X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_8, lemma, ! [X,Y] : (p2(X,Y) => p2(Y,X)), inference(mp, [status(thm)], [p2_14, s1, p2_1])).
fof(lemma_9, lemma, p2(c17,f4(c15,c14)), inference(mp, [status(thm)], [lemma_8, p2_9])).
fof(lemma_10, lemma, p2(c18,f5(f6(c9),c20)), inference(mp, [status(thm)], [lemma_8, p2_12])).
fof(goal_1, theorem, p7(c9,c10), inference(instantiate, [status(thm)], [p7_5])).
fof(goal_2, theorem, p2(c15,c15), inference(instantiate, [status(thm)], [p2_1])).
fof(goal_3, theorem, p2(c16,c16), inference(instantiate, [status(thm)], [p2_1])).
fof(s2, plain, p2(c17,f5(f6(c9),c19)), inference(mp, [status(thm)], [lemma_8, p2_11])).
fof(s3, plain, p2(f5(f6(c9),c19),f4(c15,c14)), inference(mp, [status(thm)], [p2_14, s2, lemma_9])).
fof(goal_4, theorem, p2(f4(c15,c14),f5(f6(c9),c19)), inference(mp, [status(thm)], [lemma_8, s3])).
fof(s4, plain, p2(c18,f4(c16,c14)), inference(mp, [status(thm)], [lemma_8, p2_8])).
fof(goal_5, theorem, p2(f4(c16,c14),f5(f6(c9),c20)), inference(mp, [status(thm)], [p2_14, s4, lemma_10])).
% SZS output end Proof
