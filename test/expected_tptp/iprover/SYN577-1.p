% SZS output start Proof
fof(c_49, plain, ! [X0]: p2(X0, X0), file('Problems/SYN/SYN577-1.p', p2_1)).
fof(c_53, plain, p7(c9, c10), file('Problems/SYN/SYN577-1.p', p7_5)).
fof(c_56, plain, p2(f4(c16, c14), c18), file('Problems/SYN/SYN577-1.p', p2_8)).
fof(c_57, plain, p2(f4(c15, c14), c17), file('Problems/SYN/SYN577-1.p', p2_9)).
fof(c_59, plain, p2(f5(f6(c9), c19), c17), file('Problems/SYN/SYN577-1.p', p2_11)).
fof(c_60, plain, p2(f5(f6(c9), c20), c18), file('Problems/SYN/SYN577-1.p', p2_12)).
fof(c_62, plain, ! [X0, X1, X2]: (~ p2(X0, X1) | ~ p2(X0, X2) | p2(X1, X2)), file('Problems/SYN/SYN577-1.p', p2_14)).
fof(s1, plain, p2(f5(f6(c9),c19),f5(f6(c9),c19)), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_8, lemma, p2(c17,f5(f6(c9),c19)), inference(mp, [status(thm)], [c_62, c_59, s1])).
fof(s2, plain, p2(f5(f6(c9),c20),f5(f6(c9),c20)), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_9, lemma, p2(c18,f5(f6(c9),c20)), inference(mp, [status(thm)], [c_62, c_60, s2])).
fof(s3, plain, p2(f4(c15,c14),f4(c15,c14)), inference(instantiate, [status(thm)], [c_49])).
fof(s4, plain, p2(c17,f4(c15,c14)), inference(mp, [status(thm)], [c_62, c_57, s3])).
fof(goal_1, theorem, p2(f4(c15,c14),f5(f6(c9),c19)), inference(mp, [status(thm)], [c_62, s4, lemma_8])).
fof(s5, plain, p2(f4(c16,c14),f4(c16,c14)), inference(instantiate, [status(thm)], [c_49])).
fof(s6, plain, p2(c18,f4(c16,c14)), inference(mp, [status(thm)], [c_62, c_56, s5])).
fof(goal_2, theorem, p2(f4(c16,c14),f5(f6(c9),c20)), inference(mp, [status(thm)], [c_62, s6, lemma_9])).
fof(goal_3, theorem, p2(c15,c15), inference(instantiate, [status(thm)], [c_49])).
fof(goal_4, theorem, p2(c16,c16), inference(instantiate, [status(thm)], [c_49])).
fof(goal_5, theorem, p7(c9,c10), inference(instantiate, [status(thm)], [c_53])).
% SZS output end Proof
