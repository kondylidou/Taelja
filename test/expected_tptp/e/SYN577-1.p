% SZS output start Proof
cnf(p2_12, negated_conjecture, p2(f5(f6(c9), c20), c18), file('Problems/SYN/SYN577-1.p', p2_12)).
cnf(p2_1, negated_conjecture, p2(X1, X1), file('Problems/SYN/SYN577-1.p', p2_1)).
cnf(p2_14, negated_conjecture, p2(X1, X2) | ~ p2(X3, X1) | ~ p2(X3, X2), file('Problems/SYN/SYN577-1.p', p2_14)).
cnf(p2_8, negated_conjecture, p2(f4(c16, c14), c18), file('Problems/SYN/SYN577-1.p', p2_8)).
cnf(p2_11, negated_conjecture, p2(f5(f6(c9), c19), c17), file('Problems/SYN/SYN577-1.p', p2_11)).
cnf(p2_9, negated_conjecture, p2(f4(c15, c14), c17), file('Problems/SYN/SYN577-1.p', p2_9)).
fof(s1, plain, p2(f4(c16,c14),f4(c16,c14)), inference(instantiate, [status(thm)], [p2_1])).
fof(lemma_7, lemma, p2(c18,f4(c16,c14)), inference(mp, [status(thm)], [p2_14, p2_8, s1])).
fof(s2, plain, p2(f4(c15,c14),f4(c15,c14)), inference(instantiate, [status(thm)], [p2_1])).
fof(lemma_8, lemma, p2(c17,f4(c15,c14)), inference(mp, [status(thm)], [p2_14, p2_9, s2])).
fof(goal_1, theorem, p2(c15,c15), inference(instantiate, [status(thm)], [p2_1])).
fof(s3, plain, p2(f5(f6(c9),c19),f5(f6(c9),c19)), inference(instantiate, [status(thm)], [p2_1])).
fof(s4, plain, p2(c17,f5(f6(c9),c19)), inference(mp, [status(thm)], [p2_14, p2_11, s3])).
fof(s5, plain, p2(f5(f6(c9),c19),f4(c15,c14)), inference(mp, [status(thm)], [p2_14, s4, lemma_8])).
fof(s6, plain, p2(f5(f6(c9),c19),f5(f6(c9),c19)), inference(instantiate, [status(thm)], [p2_1])).
fof(goal_2, theorem, p2(f4(c15,c14),f5(f6(c9),c19)), inference(mp, [status(thm)], [p2_14, s5, s6])).
fof(goal_3, theorem, p2(c16,c16), inference(instantiate, [status(thm)], [p2_1])).
fof(s7, plain, p2(f5(f6(c9),c20),f5(f6(c9),c20)), inference(instantiate, [status(thm)], [p2_1])).
fof(s8, plain, p2(c18,f5(f6(c9),c20)), inference(mp, [status(thm)], [p2_14, p2_12, s7])).
fof(s9, plain, p2(f5(f6(c9),c20),f4(c16,c14)), inference(mp, [status(thm)], [p2_14, s8, lemma_7])).
fof(s10, plain, p2(f5(f6(c9),c20),f5(f6(c9),c20)), inference(instantiate, [status(thm)], [p2_1])).
fof(goal_4, theorem, p2(f4(c16,c14),f5(f6(c9),c20)), inference(mp, [status(thm)], [p2_14, s9, s10])).
% SZS output end Proof
