% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p(X0, X1, X2, X3, X4) | p(X5, X1, X2, X3, X4)), file('PUZ056-2.005.p', rule1)).
fof(c_50, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p(X0, X1, X2, X3, X4) | ~ neq(X0, X1) | ~ neq(X0, X5) | p(X0, X5, X2, X3, X4)), file('PUZ056-2.005.p', rule2)).
fof(c_51, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p(X0, X1, X2, X3, X4) | ~ neq(X0, X2) | ~ neq(X0, X5) | ~ neq(X1, X2) | ~ neq(X1, X5) | p(X0, X1, X5, X3, X4)), file('PUZ056-2.005.p', rule3)).
fof(c_52, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p(X0, X1, X2, X3, X4) | ~ neq(X0, X3) | ~ neq(X0, X5) | ~ neq(X1, X3) | ~ neq(X1, X5) | ~ neq(X2, X3) | ~ neq(X2, X5) | p(X0, X1, X2, X5, X4)), file('PUZ056-2.005.p', rule4)).
fof(c_53, plain, ! [X0, X1, X2, X3, X4, X5]: (~ p(X0, X1, X2, X3, X4) | ~ neq(X0, X4) | ~ neq(X0, X5) | ~ neq(X1, X4) | ~ neq(X1, X5) | ~ neq(X2, X4) | ~ neq(X2, X5) | ~ neq(X3, X4) | ~ neq(X3, X5) | p(X0, X1, X2, X3, X5)), file('PUZ056-2.005.p', rule5)).
fof(c_55, plain, neq(s0, s1), file('PUZ056-2.005.p', neq2)).
fof(c_56, plain, neq(s0, s2), file('PUZ056-2.005.p', neq3)).
fof(c_57, plain, neq(s1, s0), file('PUZ056-2.005.p', neq4)).
fof(c_59, plain, neq(s1, s2), file('PUZ056-2.005.p', neq6)).
fof(c_60, plain, neq(s2, s0), file('PUZ056-2.005.p', neq7)).
fof(c_61, plain, neq(s2, s1), file('PUZ056-2.005.p', neq8)).
fof(c_63, plain, p(s0, s0, s0, s0, s0), file('PUZ056-2.005.p', init)).
fof(s1, plain, ! [X,Y,Z] : (p(s2,s0,X,Y,Z) => p(s2,s0,X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_13, lemma, ! [X,Y,Z] : (p(s2,s0,X,Y,Z) => p(s2,s1,X,Y,Z)), inference(mp, [status(thm)], [c_50, s1, c_60, c_61])).
fof(s2, plain, ! [X,Y,Z] : (p(s0,s1,X,Y,Z) => p(s0,s1,X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_14, lemma, ! [X,Y,Z] : (p(s0,s1,X,Y,Z) => p(s0,s2,X,Y,Z)), inference(mp, [status(thm)], [c_50, s2, c_55, c_56])).
fof(s3, plain, ! [X,Y] : (p(s2,s2,s1,X,Y) => p(s2,s2,s1,X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_15, lemma, ! [X,Y] : (p(s2,s2,s1,X,Y) => p(s2,s2,s0,X,Y)), inference(mp, [status(thm)], [c_51, s3, c_61, c_60, c_61, c_60])).
fof(s4, plain, ! [X,Y,Z] : (p(s1,s2,X,Y,Z) => p(s1,s2,X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_16, lemma, ! [X,Y,Z] : (p(s1,s2,X,Y,Z) => p(s1,s0,X,Y,Z)), inference(mp, [status(thm)], [c_50, s4, c_59, c_57])).
fof(s5, plain, p(s2,s0,s0,s0,s0), inference(mp, [status(thm)], [c_49, c_63])).
fof(s6, plain, p(s2,s1,s0,s0,s0), inference(mp, [status(thm)], [lemma_13, s5])).
fof(s7, plain, p(s1,s1,s0,s0,s0), inference(mp, [status(thm)], [c_49, s6])).
fof(s8, plain, p(s1,s1,s2,s0,s0), inference(mp, [status(thm)], [c_51, s7, c_57, c_59, c_57, c_59])).
fof(s9, plain, p(s2,s1,s2,s0,s0), inference(mp, [status(thm)], [c_49, s8])).
fof(s10, plain, p(s2,s0,s2,s0,s0), inference(mp, [status(thm)], [c_50, s9, c_61, c_60])).
fof(s11, plain, p(s0,s0,s2,s0,s0), inference(mp, [status(thm)], [c_49, s10])).
fof(s12, plain, p(s0,s0,s1,s0,s0), inference(mp, [status(thm)], [c_51, s11, c_56, c_55, c_56, c_55])).
fof(s13, plain, p(s2,s0,s1,s0,s0), inference(mp, [status(thm)], [c_49, s12])).
fof(s14, plain, p(s2,s1,s1,s0,s0), inference(mp, [status(thm)], [lemma_13, s13])).
fof(s15, plain, p(s1,s1,s1,s0,s0), inference(mp, [status(thm)], [c_49, s14])).
fof(s16, plain, p(s1,s1,s1,s2,s0), inference(mp, [status(thm)], [c_52, s15, c_57, c_59, c_57, c_59, c_57, c_59])).
fof(s17, plain, p(s0,s1,s1,s2,s0), inference(mp, [status(thm)], [c_49, s16])).
fof(s18, plain, p(s0,s2,s1,s2,s0), inference(mp, [status(thm)], [lemma_14, s17])).
fof(s19, plain, p(s2,s2,s1,s2,s0), inference(mp, [status(thm)], [c_49, s18])).
fof(s20, plain, p(s2,s2,s0,s2,s0), inference(mp, [status(thm)], [lemma_15, s19])).
fof(s21, plain, p(s1,s2,s0,s2,s0), inference(mp, [status(thm)], [c_49, s20])).
fof(s22, plain, p(s1,s0,s0,s2,s0), inference(mp, [status(thm)], [lemma_16, s21])).
fof(s23, plain, p(s0,s0,s0,s2,s0), inference(mp, [status(thm)], [c_49, s22])).
fof(s24, plain, p(s0,s0,s0,s1,s0), inference(mp, [status(thm)], [c_52, s23, c_56, c_55, c_56, c_55, c_56, c_55])).
fof(s25, plain, p(s1,s0,s0,s1,s0), inference(mp, [status(thm)], [c_49, s24])).
fof(s26, plain, p(s1,s2,s0,s1,s0), inference(mp, [status(thm)], [c_50, s25, c_57, c_59])).
fof(s27, plain, p(s2,s2,s0,s1,s0), inference(mp, [status(thm)], [c_49, s26])).
fof(s28, plain, p(s2,s2,s1,s1,s0), inference(mp, [status(thm)], [c_51, s27, c_60, c_61, c_60, c_61])).
fof(s29, plain, p(s0,s2,s1,s1,s0), inference(mp, [status(thm)], [c_49, s28])).
fof(s30, plain, p(s0,s1,s1,s1,s0), inference(mp, [status(thm)], [c_50, s29, c_56, c_55])).
fof(s31, plain, p(s1,s1,s1,s1,s0), inference(mp, [status(thm)], [c_49, s30])).
fof(s32, plain, p(s1,s1,s1,s1,s2), inference(mp, [status(thm)], [c_53, s31, c_57, c_59, c_57, c_59, c_57, c_59, c_57, c_59])).
fof(s33, plain, p(s0,s1,s1,s1,s2), inference(mp, [status(thm)], [c_49, s32])).
fof(s34, plain, p(s0,s2,s1,s1,s2), inference(mp, [status(thm)], [lemma_14, s33])).
fof(s35, plain, p(s2,s2,s1,s1,s2), inference(mp, [status(thm)], [c_49, s34])).
fof(s36, plain, p(s2,s2,s0,s1,s2), inference(mp, [status(thm)], [lemma_15, s35])).
fof(s37, plain, p(s1,s2,s0,s1,s2), inference(mp, [status(thm)], [c_49, s36])).
fof(s38, plain, p(s1,s0,s0,s1,s2), inference(mp, [status(thm)], [lemma_16, s37])).
fof(s39, plain, p(s0,s0,s0,s1,s2), inference(mp, [status(thm)], [c_49, s38])).
fof(s40, plain, p(s0,s0,s0,s2,s2), inference(mp, [status(thm)], [c_52, s39, c_55, c_56, c_55, c_56, c_55, c_56])).
fof(s41, plain, p(s2,s0,s0,s2,s2), inference(mp, [status(thm)], [c_49, s40])).
fof(s42, plain, p(s2,s1,s0,s2,s2), inference(mp, [status(thm)], [c_50, s41, c_60, c_61])).
fof(s43, plain, p(s1,s1,s0,s2,s2), inference(mp, [status(thm)], [c_49, s42])).
fof(s44, plain, p(s1,s1,s2,s2,s2), inference(mp, [status(thm)], [c_51, s43, c_57, c_59, c_57, c_59])).
fof(s45, plain, p(s0,s1,s2,s2,s2), inference(mp, [status(thm)], [c_49, s44])).
fof(s46, plain, p(s0,s2,s2,s2,s2), inference(mp, [status(thm)], [c_50, s45, c_55, c_56])).
fof(goal_1, theorem, p(s2,s2,s2,s2,s2), inference(mp, [status(thm)], [c_49, s46])).
% SZS output end Proof
