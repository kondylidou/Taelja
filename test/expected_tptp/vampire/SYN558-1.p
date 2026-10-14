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
fof(s1, plain, ! [X,Y] : (p5(c7,X,Y) => p5(c7,X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_11, lemma, ! [X,Y] : (p5(c7,X,Y) => p5(c7,X,f3(Y))), inference(mp, [status(thm)], [f11, f6, s1])).
fof(s2, plain, ! [X,Y,Z] : ((p5(c7,X,Y) & p2(f3(Y),Z)) => p5(c7,X,f3(Y))), inference(instantiate, [status(thm)], [lemma_11])).
fof(s3, plain, ! [X,Y,Z] : ((p5(c7,X,Y) & p2(f3(Y),Z)) => p2(f3(Y),f3(X))), inference(mp, [status(thm)], [f13, f6, f3, f3, s2])).
fof(s4, plain, ! [X,Y,Z] : ((p5(c7,X,Y) & p2(f3(Y),Z)) => p2(f3(Y),Z)), inference(assumption, [status(thm)], [])).
fof(lemma_12, lemma, ! [X,Y,Z] : ((p5(c7,X,Y) & p2(f3(Y),Z)) => p2(Z,f3(X))), inference(mp, [status(thm)], [f9, s3, s4])).
fof(s5, plain, ! [X,Y] : (p2(X,Y) => p2(X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_13, lemma, ! [X,Y] : (p2(X,Y) => p2(Y,X)), inference(mp, [status(thm)], [f9, f1, s5])).
fof(s6, plain, p2(f3(c8),f3(c8)), inference(instantiate, [status(thm)], [f1])).
fof(s7, plain, p2(f3(c8),f3(c10)), inference(mp, [status(thm)], [lemma_12, f5, s6])).
fof(lemma_14, lemma, p2(f3(c10),f3(c8)), inference(mp, [status(thm)], [lemma_13, s7])).
fof(s8, plain, p2(f3(c9),f3(c9)), inference(instantiate, [status(thm)], [f1])).
fof(s9, plain, p2(f3(c9),f3(c10)), inference(mp, [status(thm)], [lemma_12, f4, s8])).
fof(s10, plain, p2(f3(c10),f3(c9)), inference(mp, [status(thm)], [lemma_13, s9])).
fof(s11, plain, p2(f3(c8),f3(c9)), inference(mp, [status(thm)], [f9, s10, lemma_14])).
fof(lemma_15, lemma, p2(f3(c9),f3(c8)), inference(mp, [status(thm)], [lemma_13, s11])).
fof(s12, plain, p5(c7,f3(c9),f3(f3(c9))), inference(instantiate, [status(thm)], [f6])).
fof(s13, plain, p2(f3(f3(c9)),f3(f3(c9))), inference(instantiate, [status(thm)], [f1])).
fof(s14, plain, p4(c7,c7), inference(instantiate, [status(thm)], [f2])).
fof(s15, plain, p5(c7,f3(c8),f3(f3(c9))), inference(mp, [status(thm)], [f14, s12, lemma_15, s13, s14])).
fof(s16, plain, p5(c7,c8,f3(c8)), inference(instantiate, [status(thm)], [f6])).
fof(s17, plain, p5(c7,c8,f3(f3(c9))), inference(mp, [status(thm)], [f11, s15, s16])).
fof(goal_1, theorem, p5(c7,c8,f3(f3(f3(c9)))), inference(mp, [status(thm)], [lemma_11, s17])).
fof(s18, plain, p5(c7,f3(c9),f3(f3(c9))), inference(instantiate, [status(thm)], [f6])).
fof(s19, plain, p5(c7,c9,f3(c9)), inference(instantiate, [status(thm)], [f6])).
fof(s20, plain, p5(c7,c9,f3(f3(c9))), inference(mp, [status(thm)], [f11, s18, s19])).
fof(goal_2, theorem, p5(c7,c9,f3(f3(f3(c9)))), inference(mp, [status(thm)], [lemma_11, s20])).
% SZS output end Proof
