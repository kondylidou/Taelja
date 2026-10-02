% SZS output start Proof
fof(skolem_definition, definition, ? [X21, X22, X23]: ~ ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23) => ~ ((esk1_0 = '==>'(esk1_0, esk2_0) & esk3_0 = '==>'(esk3_0, esk2_0)) => esk1_0 = esk3_0), introduced(definition, [new_symbols(definition, [esk1_0,esk3_0,esk2_0])], [])).
fof(sos_03, axiom, ! [X1]: '+'(X1, '0') = X1, file('Problems/LCL/LCL888+1.p', sos_03)).
fof(sos_02, axiom, ! [X1, X2]: '+'(X1, X2) = '+'(X2, X1), file('Problems/LCL/LCL888+1.p', sos_02)).
fof(sos_09, axiom, ! [X12, X13, X14]: ('>='(X12, X13) => '>='('+'(X12, X14), '+'(X13, X14))), file('Problems/LCL/LCL888+1.p', sos_09)).
fof(sos_08, axiom, ! [X1]: '>='(X1, '0'), file('Problems/LCL/LCL888+1.p', sos_08)).
fof(sos_07, axiom, ! [X9, X10, X11]: ('>='('+'(X9, X10), X11) <=> '>='(X10, '==>'(X9, X11))), file('Problems/LCL/LCL888+1.p', sos_07)).
fof(sos_12, axiom, ! [X1, X2]: '+'(X1, '==>'(X1, X2)) = '+'(X2, '==>'(X2, X1)), file('Problems/LCL/LCL888+1.p', sos_12)).
fof(sos_06, axiom, ! [X7, X8]: (('>='(X7, X8) & '>='(X8, X7)) => X7 = X8), file('Problems/LCL/LCL888+1.p', sos_06)).
fof(sos_01, axiom, ! [X1, X2, X3]: '+'('+'(X1, X2), X3) = '+'(X1, '+'(X2, X3)), file('Problems/LCL/LCL888+1.p', sos_01)).
fof(sos_05, axiom, ! [X4, X5, X6]: (('>='(X4, X5) & '>='(X5, X6)) => '>='(X4, X6)), file('Problems/LCL/LCL888+1.p', sos_05)).
fof(sos_04, axiom, ! [X1]: '>='(X1, X1), file('Problems/LCL/LCL888+1.p', sos_04)).
fof(c_0_37, assumption, esk3_0 = '==>'(esk3_0,esk2_0), introduced(assumption, [], [])).
fof(axiom_7, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [sos_07])).
fof(c_0_32, assumption, esk1_0 = '==>'(esk1_0,esk2_0), introduced(assumption, [], [])).
fof(s1, plain, ! [X] : '+'('0',X) = '+'(X,'0'), inference(instantiate, [status(thm)], [sos_02])).
fof(lemma_13, lemma, ! [X] : '+'('0',X) = X, inference(rewrite, [status(thm)], [sos_03, s1])).
fof(s2, plain, ! [X,Y] : '>='('+'(X,Y),'+'('0',Y)), inference(mp, [status(thm)], [sos_09, sos_08])).
fof(lemma_14, lemma, ! [X,Y] : '>='('+'(X,Y),Y), inference(rewrite, [status(thm)], [lemma_13, s2])).
fof(s3, plain, ! [X,Y] : '>='('+'('+'(X,'0'),Y),Y), inference(instantiate, [status(thm)], [lemma_14])).
fof(s4, plain, ! [X,Y] : '>='('+'(X,'+'('0',Y)),Y), inference(rewrite, [status(thm)], [sos_01, s3])).
fof(lemma_15, lemma, ! [X,Y] : '>='('+'(X,'+'(Y,'0')),Y), inference(rewrite, [status(thm)], [sos_02, s4])).
fof(s5, plain, ! [X,Y] : '>='('+'(X,'0'),'==>'(Y,X)), inference(mp, [status(thm)], [axiom_7, lemma_15])).
fof(lemma_16, lemma, ! [X,Y] : '>='('0','==>'(X,'==>'(Y,X))), inference(mp, [status(thm)], [axiom_7, s5])).
fof(s6, plain, ! [X,Y] : '>='('==>'(X,'==>'(Y,X)),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_17, lemma, ! [X,Y] : '==>'(X,'==>'(Y,X)) = '0', inference(mp, [status(thm)], [sos_06, s6, lemma_16])).
fof(lemma_18, lemma, ! [X,Y] : '>='(X,'==>'(Y,X)), inference(mp, [status(thm)], [axiom_7, lemma_14])).
fof(lemma_19, lemma, ! [X,Y] : '>='('+'(X,Y),X), inference(rewrite, [status(thm)], [sos_02, lemma_14])).
fof(s7, plain, ! [X] : '+'(X,'==>'(X,'0')) = '+'('0','==>'('0',X)), inference(instantiate, [status(thm)], [sos_12])).
fof(lemma_20, lemma, ! [X] : '+'(X,'==>'(X,'0')) = '==>'('0',X), inference(rewrite, [status(thm)], [lemma_13, s7])).
fof(s8, plain, ! [X,Y] : '+'(X,'+'('==>'(X,'0'),Y)) = '+'('+'(X,'==>'(X,'0')),Y), inference(instantiate, [status(thm)], [sos_01])).
fof(lemma_21, lemma, ! [X,Y] : '+'(X,'+'('==>'(X,'0'),Y)) = '+'('==>'('0',X),Y), inference(rewrite, [status(thm)], [lemma_20, s8])).
fof(s9, plain, ! [X,Y] : '>='('+'(X,'+'('==>'(X,'0'),Y)),X), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_22, lemma, ! [X,Y] : '>='('+'('==>'('0',X),Y),X), inference(rewrite, [status(thm)], [lemma_21, s9])).
fof(s10, plain, ! [X] : '>='('+'(X,'0'),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_23, lemma, ! [X] : '>='('0','==>'(X,'0')), inference(mp, [status(thm)], [axiom_7, s10])).
fof(s11, plain, ! [X] : '>='('==>'(X,'0'),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_24, lemma, ! [X] : '==>'(X,'0') = '0', inference(mp, [status(thm)], [sos_06, s11, lemma_23])).
fof(s12, plain, ! [X] : '==>'('0',X) = '+'(X,'==>'(X,'0')), inference(instantiate, [status(thm)], [lemma_20])).
fof(s13, plain, ! [X] : '==>'('0',X) = '+'(X,'0'), inference(rewrite, [status(thm)], [lemma_24, s12])).
fof(lemma_25, lemma, ! [X] : '==>'('0',X) = X, inference(rewrite, [status(thm)], [sos_03, s13])).
fof(s14, plain, '>='(esk2_0,'==>'(esk3_0,esk2_0)), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_26, lemma, '>='(esk2_0,esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37])], [c_0_37, s14])).
fof(s15, plain, '>='('+'('==>'('0',esk2_0),'0'),esk2_0), inference(instantiate, [status(thm)], [lemma_22])).
fof(s16, plain, '>='('+'('==>'('0',esk2_0),'0'),esk3_0), inference(mp, [status(thm), assumptions([c_0_37])], [sos_05, s15, lemma_26])).
fof(s17, plain, '>='('+'(esk2_0,'0'),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37])], [lemma_25, s16])).
fof(lemma_27, lemma, '>='('0','==>'(esk2_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37])], [axiom_7, s17])).
fof(s18, plain, '>='('==>'(esk2_0,esk3_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_28, lemma, '==>'(esk2_0,esk3_0) = '0', inference(mp, [status(thm), assumptions([c_0_37])], [sos_06, s18, lemma_27])).
fof(s19, plain, '+'(esk3_0,esk3_0) = '+'(esk3_0,'==>'(esk3_0,esk2_0)), inference(instantiate, [status(thm), assumptions([c_0_37])], [c_0_37])).
fof(s20, plain, '+'(esk3_0,esk3_0) = '+'(esk2_0,'==>'(esk2_0,esk3_0)), inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_12, s19])).
fof(s21, plain, '+'(esk3_0,esk3_0) = '+'(esk2_0,'0'), inference(rewrite, [status(thm), assumptions([c_0_37])], [lemma_28, s20])).
fof(lemma_29, lemma, '+'(esk3_0,esk3_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_03, s21])).
fof(s22, plain, ! [Y,X] : '>='('+'(Y,'==>'(Y,X)),Y), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_30, lemma, ! [X,Y] : '>='('+'(X,'==>'(X,Y)),Y), inference(rewrite, [status(thm)], [sos_12, s22])).
fof(s23, plain, ! [X,Y,Z] : '>='('+'('+'(X,'==>'(X,Y)),Z),'+'(Y,Z)), inference(mp, [status(thm)], [sos_09, lemma_30])).
fof(s24, plain, ! [X,Y,Z] : '>='('+'(X,'+'('==>'(X,Y),Z)),'+'(Y,Z)), inference(rewrite, [status(thm)], [sos_01, s23])).
fof(lemma_31, lemma, ! [X,Y,Z] : '>='('+'('==>'(X,Y),Z),'==>'(X,'+'(Y,Z))), inference(mp, [status(thm)], [axiom_7, s24])).
fof(s25, plain, '>='('+'('==>'(esk1_0,esk3_0),esk3_0),'==>'(esk1_0,'+'(esk3_0,esk3_0))), inference(instantiate, [status(thm)], [lemma_31])).
fof(s26, plain, '>='('+'('==>'(esk1_0,esk3_0),esk3_0),'==>'(esk1_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_37])], [lemma_29, s25])).
fof(s27, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_02, s26])).
fof(lemma_32, lemma, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32, c_0_37])], [c_0_32, s27])).
fof(s28, plain, '>='(esk2_0,'==>'(esk1_0,esk2_0)), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_33, lemma, '>='(esk2_0,esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32])], [c_0_32, s28])).
fof(s29, plain, '>='('+'('==>'('0',esk2_0),'0'),esk2_0), inference(instantiate, [status(thm)], [lemma_22])).
fof(s30, plain, '>='('+'('==>'('0',esk2_0),'0'),esk1_0), inference(mp, [status(thm), assumptions([c_0_32])], [sos_05, s29, lemma_33])).
fof(s31, plain, '>='('+'(esk2_0,'0'),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32])], [lemma_25, s30])).
fof(lemma_34, lemma, '>='('0','==>'(esk2_0,esk1_0)), inference(mp, [status(thm), assumptions([c_0_32])], [axiom_7, s31])).
fof(s32, plain, '>='('==>'(esk2_0,esk1_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_35, lemma, '==>'(esk2_0,esk1_0) = '0', inference(mp, [status(thm), assumptions([c_0_32])], [sos_06, s32, lemma_34])).
fof(s33, plain, '+'(esk1_0,esk1_0) = '+'(esk1_0,'==>'(esk1_0,esk2_0)), inference(instantiate, [status(thm), assumptions([c_0_32])], [c_0_32])).
fof(s34, plain, '+'(esk1_0,esk1_0) = '+'(esk2_0,'==>'(esk2_0,esk1_0)), inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_12, s33])).
fof(s35, plain, '+'(esk1_0,esk1_0) = '+'(esk2_0,'0'), inference(rewrite, [status(thm), assumptions([c_0_32])], [lemma_35, s34])).
fof(lemma_36, lemma, '+'(esk1_0,esk1_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_03, s35])).
fof(s36, plain, '>='('+'('==>'(esk3_0,esk1_0),esk1_0),'==>'(esk3_0,'+'(esk1_0,esk1_0))), inference(instantiate, [status(thm)], [lemma_31])).
fof(s37, plain, '>='('+'('==>'(esk3_0,esk1_0),esk1_0),'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_32])], [lemma_36, s36])).
fof(s38, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_02, s37])).
fof(lemma_37, lemma, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [c_0_37, s38])).
fof(lemma_38, lemma, '>='('==>'(esk1_0,esk3_0),'==>'(esk3_0,esk1_0)), inference(mp, [status(thm), assumptions([c_0_32, c_0_37])], [axiom_7, lemma_32])).
fof(s39, plain, '>='('==>'(esk3_0,esk1_0),'==>'(esk1_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [axiom_7, lemma_37])).
fof(lemma_39, lemma, '==>'(esk3_0,esk1_0) = '==>'(esk1_0,esk3_0), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [sos_06, s39, lemma_38])).
fof(s40, plain, '+'(esk1_0,esk3_0) = '+'(esk1_0,'+'(esk3_0,'0')), inference(instantiate, [status(thm)], [sos_03])).
fof(s41, plain, '+'(esk1_0,esk3_0) = '+'(esk1_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0)))), inference(rewrite, [status(thm)], [lemma_17, s40])).
fof(s42, plain, '+'(esk1_0,esk3_0) = '+'(esk1_0,'+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm)], [sos_12, s41])).
fof(s43, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk1_0,'==>'(esk1_0,esk3_0)),'==>'('==>'(esk1_0,esk3_0),esk3_0)), inference(rewrite, [status(thm)], [sos_01, s42])).
fof(s44, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk3_0,'==>'(esk3_0,esk1_0)),'==>'('==>'(esk1_0,esk3_0),esk3_0)), inference(rewrite, [status(thm)], [sos_12, s43])).
fof(s45, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'('==>'(esk3_0,esk1_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm)], [sos_01, s44])).
fof(s46, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_39, s45])).
fof(s47, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0)))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_12, s46])).
fof(s48, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk3_0,esk3_0),'==>'(esk3_0,'==>'(esk1_0,esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_01, s47])).
fof(s49, plain, '+'(esk1_0,esk3_0) = '+'(esk2_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_29, s48])).
fof(s50, plain, '+'(esk1_0,esk3_0) = '+'(esk2_0,'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_17, s49])).
fof(lemma_40, lemma, '+'(esk1_0,esk3_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_03, s50])).
fof(s51, plain, ! [Y,X] : '>='('+'(Y,X),'+'(Y,X)), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_41, lemma, ! [X,Y] : '>='(X,'==>'(Y,'+'(Y,X))), inference(mp, [status(thm)], [axiom_7, s51])).
fof(s52, plain, '>='(esk1_0,'==>'(esk3_0,'+'(esk3_0,esk1_0))), inference(instantiate, [status(thm)], [lemma_41])).
fof(s53, plain, '>='(esk1_0,'==>'(esk3_0,'+'(esk1_0,esk3_0))), inference(rewrite, [status(thm)], [sos_02, s52])).
fof(s54, plain, '>='(esk1_0,'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_40, s53])).
fof(lemma_42, lemma, '>='(esk1_0,esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [c_0_37, s54])).
fof(s55, plain, '>='('==>'(esk1_0,esk2_0),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_32, c_0_37])], [c_0_32, lemma_42])).
fof(lemma_43, lemma, '>='('==>'(esk1_0,'+'(esk1_0,esk3_0)),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_40, s55])).
fof(s56, plain, '>='(esk3_0,'==>'(esk1_0,'+'(esk1_0,esk3_0))), inference(instantiate, [status(thm)], [lemma_41])).
fof(s57, plain, esk3_0 = '==>'(esk1_0,'+'(esk1_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [sos_06, s56, lemma_43])).
fof(s58, plain, esk3_0 = '==>'(esk1_0,esk2_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_40, s57])).
fof(s59, plain, esk1_0 = esk3_0, inference(rewrite, [status(thm), assumptions([c_0_32, c_0_37])], [c_0_32, s58])).
fof(discharged, plain, ((esk3_0 = '==>'(esk3_0,esk2_0) & esk1_0 = '==>'(esk1_0,esk2_0)) => esk1_0 = esk3_0), inference(implies, [status(thm), discharge(implies, [c_0_37, c_0_32])], [s59, c_0_37, c_0_32])).
fof(goals_13, theorem, ! [X21, X22, X23]: ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
