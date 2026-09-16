% SZS output start Proof
fof(f1, negated_conjecture, ! [X0]: p2(X0, X0), file('Problems/SYN/SYN558-1.p')).
fof(f2, negated_conjecture, ! [X0]: p4(X0, X0), file('Problems/SYN/SYN558-1.p')).
fof(f3, negated_conjecture, ! [X0]: p6(c7, f3(X0)), file('Problems/SYN/SYN558-1.p')).
fof(f4, negated_conjecture, p5(c7, c10, c9), file('Problems/SYN/SYN558-1.p')).
fof(f5, negated_conjecture, p5(c7, c10, c8), file('Problems/SYN/SYN558-1.p')).
fof(f6, negated_conjecture, ! [X0]: p5(c7, X0, f3(X0)), file('Problems/SYN/SYN558-1.p')).
fof(f9, negated_conjecture, ! [X2, X0, X1]: (~ p2(X2, X1) | ~ p2(X2, X0) | p2(X0, X1)), file('Problems/SYN/SYN558-1.p')).
fof(f11, negated_conjecture, ! [X2, X3, X0, X1]: (~ p5(X0, X3, X2) | ~ p5(X0, X1, X3) | p5(X0, X1, X2)), file('Problems/SYN/SYN558-1.p')).
fof(f13, negated_conjecture, ! [X2, X0, X1]: (~ p5(c7, X2, X1) | ~ p6(c7, X1) | ~ p6(c7, X0) | p2(X0, X1) | ~ p5(c7, X2, X0)), file('Problems/SYN/SYN558-1.p')).
fof(f14, negated_conjecture, ! [X2, X3, X0, X1, X4, X5]: (~ p5(X5, X3, X4) | ~ p2(X3, X1) | ~ p2(X4, X2) | ~ p4(X5, X0) | p5(X0, X1, X2)), file('Problems/SYN/SYN558-1.p')).
fof(s1, plain, p5(c7,c8,f3(c8)), inference(instantiate, [status(thm)], [f6])).
fof(lemma_11, lemma, p5(c7,c10,f3(c8)), inference(mp, [status(thm)], [f11, s1, f5])).
fof(s2, plain, p5(c7,c10,f3(c10)), inference(instantiate, [status(thm)], [f6])).
fof(s3, plain, p6(c7,f3(c10)), inference(instantiate, [status(thm)], [f3])).
fof(s4, plain, p6(c7,f3(c8)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_12, lemma, p2(f3(c8),f3(c10)), inference(mp, [status(thm)], [f13, s2, s3, s4, lemma_11])).
fof(s5, plain, p5(c7,c9,f3(c9)), inference(instantiate, [status(thm)], [f6])).
fof(lemma_13, lemma, p5(c7,c10,f3(c9)), inference(mp, [status(thm)], [f11, s5, f4])).
fof(s6, plain, p5(c7,c10,f3(c10)), inference(instantiate, [status(thm)], [f6])).
fof(s7, plain, p6(c7,f3(c10)), inference(instantiate, [status(thm)], [f3])).
fof(s8, plain, p6(c7,f3(c9)), inference(instantiate, [status(thm)], [f3])).
fof(lemma_14, lemma, p2(f3(c9),f3(c10)), inference(mp, [status(thm)], [f13, s6, s7, s8, lemma_13])).
fof(s9, plain, p2(f3(c8),f3(c8)), inference(instantiate, [status(thm)], [f1])).
fof(lemma_15, lemma, p2(f3(c10),f3(c8)), inference(mp, [status(thm)], [f9, s9, lemma_12])).
fof(s10, plain, p2(f3(c9),f3(c9)), inference(instantiate, [status(thm)], [f1])).
fof(s11, plain, p2(f3(c10),f3(c9)), inference(mp, [status(thm)], [f9, s10, lemma_14])).
fof(lemma_16, lemma, p2(f3(c8),f3(c9)), inference(mp, [status(thm)], [f9, s11, lemma_15])).
fof(s12, plain, p2(f3(c8),f3(c8)), inference(instantiate, [status(thm)], [f1])).
fof(lemma_17, lemma, p2(f3(c9),f3(c8)), inference(mp, [status(thm)], [f9, s12, lemma_16])).
fof(s13, plain, p5(c7,f3(c9),f3(f3(c9))), inference(instantiate, [status(thm)], [f6])).
fof(s14, plain, p5(c7,c9,f3(c9)), inference(instantiate, [status(thm)], [f6])).
fof(lemma_18, lemma, p5(c7,c9,f3(f3(c9))), inference(mp, [status(thm)], [f11, s13, s14])).
fof(s15, plain, p5(c7,f3(c9),f3(f3(c9))), inference(instantiate, [status(thm)], [f6])).
fof(s16, plain, p2(f3(f3(c9)),f3(f3(c9))), inference(instantiate, [status(thm)], [f1])).
fof(s17, plain, p4(c7,c7), inference(instantiate, [status(thm)], [f2])).
fof(s18, plain, p5(c7,f3(c8),f3(f3(c9))), inference(mp, [status(thm)], [f14, s15, lemma_17, s16, s17])).
fof(s19, plain, p5(c7,c8,f3(c8)), inference(instantiate, [status(thm)], [f6])).
fof(lemma_19, lemma, p5(c7,c8,f3(f3(c9))), inference(mp, [status(thm)], [f11, s18, s19])).
fof(s20, plain, p5(c7,f3(f3(c9)),f3(f3(f3(c9)))), inference(instantiate, [status(thm)], [f6])).
fof(goal_1, theorem, p5(c7,c8,f3(f3(f3(c9)))), inference(mp, [status(thm)], [f11, s20, lemma_19])).
fof(s21, plain, p5(c7,f3(f3(c9)),f3(f3(f3(c9)))), inference(instantiate, [status(thm)], [f6])).
fof(goal_2, theorem, p5(c7,c9,f3(f3(f3(c9)))), inference(mp, [status(thm)], [f11, s21, lemma_18])).
% SZS output end Proof
