% SZS output start Proof
fof(skolem_definition, definition, ? [X21, X22, X23]: ~ ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23) => ~ ((esk1_0 = '==>'(esk1_0, esk2_0) & esk3_0 = '==>'(esk3_0, esk2_0)) => esk1_0 = esk3_0), introduced(definition, [new_symbols(definition, [esk1_0,esk3_0])], [])).
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
fof(s1, plain, '>='('+'(esk1_0,'0'),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_13, lemma, ! [X] : '>='('+'('+'(esk1_0,'0'),X),'+'('0',X)), inference(mp, [status(thm)], [sos_09, s1])).
fof(s2, plain, '>='('+'('+'(esk1_0,'0'),'+'(esk3_0,'0')),'+'('0','+'(esk3_0,'0'))), inference(instantiate, [status(thm)], [lemma_13])).
fof(s3, plain, '>='('+'(esk1_0,'+'('0','+'(esk3_0,'0'))),'+'('0','+'(esk3_0,'0'))), inference(rewrite, [status(thm)], [sos_01, s2])).
fof(s4, plain, '>='('+'(esk1_0,'+'('+'(esk3_0,'0'),'0')),'+'('0','+'(esk3_0,'0'))), inference(rewrite, [status(thm)], [sos_02, s3])).
fof(s5, plain, '>='('+'(esk1_0,'+'(esk3_0,'0')),'+'('0','+'(esk3_0,'0'))), inference(rewrite, [status(thm)], [sos_03, s4])).
fof(s6, plain, '>='('+'(esk1_0,'+'(esk3_0,'0')),'+'('+'(esk3_0,'0'),'0')), inference(rewrite, [status(thm)], [sos_02, s5])).
fof(s7, plain, '>='('+'(esk1_0,'+'(esk3_0,'0')),'+'(esk3_0,'0')), inference(rewrite, [status(thm)], [sos_03, s6])).
fof(s8, plain, '>='('+'(esk1_0,esk3_0),'+'(esk3_0,'0')), inference(rewrite, [status(thm)], [sos_03, s7])).
fof(s9, plain, '>='('+'(esk1_0,esk3_0),esk3_0), inference(rewrite, [status(thm)], [sos_03, s8])).
fof(lemma_14, lemma, '>='('+'(esk1_0,'+'(esk3_0,'0')),esk3_0), inference(rewrite, [status(thm)], [sos_03, s9])).
fof(s10, plain, '>='('+'(esk3_0,'0'),'==>'(esk1_0,esk3_0)), inference(mp, [status(thm)], [axiom_7, lemma_14])).
fof(s11, plain, '>='(esk3_0,'==>'(esk1_0,esk3_0)), inference(rewrite, [status(thm)], [sos_03, s10])).
fof(s12, plain, '>='('+'(esk3_0,'0'),'==>'(esk1_0,esk3_0)), inference(rewrite, [status(thm)], [sos_03, s11])).
fof(lemma_15, lemma, '>='('0','==>'(esk3_0,'==>'(esk1_0,esk3_0))), inference(mp, [status(thm)], [axiom_7, s12])).
fof(s13, plain, '>='(esk3_0,'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_16, lemma, ! [X] : '>='('+'(esk3_0,X),'+'('0',X)), inference(mp, [status(thm)], [sos_09, s13])).
fof(s14, plain, '>='('+'(esk3_0,esk2_0),'+'('0',esk2_0)), inference(instantiate, [status(thm)], [lemma_16])).
fof(s15, plain, '>='('+'(esk3_0,esk2_0),'+'(esk2_0,'0')), inference(rewrite, [status(thm)], [sos_02, s14])).
fof(lemma_17, lemma, '>='('+'(esk3_0,esk2_0),esk2_0), inference(rewrite, [status(thm)], [sos_03, s15])).
fof(s16, plain, '>='(esk2_0,'==>'(esk3_0,esk2_0)), inference(mp, [status(thm)], [axiom_7, lemma_17])).
fof(lemma_18, lemma, '>='(esk2_0,esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37])], [c_0_37, s16])).
fof(s17, plain, '>='('+'(esk2_0,'0'),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_03, lemma_18])).
fof(lemma_19, lemma, '>='('0','==>'(esk2_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37])], [axiom_7, s17])).
fof(s18, plain, '>='('==>'(esk3_0,esk1_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_20, lemma, ! [X] : '>='('+'('==>'(esk3_0,esk1_0),X),'+'('0',X)), inference(mp, [status(thm)], [sos_09, s18])).
fof(s19, plain, '>='('+'('==>'(esk3_0,esk1_0),esk3_0),'+'('0',esk3_0)), inference(instantiate, [status(thm)], [lemma_20])).
fof(s20, plain, '>='('+'('==>'(esk3_0,esk1_0),esk3_0),'+'(esk3_0,'0')), inference(rewrite, [status(thm)], [sos_02, s19])).
fof(s21, plain, '>='('+'('==>'(esk3_0,esk1_0),esk3_0),esk3_0), inference(rewrite, [status(thm)], [sos_03, s20])).
fof(s22, plain, '>='('+'(esk3_0,'==>'(esk3_0,esk1_0)),esk3_0), inference(rewrite, [status(thm)], [sos_02, s21])).
fof(lemma_21, lemma, '>='('+'(esk1_0,'==>'(esk1_0,esk3_0)),esk3_0), inference(rewrite, [status(thm)], [sos_12, s22])).
fof(s23, plain, '>='('==>'(esk2_0,esk3_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_22, lemma, '==>'(esk2_0,esk3_0) = '0', inference(mp, [status(thm), assumptions([c_0_37])], [sos_06, s23, lemma_19])).
fof(s24, plain, '>='('+'('+'(esk1_0,'==>'(esk1_0,esk3_0)),esk3_0),'+'(esk3_0,esk3_0)), inference(mp, [status(thm)], [sos_09, lemma_21])).
fof(s25, plain, '>='('+'(esk1_0,'+'('==>'(esk1_0,esk3_0),esk3_0)),'+'(esk3_0,esk3_0)), inference(rewrite, [status(thm)], [sos_01, s24])).
fof(lemma_23, lemma, '>='('+'('==>'(esk1_0,esk3_0),esk3_0),'==>'(esk1_0,'+'(esk3_0,esk3_0))), inference(mp, [status(thm)], [axiom_7, s25])).
fof(s26, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,'+'(esk3_0,esk3_0))), inference(rewrite, [status(thm)], [sos_02, lemma_23])).
fof(s27, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,'+'(esk3_0,'==>'(esk3_0,esk2_0)))), inference(rewrite, [status(thm), assumptions([c_0_37])], [c_0_37, s26])).
fof(s28, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,'+'(esk2_0,'==>'(esk2_0,esk3_0)))), inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_12, s27])).
fof(s29, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,'+'(esk2_0,'0'))), inference(rewrite, [status(thm), assumptions([c_0_37])], [lemma_22, s28])).
fof(s30, plain, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),'==>'(esk1_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_37])], [sos_03, s29])).
fof(lemma_24, lemma, '>='('+'(esk3_0,'==>'(esk1_0,esk3_0)),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32, c_0_37])], [c_0_32, s30])).
fof(s31, plain, '>='(esk1_0,'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_25, lemma, ! [X] : '>='('+'(esk1_0,X),'+'('0',X)), inference(mp, [status(thm)], [sos_09, s31])).
fof(s32, plain, '>='('+'(esk1_0,esk2_0),'+'('0',esk2_0)), inference(instantiate, [status(thm)], [lemma_25])).
fof(s33, plain, '>='('+'(esk1_0,esk2_0),'+'(esk2_0,'0')), inference(rewrite, [status(thm)], [sos_02, s32])).
fof(lemma_26, lemma, '>='('+'(esk1_0,esk2_0),esk2_0), inference(rewrite, [status(thm)], [sos_03, s33])).
fof(s34, plain, '>='(esk2_0,'==>'(esk1_0,esk2_0)), inference(mp, [status(thm)], [axiom_7, lemma_26])).
fof(lemma_27, lemma, '>='(esk2_0,esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32])], [c_0_32, s34])).
fof(s35, plain, '>='('+'(esk2_0,'0'),esk1_0), inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_03, lemma_27])).
fof(lemma_28, lemma, '>='('0','==>'(esk2_0,esk1_0)), inference(mp, [status(thm), assumptions([c_0_32])], [axiom_7, s35])).
fof(s36, plain, '>='('==>'(esk1_0,esk3_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_29, lemma, ! [X] : '>='('+'('==>'(esk1_0,esk3_0),X),'+'('0',X)), inference(mp, [status(thm)], [sos_09, s36])).
fof(s37, plain, '>='('+'('==>'(esk1_0,esk3_0),esk1_0),'+'('0',esk1_0)), inference(instantiate, [status(thm)], [lemma_29])).
fof(s38, plain, '>='('+'('==>'(esk1_0,esk3_0),esk1_0),'+'(esk1_0,'0')), inference(rewrite, [status(thm)], [sos_02, s37])).
fof(s39, plain, '>='('+'('==>'(esk1_0,esk3_0),esk1_0),esk1_0), inference(rewrite, [status(thm)], [sos_03, s38])).
fof(s40, plain, '>='('+'(esk1_0,'==>'(esk1_0,esk3_0)),esk1_0), inference(rewrite, [status(thm)], [sos_02, s39])).
fof(lemma_30, lemma, '>='('+'(esk3_0,'==>'(esk3_0,esk1_0)),esk1_0), inference(rewrite, [status(thm)], [sos_12, s40])).
fof(s41, plain, '>='('==>'(esk2_0,esk1_0),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_31, lemma, '==>'(esk2_0,esk1_0) = '0', inference(mp, [status(thm), assumptions([c_0_32])], [sos_06, s41, lemma_28])).
fof(s42, plain, '>='('+'('+'(esk3_0,'==>'(esk3_0,esk1_0)),esk1_0),'+'(esk1_0,esk1_0)), inference(mp, [status(thm)], [sos_09, lemma_30])).
fof(s43, plain, '>='('+'(esk3_0,'+'('==>'(esk3_0,esk1_0),esk1_0)),'+'(esk1_0,esk1_0)), inference(rewrite, [status(thm)], [sos_01, s42])).
fof(lemma_32, lemma, '>='('+'('==>'(esk3_0,esk1_0),esk1_0),'==>'(esk3_0,'+'(esk1_0,esk1_0))), inference(mp, [status(thm)], [axiom_7, s43])).
fof(s44, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,'+'(esk1_0,esk1_0))), inference(rewrite, [status(thm)], [sos_02, lemma_32])).
fof(s45, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,'+'(esk1_0,'==>'(esk1_0,esk2_0)))), inference(rewrite, [status(thm), assumptions([c_0_32])], [c_0_32, s44])).
fof(s46, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,'+'(esk2_0,'==>'(esk2_0,esk1_0)))), inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_12, s45])).
fof(s47, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,'+'(esk2_0,'0'))), inference(rewrite, [status(thm), assumptions([c_0_32])], [lemma_31, s46])).
fof(s48, plain, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_32])], [sos_03, s47])).
fof(lemma_33, lemma, '>='('+'(esk1_0,'==>'(esk3_0,esk1_0)),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [c_0_37, s48])).
fof(lemma_34, lemma, '>='('==>'(esk1_0,esk3_0),'==>'(esk3_0,esk1_0)), inference(mp, [status(thm), assumptions([c_0_32, c_0_37])], [axiom_7, lemma_24])).
fof(s49, plain, '>='('==>'(esk3_0,'==>'(esk1_0,esk3_0)),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_35, lemma, '==>'(esk3_0,'==>'(esk1_0,esk3_0)) = '0', inference(mp, [status(thm)], [sos_06, s49, lemma_15])).
fof(s50, plain, '>='('==>'(esk3_0,esk1_0),'==>'(esk1_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [axiom_7, lemma_33])).
fof(lemma_36, lemma, '==>'(esk3_0,esk1_0) = '==>'(esk1_0,esk3_0), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [sos_06, s50, lemma_34])).
fof(s51, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk1_0,esk3_0),'0'), inference(instantiate, [status(thm)], [sos_03])).
fof(s52, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk1_0,esk3_0),'==>'(esk3_0,'==>'(esk1_0,esk3_0))), inference(rewrite, [status(thm)], [lemma_35, s51])).
fof(s53, plain, '+'(esk1_0,esk3_0) = '+'(esk1_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0)))), inference(rewrite, [status(thm)], [sos_01, s52])).
fof(s54, plain, '+'(esk1_0,esk3_0) = '+'(esk1_0,'+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm)], [sos_12, s53])).
fof(s55, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk1_0,'==>'(esk1_0,esk3_0)),'==>'('==>'(esk1_0,esk3_0),esk3_0)), inference(rewrite, [status(thm)], [sos_01, s54])).
fof(s56, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk3_0,'==>'(esk3_0,esk1_0)),'==>'('==>'(esk1_0,esk3_0),esk3_0)), inference(rewrite, [status(thm)], [sos_12, s55])).
fof(s57, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'('==>'(esk3_0,esk1_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm)], [sos_01, s56])).
fof(s58, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'('==>'(esk1_0,esk3_0),'==>'('==>'(esk1_0,esk3_0),esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_36, s57])).
fof(s59, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'(esk3_0,'==>'(esk3_0,'==>'(esk1_0,esk3_0)))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_12, s58])).
fof(s60, plain, '+'(esk1_0,esk3_0) = '+'(esk3_0,'+'(esk3_0,'0')), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_35, s59])).
fof(s61, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk3_0,esk3_0),'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_01, s60])).
fof(s62, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk3_0,'==>'(esk3_0,esk2_0)),'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [c_0_37, s61])).
fof(s63, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk2_0,'==>'(esk2_0,esk3_0)),'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_12, s62])).
fof(s64, plain, '+'(esk1_0,esk3_0) = '+'('+'(esk2_0,'0'),'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_22, s63])).
fof(s65, plain, '+'(esk1_0,esk3_0) = '+'(esk2_0,'0'), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_03, s64])).
fof(lemma_37, lemma, '+'(esk1_0,esk3_0) = esk2_0, inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [sos_03, s65])).
fof(s66, plain, '>='('+'(esk3_0,esk1_0),'+'(esk3_0,esk1_0)), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_38, lemma, '>='(esk1_0,'==>'(esk3_0,'+'(esk3_0,esk1_0))), inference(mp, [status(thm)], [axiom_7, s66])).
fof(s67, plain, '>='(esk1_0,'==>'(esk3_0,'+'(esk1_0,esk3_0))), inference(rewrite, [status(thm)], [sos_02, lemma_38])).
fof(s68, plain, '>='('==>'(esk1_0,esk2_0),'==>'(esk3_0,'+'(esk1_0,esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_32])], [c_0_32, s67])).
fof(s69, plain, '>='('==>'(esk1_0,'+'(esk1_0,esk3_0)),'==>'(esk3_0,'+'(esk1_0,esk3_0))), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_37, s68])).
fof(s70, plain, '>='('==>'(esk1_0,'+'(esk1_0,esk3_0)),'==>'(esk3_0,esk2_0)), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_37, s69])).
fof(lemma_39, lemma, '>='('==>'(esk1_0,'+'(esk1_0,esk3_0)),esk3_0), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [c_0_37, s70])).
fof(s71, plain, '>='('+'(esk1_0,esk3_0),'+'(esk1_0,esk3_0)), inference(instantiate, [status(thm)], [sos_04])).
fof(s72, plain, '>='(esk3_0,'==>'(esk1_0,'+'(esk1_0,esk3_0))), inference(mp, [status(thm)], [axiom_7, s71])).
fof(lemma_40, lemma, esk3_0 = '==>'(esk1_0,'+'(esk1_0,esk3_0)), inference(mp, [status(thm), assumptions([c_0_37, c_0_32])], [sos_06, s72, lemma_39])).
fof(s73, plain, esk1_0 = '==>'(esk1_0,'+'(esk1_0,esk3_0)), inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_37, c_0_32])).
fof(s74, plain, esk1_0 = esk3_0, inference(rewrite, [status(thm), assumptions([c_0_37, c_0_32])], [lemma_40, s73])).
fof(discharged, plain, ((esk3_0 = '==>'(esk3_0,esk2_0) & esk1_0 = '==>'(esk1_0,esk2_0)) => esk1_0 = esk3_0), inference(implies, [status(thm), discharge(implies, [c_0_37, c_0_32])], [s74, c_0_37, c_0_32])).
fof(goals_13, theorem, ! [X21, X22, X23]: ((X21 = '==>'(X21, X22) & X23 = '==>'(X23, X22)) => X21 = X23), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
