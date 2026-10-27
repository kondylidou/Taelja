% SZS output start Proof
fof(skolem_definition, definition, ? [X21, X22, X23]: ~ ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23) => ~ ((esk1_0 = '==>'(esk1_0, esk2_0) & esk3_0 = '==>'(esk3_0, esk2_0)) => esk1_0 = esk3_0), introduced(definition, [new_symbols(definition, [esk1_0,esk3_0,esk2_0])], [])).
fof(sos_06, axiom, ! [X7, X8]: (('>='(X7, X8) & '>='(X8, X7)) => X7 = X8), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_06)).
fof(sos_08, axiom, ! [X1]: '>='(X1, '0'), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_08)).
fof(sos_07, axiom, ! [X9, X10, X11]: ('>='('+'(X9, X10), X11) <=> '>='(X10, '==>'(X9, X11))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_07)).
fof(sos_03, axiom, ! [X1]: '+'(X1, '0') = X1, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_03)).
fof(sos_02, axiom, ! [X1, X2]: '+'(X1, X2) = '+'(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_02)).
fof(sos_09, axiom, ! [X12, X13, X14]: ('>='(X12, X13) => '>='('+'(X12, X14), '+'(X13, X14))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_09)).
fof(sos_12, axiom, ! [X1, X2]: '+'(X1, '==>'(X1, X2)) = '+'(X2, '==>'(X2, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_12)).
fof(sos_04, axiom, ! [X1]: '>='(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_04)).
fof(sos_01, axiom, ! [X1, X2, X3]: '+'('+'(X1, X2), X3) = '+'(X1, '+'(X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_01)).
fof(sos_10, axiom, ! [X15, X16, X17]: ('>='(X15, X16) => '>='('==>'(X16, X17), '==>'(X15, X17))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL888+1.p', sos_10)).
fof(axiom_5, plain, ! [X,Y,Z] : ('>='(X,'==>'(Y,Z)) => '>='('+'(Y,X),Z)), inference(clausify, [status(thm)], [sos_07])).
fof(axiom_6, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [sos_07])).
fof(c_0_44, assumption, esk3_0 = '==>'(esk3_0,esk2_0), introduced(assumption, [], [])).
fof(c_0_36, assumption, esk1_0 = '==>'(esk1_0,esk2_0), introduced(assumption, [], [])).
fof(s1, plain, ! [X] : ('>='('0',X) => '>='('0',X)), inference(assumption, [status(thm)], [])).
fof(lemma_14, lemma, ! [X] : ('>='('0',X) => '0' = X), inference(mp, [status(thm)], [sos_06, sos_08, s1])).
fof(s2, plain, ! [X] : '+'('0',X) = '+'(X,'0'), inference(instantiate, [status(thm)], [sos_02])).
fof(lemma_15, lemma, ! [X] : '+'('0',X) = X, inference(rewrite, [status(thm)], [sos_03, s2])).
fof(s3, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='('+'(X,Z),Y)), inference(assumption, [status(thm)], [])).
fof(s4, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='(Z,'==>'(X,Y))), inference(mp, [status(thm)], [axiom_6, s3])).
fof(s5, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='('==>'(X,Y),Z)), inference(assumption, [status(thm)], [])).
fof(lemma_16, lemma, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '==>'(X,Y) = Z), inference(mp, [status(thm)], [sos_06, s4, s5])).
fof(s6, plain, ! [X] : '>='('+'(X,'0'),'+'(X,'0')), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_17, lemma, ! [X] : '>='('+'('0','+'(X,'0')),'+'(X,'0')), inference(rewrite, [status(thm)], [lemma_15, s6])).
fof(s7, plain, ! [X] : '>='('==>'('0','+'(X,'0')),'==>'('0','+'(X,'0'))), inference(instantiate, [status(thm)], [sos_04])).
fof(s8, plain, ! [X] : '>='('+'('0','==>'('0','+'(X,'0'))),'+'(X,'0')), inference(mp, [status(thm)], [axiom_5, s7])).
fof(s9, plain, ! [X] : '>='('==>'('0','+'(X,'0')),'+'(X,'0')), inference(rewrite, [status(thm)], [lemma_15, s8])).
fof(lemma_18, lemma, ! [X] : '==>'('0','+'(X,'0')) = '+'(X,'0'), inference(mp, [status(thm)], [lemma_16, s9, lemma_17])).
fof(s10, plain, ! [X,Y] : '>='('==>'('0','+'(X,'0')),'==>'(Y,'+'(X,'0'))), inference(mp, [status(thm)], [sos_10, sos_08])).
fof(s11, plain, ! [X,Y] : '>='('+'(X,'0'),'==>'(Y,'+'(X,'0'))), inference(rewrite, [status(thm)], [lemma_18, s10])).
fof(s12, plain, ! [X,Y] : '>='('0','==>'(X,'==>'(Y,'+'(X,'0')))), inference(mp, [status(thm)], [axiom_6, s11])).
fof(s13, plain, ! [X,Y] : '>='('0','==>'(X,'==>'(Y,X))), inference(rewrite, [status(thm)], [sos_03, s12])).
fof(lemma_19, lemma, ! [X,Y] : '==>'(X,'==>'(Y,X)) = '0', inference(mp, [status(thm)], [lemma_14, s13])).
fof(s14, plain, ! [X,Y] : '>='('+'(X,Y),'+'('0',Y)), inference(mp, [status(thm)], [sos_09, sos_08])).
fof(lemma_20, lemma, ! [X,Y] : '>='('+'(X,Y),Y), inference(rewrite, [status(thm)], [lemma_15, s14])).
fof(s15, plain, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'('+'(X,Y),Z), inference(instantiate, [status(thm)], [sos_01])).
fof(lemma_21, lemma, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'(Z,'+'(X,Y)), inference(rewrite, [status(thm)], [sos_02, s15])).
fof(s16, plain, ! [X,Y,Z] : '+'(X,'+'('==>'(X,Y),Z)) = '+'('+'(X,'==>'(X,Y)),Z), inference(instantiate, [status(thm)], [sos_01])).
fof(s17, plain, ! [X,Y,Z] : '+'(X,'+'('==>'(X,Y),Z)) = '+'('+'(Y,'==>'(Y,X)),Z), inference(rewrite, [status(thm)], [sos_12, s16])).
fof(lemma_22, lemma, ! [X,Y,Z] : '+'(X,'+'('==>'(X,Y),Z)) = '+'(Y,'+'('==>'(Y,X),Z)), inference(rewrite, [status(thm)], [sos_01, s17])).
fof(s18, plain, ! [X] : ('>='('+'(esk3_0,X),esk2_0) => '>='('+'(esk3_0,X),esk2_0)), inference(assumption, [status(thm)], [])).
fof(s19, plain, ! [X] : ('>='('+'(esk3_0,X),esk2_0) => '>='(X,'==>'(esk3_0,esk2_0))), inference(mp, [status(thm)], [axiom_6, s18])).
fof(lemma_23, lemma, ! [X] : ('>='('+'(esk3_0,X),esk2_0) => '>='(X,esk3_0)), inference(rewrite, [status(thm), assumptions([c_0_44])], [c_0_44, s19])).
fof(s20, plain, ! [X] : ('>='('+'(esk1_0,X),esk2_0) => '>='('+'(esk1_0,X),esk2_0)), inference(assumption, [status(thm)], [])).
fof(s21, plain, ! [X] : ('>='('+'(esk1_0,X),esk2_0) => '>='(X,'==>'(esk1_0,esk2_0))), inference(mp, [status(thm)], [axiom_6, s20])).
fof(lemma_24, lemma, ! [X] : ('>='('+'(esk1_0,X),esk2_0) => '>='(X,esk1_0)), inference(rewrite, [status(thm), assumptions([c_0_36])], [c_0_36, s21])).
fof(s22, plain, ! [X,Y] : ('>='(X,Y) => '>='(X,Y)), inference(assumption, [status(thm)], [])).
fof(s23, plain, ! [X,Y] : ('>='(X,Y) => '>='('+'(X,'0'),Y)), inference(rewrite, [status(thm)], [sos_03, s22])).
fof(s24, plain, ! [X,Y] : ('>='(X,Y) => '>='('0','==>'(X,Y))), inference(mp, [status(thm)], [axiom_6, s23])).
fof(lemma_25, lemma, ! [X,Y] : ('>='(X,Y) => '0' = '==>'(X,Y)), inference(mp, [status(thm)], [lemma_14, s24])).
fof(s25, plain, ! [X,Y] : ('>='(X,Y) => '+'(X,'0') = '+'(Y,'==>'(Y,X))), inference(rewrite, [status(thm)], [lemma_25, sos_12])).
fof(lemma_26, lemma, ! [X,Y] : ('>='(X,Y) => '+'(Y,'==>'(Y,X)) = X), inference(rewrite, [status(thm)], [sos_03, s25])).
fof(s26, plain, '>='('+'(esk3_0,esk2_0),esk2_0), inference(instantiate, [status(thm)], [lemma_20])).
fof(s27, plain, '>='(esk2_0,esk3_0), inference(mp, [status(thm), assumptions([c_0_44])], [lemma_23, s26])).
fof(s28, plain, '+'(esk3_0,'==>'(esk3_0,esk2_0)) = esk2_0, inference(mp, [status(thm), assumptions([c_0_44])], [lemma_26, s27])).
fof(lemma_27, lemma, '+'(esk3_0,esk3_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_44])], [c_0_44, s28])).
fof(s29, plain, ! [X,Y] : ('>='('+'(X,'+'('==>'(X,esk1_0),Y)),esk2_0) => '>='('+'(X,'+'('==>'(X,esk1_0),Y)),esk2_0)), inference(assumption, [status(thm)], [])).
fof(s30, plain, ! [X,Y] : ('>='('+'(X,'+'('==>'(X,esk1_0),Y)),esk2_0) => '>='('+'(esk1_0,'+'('==>'(esk1_0,X),Y)),esk2_0)), inference(rewrite, [status(thm)], [lemma_22, s29])).
fof(lemma_28, lemma, ! [X,Y] : ('>='('+'(X,'+'('==>'(X,esk1_0),Y)),esk2_0) => '>='('+'('==>'(esk1_0,X),Y),esk1_0)), inference(mp, [status(thm), assumptions([c_0_36])], [lemma_24, s30])).
fof(s31, plain, '>='('+'(esk1_0,esk2_0),esk2_0), inference(instantiate, [status(thm)], [lemma_20])).
fof(s32, plain, '>='(esk2_0,esk1_0), inference(mp, [status(thm), assumptions([c_0_36])], [lemma_24, s31])).
fof(s33, plain, '+'(esk1_0,'==>'(esk1_0,esk2_0)) = esk2_0, inference(mp, [status(thm), assumptions([c_0_36])], [lemma_26, s32])).
fof(lemma_29, lemma, '+'(esk1_0,esk1_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_36])], [c_0_36, s33])).
fof(s34, plain, '>='('+'('==>'(esk3_0,esk1_0),esk2_0),esk2_0), inference(instantiate, [status(thm)], [lemma_20])).
fof(s35, plain, '>='('+'('==>'(esk3_0,esk1_0),'+'(esk3_0,esk3_0)),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44])], [lemma_27, s34])).
fof(s36, plain, '>='('+'(esk3_0,'+'('==>'(esk3_0,esk1_0),esk3_0)),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44])], [lemma_21, s35])).
fof(s37, plain, '>='('+'('==>'(esk1_0,esk3_0),esk3_0),esk1_0), inference(mp, [status(thm), assumptions([c_0_36, c_0_44])], [lemma_28, s36])).
fof(lemma_30, lemma, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_36, c_0_44])], [sos_02, s37])).
fof(s38, plain, '>='('+'('==>'(esk1_0,esk3_0),esk2_0),esk2_0), inference(instantiate, [status(thm)], [lemma_20])).
fof(s39, plain, '>='('+'('==>'(esk1_0,esk3_0),'+'(esk1_0,esk1_0)),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_36])], [lemma_29, s38])).
fof(s40, plain, '>='('+'(esk1_0,'+'('==>'(esk1_0,esk3_0),esk1_0)),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_36])], [lemma_21, s39])).
fof(s41, plain, '>='('+'(esk3_0,'+'('==>'(esk3_0,esk1_0),esk1_0)),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_36])], [lemma_22, s40])).
fof(s42, plain, '>='('+'('==>'(esk3_0,esk1_0),esk1_0),esk3_0), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_23, s41])).
fof(s43, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_02, s42])).
fof(s44, plain, '>='('==>'(esk3_0,esk1_0),'==>'(esk1_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [axiom_6, s43])).
fof(lemma_31, lemma, '==>'(esk3_0,esk1_0) = '==>'(esk1_0,esk3_0), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_16, s44, lemma_30])).
fof(s45, plain, '>='(esk2_0,esk2_0), inference(instantiate, [status(thm)], [sos_04])).
fof(s46, plain, '>='('+'(esk2_0,'0'),esk2_0), inference(rewrite, [status(thm)], [sos_03, s45])).
fof(s47, plain, '>='('+'(esk2_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0))),esk2_0), inference(rewrite, [status(thm)], [lemma_19, s46])).
fof(s48, plain, '>='('+'(esk2_0,'==>'(esk3_0,'==>'(esk3_0,esk1_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_31, s47])).
fof(s49, plain, '>='('+'('+'(esk3_0,esk3_0),'==>'(esk3_0,'==>'(esk3_0,esk1_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_27, s48])).
fof(s50, plain, '>='('+'(esk3_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk3_0,esk1_0)))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_01, s49])).
fof(s51, plain, '>='('+'(esk3_0,'+'('==>'(esk3_0,esk1_0),'==>'('==>'(esk3_0,esk1_0),esk3_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_12, s50])).
fof(s52, plain, '>='('+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk3_0,esk1_0),esk3_0)),esk1_0), inference(mp, [status(thm), assumptions([c_0_36, c_0_44])], [lemma_28, s51])).
fof(s53, plain, '>='('+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0)),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_31, s52])).
fof(s54, plain, '>='('+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0))),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_12, s53])).
fof(s55, plain, '>='('+'(esk3_0,'0'),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_19, s54])).
fof(s56, plain, '>='(esk3_0,esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_03, s55])).
fof(s57, plain, '>='('==>'(esk1_0,esk2_0),'==>'(esk3_0,esk2_0)), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [sos_10, s56])).
fof(s58, plain, '>='(esk1_0,'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_36, c_0_44])], [c_0_36, s57])).
fof(lemma_32, lemma, '>='(esk1_0,esk3_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [c_0_44, s58])).
fof(s59, plain, '>='(esk2_0,esk2_0), inference(instantiate, [status(thm)], [sos_04])).
fof(s60, plain, '>='('+'(esk2_0,'0'),esk2_0), inference(rewrite, [status(thm)], [sos_03, s59])).
fof(s61, plain, '>='('+'(esk2_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0))),esk2_0), inference(rewrite, [status(thm)], [lemma_19, s60])).
fof(s62, plain, '>='('+'(esk2_0,'==>'(esk3_0,'==>'(esk3_0,esk1_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_31, s61])).
fof(s63, plain, '>='('+'('+'(esk3_0,esk3_0),'==>'(esk3_0,'==>'(esk3_0,esk1_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_27, s62])).
fof(s64, plain, '>='('+'(esk3_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk3_0,esk1_0)))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_01, s63])).
fof(s65, plain, '>='('+'(esk3_0,'+'('==>'(esk3_0,esk1_0),'==>'('==>'(esk3_0,esk1_0),esk3_0))),esk2_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_12, s64])).
fof(s66, plain, '>='('+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk3_0,esk1_0),esk3_0)),esk1_0), inference(mp, [status(thm), assumptions([c_0_36, c_0_44])], [lemma_28, s65])).
fof(s67, plain, '>='('+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0)),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_31, s66])).
fof(s68, plain, '>='('+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0))),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_12, s67])).
fof(s69, plain, '>='('+'(esk3_0,'0'),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [lemma_19, s68])).
fof(s70, plain, '>='(esk3_0,esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [sos_03, s69])).
fof(s71, plain, '>='('==>'(esk1_0,esk2_0),'==>'(esk3_0,esk2_0)), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [sos_10, s70])).
fof(s72, plain, '>='(esk1_0,'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_36, c_0_44])], [c_0_36, s71])).
fof(s73, plain, '>='(esk1_0,esk3_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [c_0_44, s72])).
fof(s74, plain, '>='('==>'(esk3_0,esk2_0),'==>'(esk1_0,esk2_0)), inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [sos_10, s73])).
fof(s75, plain, '>='('==>'(esk3_0,esk2_0),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_36, c_0_44])], [c_0_36, s74])).
fof(s76, plain, '>='(esk3_0,esk1_0), inference(rewrite, [status(thm), assumptions([c_0_44, c_0_36])], [c_0_44, s75])).
fof(s77, plain, esk1_0 = esk3_0, inference(mp, [status(thm), assumptions([c_0_44, c_0_36])], [sos_06, s76, lemma_32])).
fof(discharged, plain, ((esk3_0 = '==>'(esk3_0,esk2_0) & esk1_0 = '==>'(esk1_0,esk2_0)) => esk1_0 = esk3_0), inference(implies, [status(thm), discharge(implies, [c_0_44, c_0_36])], [s77, c_0_44, c_0_36])).
fof(goals_13, theorem, ! [X21, X22, X23]: ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
