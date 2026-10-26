% SZS output start Proof
fof(c_49, plain, ! [X0]: p2(X0, X0), file('Problems/SYN/SYN558-1.p', p2_1)).
fof(c_50, plain, ! [X0]: p4(X0, X0), file('Problems/SYN/SYN558-1.p', p4_2)).
fof(c_51, plain, ! [X0]: p6(c7, f3(X0)), file('Problems/SYN/SYN558-1.p', p6_3)).
fof(c_52, plain, p5(c7, c10, c9), file('Problems/SYN/SYN558-1.p', p5_4)).
fof(c_53, plain, p5(c7, c10, c8), file('Problems/SYN/SYN558-1.p', p5_5)).
fof(c_54, plain, ! [X0]: p5(c7, X0, f3(X0)), file('Problems/SYN/SYN558-1.p', p5_6)).
fof(c_55, plain, ! [X0, X1]: (~ p2(X0, X1) | p2(f3(X0), f3(X1))), file('Problems/SYN/SYN558-1.p', p2_7)).
fof(c_59, plain, ! [X0, X1, X2, X3]: (~ p5(X0, X1, X2) | ~ p5(X0, X2, X3) | p5(X0, X1, X3)), file('Problems/SYN/SYN558-1.p', p5_11)).
fof(c_61, plain, ! [X0, X1, X2]: (~ p5(c7, X0, X1) | ~ p5(c7, X0, X2) | ~ p6(c7, X1) | ~ p6(c7, X2) | p2(X1, X2)), file('Problems/SYN/SYN558-1.p', p2_13)).
fof(c_62, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p5(X0, X1, X2) | ~ p2(X1, X3) | ~ p2(X2, X4) | ~ p4(X0, X5) | p5(X5, X3, X4)), file('Problems/SYN/SYN558-1.p', p5_14)).
fof(s1, plain, p5(c7,c9,f3(c9)), inference(instantiate, [status(thm)], [c_54])).
fof(lemma_11, lemma, p5(c7,c10,f3(c9)), inference(mp, [status(thm)], [c_59, c_52, s1])).
fof(s2, plain, p5(c7,c8,f3(c8)), inference(instantiate, [status(thm)], [c_54])).
fof(s3, plain, p5(c7,c10,f3(c8)), inference(mp, [status(thm)], [c_59, c_53, s2])).
fof(s4, plain, p6(c7,f3(c8)), inference(instantiate, [status(thm)], [c_51])).
fof(s5, plain, p6(c7,f3(c9)), inference(instantiate, [status(thm)], [c_51])).
fof(s6, plain, p2(f3(c8),f3(c9)), inference(mp, [status(thm)], [c_61, s3, lemma_11, s4, s5])).
fof(lemma_12, lemma, p2(f3(f3(c8)),f3(f3(c9))), inference(mp, [status(thm)], [c_55, s6])).
fof(s7, plain, p5(c7,c9,f3(c9)), inference(instantiate, [status(thm)], [c_54])).
fof(s8, plain, p5(c7,f3(c9),f3(f3(c9))), inference(instantiate, [status(thm)], [c_54])).
fof(goal_1, theorem, p5(c7,c9,f3(f3(c9))), inference(mp, [status(thm)], [c_59, s7, s8])).
fof(s9, plain, p5(c7,c8,f3(c8)), inference(instantiate, [status(thm)], [c_54])).
fof(s10, plain, p5(c7,f3(c8),f3(f3(c8))), inference(instantiate, [status(thm)], [c_54])).
fof(s11, plain, p5(c7,c8,f3(f3(c8))), inference(mp, [status(thm)], [c_59, s9, s10])).
fof(s12, plain, p2(c8,c8), inference(instantiate, [status(thm)], [c_49])).
fof(s13, plain, p4(c7,c7), inference(instantiate, [status(thm)], [c_50])).
fof(goal_2, theorem, p5(c7,c8,f3(f3(c9))), inference(mp, [status(thm)], [c_62, s11, s12, lemma_12, s13])).
% SZS output end Proof
