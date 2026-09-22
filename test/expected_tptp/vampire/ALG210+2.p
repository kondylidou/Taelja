% SZS output start Proof
fof(f1, axiom, ! [X0, X1, X2]: times(times(X0, X1), X2) = times(X1, times(X2, X0)), file('Problems/ALG/ALG210+2.p')).
fof(f2, axiom, ! [X0]: (element(X0) <=> ? [X1]: (times(X0, X1) = X0 & times(X0, X0) = X1)), file('Problems/ALG/ALG210+2.p')).
fof(f9, definition, ! [X0]: (? [X2]: (times(X0, X2) = X0 & times(X0, X0) = X2) => (times(X0, sK0(X0)) = X0 & times(X0, X0) = sK0(X0))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f11, definition, ? [X0, X1, X2]: (~ element(X2) & element(X0) & element(X1) & X2 = times(X0, X1)) => (~ element(sK3) & element(sK1) & element(sK2) & sK3 = times(sK1, sK2)), introduced(definition, [new_symbols(definition, [sK3,sK1,sK2])], [])).
fof(f17, assumption, sK3 = times(sK1,sK2), introduced(assumption, [], [])).
fof(f19, assumption, element(sK1), introduced(assumption, [], [])).
fof(axiom_3, plain, ! [X] : (element(X) => times(X,sK0(X)) = X), inference(clausify, [status(thm)], [f2, f9])).
fof(axiom_4, plain, ! [X] : (element(X) => times(X,X) = sK0(X)), inference(clausify, [status(thm)], [f2, f9])).
fof(f18, assumption, element(sK2), introduced(assumption, [], [])).
fof(axiom_7, plain, ! [X,Y] : ((times(X,Y) = X & times(X,X) = Y) => element(X)), inference(clausify, [status(thm)], [f2, f9])).
fof(lemma_8, lemma, times(sK1,sK0(sK1)) = sK1, inference(mp, [status(thm), assumptions([f19])], [axiom_3, f19])).
fof(lemma_9, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s1, plain, ! [X] : times(sK1,X) = times(times(sK1,sK0(sK1)),X), inference(instantiate, [status(thm), assumptions([f19])], [lemma_8])).
fof(s2, plain, ! [X] : times(sK1,X) = times(times(sK1,times(sK1,sK1)),X), inference(rewrite, [status(thm), assumptions([f19])], [lemma_9, s1])).
fof(s3, plain, ! [X] : times(sK1,X) = times(times(times(sK1,sK1),sK1),X), inference(rewrite, [status(thm), assumptions([f19])], [f1, s2])).
fof(s4, plain, ! [X] : times(sK1,X) = times(times(sK0(sK1),sK1),X), inference(rewrite, [status(thm), assumptions([f19])], [lemma_9, s3])).
fof(lemma_10, lemma, ! [X] : times(sK1,X) = times(sK1,times(X,sK0(sK1))), inference(rewrite, [status(thm), assumptions([f19])], [f1, s4])).
fof(lemma_11, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s5, plain, ! [X,Y] : times(X,times(Y,sK3)) = times(X,times(Y,times(sK1,sK2))), inference(instantiate, [status(thm), assumptions([f17])], [f17])).
fof(s6, plain, ! [X,Y] : times(X,times(Y,sK3)) = times(times(times(sK1,sK2),X),Y), inference(rewrite, [status(thm), assumptions([f17])], [f1, s5])).
fof(s7, plain, ! [X,Y] : times(X,times(Y,sK3)) = times(times(sK2,times(X,sK1)),Y), inference(rewrite, [status(thm), assumptions([f17])], [f1, s6])).
fof(s8, plain, ! [X,Y] : times(X,times(Y,sK3)) = times(times(X,sK1),times(Y,sK2)), inference(rewrite, [status(thm), assumptions([f17])], [f1, s7])).
fof(s9, plain, ! [X,Y] : times(X,times(Y,sK3)) = times(sK1,times(times(Y,sK2),X)), inference(rewrite, [status(thm), assumptions([f17])], [f1, s8])).
fof(lemma_12, lemma, ! [X,Y] : times(X,times(Y,sK3)) = times(sK1,times(sK2,times(X,Y))), inference(rewrite, [status(thm), assumptions([f17])], [f1, s9])).
fof(s10, plain, ! [X] : times(sK2,times(X,sK1)) = times(times(sK1,sK2),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_13, lemma, ! [X] : times(sK2,times(X,sK1)) = times(sK3,X), inference(rewrite, [status(thm), assumptions([f17])], [f17, s10])).
fof(lemma_14, lemma, sK1 = times(sK1,sK0(sK1)), inference(mp, [status(thm), assumptions([f19])], [axiom_3, f19])).
fof(lemma_15, lemma, times(sK1,sK0(sK1)) = sK1, inference(mp, [status(thm), assumptions([f19])], [axiom_3, f19])).
fof(lemma_16, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s11, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(X,times(times(sK1,sK0(sK1)),Y)), inference(instantiate, [status(thm), assumptions([f19])], [lemma_15])).
fof(s12, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(X,times(sK0(sK1),times(Y,sK1))), inference(rewrite, [status(thm), assumptions([f19])], [f1, s11])).
fof(s13, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(times(times(Y,sK1),X),sK0(sK1)), inference(rewrite, [status(thm), assumptions([f19])], [f1, s12])).
fof(s14, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(times(sK1,times(X,Y)),sK0(sK1)), inference(rewrite, [status(thm), assumptions([f19])], [f1, s13])).
fof(s15, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(times(X,Y),times(sK0(sK1),sK1)), inference(rewrite, [status(thm), assumptions([f19])], [f1, s14])).
fof(s16, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(Y,times(times(sK0(sK1),sK1),X)), inference(rewrite, [status(thm), assumptions([f19])], [f1, s15])).
fof(s17, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(Y,times(times(times(sK1,sK1),sK1),X)), inference(rewrite, [status(thm), assumptions([f19])], [lemma_16, s16])).
fof(s18, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(Y,times(times(sK1,times(sK1,sK1)),X)), inference(rewrite, [status(thm), assumptions([f19])], [f1, s17])).
fof(s19, plain, ! [X,Y] : times(X,times(sK1,Y)) = times(Y,times(times(sK1,sK0(sK1)),X)), inference(rewrite, [status(thm), assumptions([f19])], [lemma_16, s18])).
fof(lemma_17, lemma, ! [X,Y] : times(X,times(sK1,Y)) = times(Y,times(sK1,X)), inference(rewrite, [status(thm), assumptions([f19])], [lemma_15, s19])).
fof(lemma_18, lemma, times(sK1,sK0(sK1)) = sK1, inference(mp, [status(thm), assumptions([f19])], [axiom_3, f19])).
fof(lemma_19, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s20, plain, sK1 = times(sK1,sK0(sK1)), inference(instantiate, [status(thm), assumptions([f19])], [lemma_18])).
fof(s21, plain, sK1 = times(sK1,times(sK1,sK1)), inference(rewrite, [status(thm), assumptions([f19])], [lemma_19, s20])).
fof(s22, plain, sK1 = times(times(sK1,sK1),sK1), inference(rewrite, [status(thm), assumptions([f19])], [f1, s21])).
fof(lemma_20, lemma, sK1 = times(sK0(sK1),sK1), inference(rewrite, [status(thm), assumptions([f19])], [lemma_19, s22])).
fof(lemma_21, lemma, sK2 = times(sK2,sK0(sK2)), inference(mp, [status(thm), assumptions([f18])], [axiom_3, f18])).
fof(lemma_22, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s23, plain, ! [X] : times(sK1,times(X,sK1)) = times(times(sK1,sK1),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_23, lemma, ! [X] : times(sK1,times(X,sK1)) = times(sK0(sK1),X), inference(rewrite, [status(thm), assumptions([f19])], [lemma_22, s23])).
fof(lemma_24, lemma, times(sK1,sK0(sK1)) = sK1, inference(mp, [status(thm), assumptions([f19])], [axiom_3, f19])).
fof(s24, plain, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(times(times(X,Y),sK1),sK0(sK1)), inference(instantiate, [status(thm)], [f1])).
fof(s25, plain, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(times(Y,times(sK1,X)),sK0(sK1)), inference(rewrite, [status(thm)], [f1, s24])).
fof(s26, plain, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(times(sK1,X),times(sK0(sK1),Y)), inference(rewrite, [status(thm)], [f1, s25])).
fof(s27, plain, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(X,times(times(sK0(sK1),Y),sK1)), inference(rewrite, [status(thm)], [f1, s26])).
fof(s28, plain, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(X,times(Y,times(sK1,sK0(sK1)))), inference(rewrite, [status(thm)], [f1, s27])).
fof(lemma_25, lemma, ! [X,Y] : times(sK1,times(sK0(sK1),times(X,Y))) = times(X,times(Y,sK1)), inference(rewrite, [status(thm), assumptions([f19])], [lemma_24, s28])).
fof(lemma_26, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s29, plain, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(times(times(X,Y),sK1),sK1), inference(instantiate, [status(thm)], [f1])).
fof(s30, plain, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(times(Y,times(sK1,X)),sK1), inference(rewrite, [status(thm)], [f1, s29])).
fof(s31, plain, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(times(sK1,X),times(sK1,Y)), inference(rewrite, [status(thm)], [f1, s30])).
fof(s32, plain, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(X,times(times(sK1,Y),sK1)), inference(rewrite, [status(thm)], [f1, s31])).
fof(s33, plain, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(X,times(Y,times(sK1,sK1))), inference(rewrite, [status(thm)], [f1, s32])).
fof(lemma_27, lemma, ! [X,Y] : times(sK1,times(sK1,times(X,Y))) = times(X,times(Y,sK0(sK1))), inference(rewrite, [status(thm), assumptions([f19])], [lemma_26, s33])).
fof(lemma_28, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([f19])], [axiom_4, f19])).
fof(s34, plain, times(sK3,sK1) = times(times(sK1,sK2),sK1), inference(instantiate, [status(thm), assumptions([f17])], [f17])).
fof(s35, plain, times(sK3,sK1) = times(sK2,times(sK1,sK1)), inference(rewrite, [status(thm), assumptions([f17])], [f1, s34])).
fof(lemma_29, lemma, times(sK3,sK1) = times(sK2,sK0(sK1)), inference(rewrite, [status(thm), assumptions([f19, f17])], [lemma_28, s35])).
fof(lemma_30, lemma, times(sK2,sK2) = sK0(sK2), inference(mp, [status(thm), assumptions([f18])], [axiom_4, f18])).
fof(s36, plain, ! [X] : times(sK2,times(X,sK2)) = times(times(sK2,sK2),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_31, lemma, ! [X] : times(sK2,times(X,sK2)) = times(sK0(sK2),X), inference(rewrite, [status(thm), assumptions([f18])], [lemma_30, s36])).
fof(s37, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(times(sK1,sK2),times(times(sK1,sK2),sK3)), inference(instantiate, [status(thm), assumptions([f17])], [f17])).
fof(s38, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(times(sK1,sK2),times(sK1,sK2)))), inference(rewrite, [status(thm), assumptions([f17])], [lemma_12, s37])).
fof(s39, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK3,times(sK1,sK2)))), inference(rewrite, [status(thm), assumptions([f17])], [f17, s38])).
fof(s40, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK2,times(times(sK1,sK2),sK1)))), inference(rewrite, [status(thm), assumptions([f17])], [lemma_13, s39])).
fof(s41, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK1,times(sK0(sK1),times(sK2,times(sK1,sK2)))))), inference(rewrite, [status(thm), assumptions([f19, f17])], [lemma_25, s40])).
fof(s42, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK1,times(sK0(sK1),times(sK0(sK2),sK1))))), inference(rewrite, [status(thm), assumptions([f18, f19, f17])], [lemma_31, s41])).
fof(s43, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK0(sK2),times(sK1,sK1)))), inference(rewrite, [status(thm), assumptions([f19, f18, f17])], [lemma_25, s42])).
fof(s44, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,times(sK0(sK2),sK0(sK1)))), inference(rewrite, [status(thm), assumptions([f19, f18, f17])], [lemma_11, s43])).
fof(s45, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK0(sK1),sK3)), inference(rewrite, [status(thm), assumptions([f17, f19, f18])], [lemma_12, s44])).
fof(s46, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK1,times(sK3,sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_23, s45])).
fof(s47, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK1,times(sK2,sK0(sK1)))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_29, s46])).
fof(s48, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK1,sK2)), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_10, s47])).
fof(s49, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(sK1,sK0(sK2))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s48])).
fof(s50, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(sK1,times(sK0(sK2),sK0(sK1)))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_10, s49])).
fof(s51, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(sK1,times(sK0(sK2),times(sK1,sK1)))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_11, s50])).
fof(s52, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(sK1,times(sK1,times(sK1,sK0(sK2))))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s51])).
fof(s53, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(times(sK1,sK0(sK2)),times(sK1,sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s52])).
fof(s54, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK2,times(times(sK1,sK0(sK2)),sK0(sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_11, s53])).
fof(s55, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK1,times(sK2,times(sK1,sK0(sK2))))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_27, s54])).
fof(s56, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK1,times(sK0(sK2),times(sK1,sK2)))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s55])).
fof(s57, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(times(sK1,sK2),sK0(sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_27, s56])).
fof(s58, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK2,times(sK0(sK1),sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [f1, s57])).
fof(s59, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK2,sK1)), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_20, s58])).
fof(s60, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK2,times(sK1,sK0(sK1)))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_14, s59])).
fof(s61, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(sK0(sK1),times(sK1,sK2))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s60])).
fof(s62, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK0(sK2),times(times(sK2,sK0(sK1)),sK1)), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [f1, s61])).
fof(s63, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(times(sK1,sK0(sK2)),times(sK2,sK0(sK1))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [f1, s62])).
fof(s64, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(times(sK0(sK1),times(sK1,sK0(sK2))),sK2), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [f1, s63])).
fof(s65, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(times(sK0(sK2),times(sK1,sK0(sK1))),sK2), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_17, s64])).
fof(s66, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(times(sK0(sK2),sK1),sK2), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [lemma_14, s65])).
fof(s67, plain, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,times(sK2,sK0(sK2))), inference(rewrite, [status(thm), assumptions([f19, f17, f18])], [f1, s66])).
fof(lemma_32, lemma, times(times(sK1,sK2),times(times(sK1,sK2),times(sK1,sK2))) = times(sK1,sK2), inference(rewrite, [status(thm), assumptions([f18, f19, f17])], [lemma_21, s67])).
fof(s68, plain, element(times(sK1,sK2)), inference(mp, [status(thm), assumptions([f18, f19, f17])], [axiom_7, lemma_32])).
fof(s69, plain, element(sK3), inference(rewrite, [status(thm), assumptions([f17, f18, f19])], [f17, s68])).
fof(f3, theorem, ! [X0, X1, X2]: ((element(X0) & element(X1) & X2 = times(X0, X1)) => element(X2)), inference(implies, [status(thm), discharge(implies, [f17, f19, f18])], [s69, f17, f19, f18])).
% SZS output end Proof
