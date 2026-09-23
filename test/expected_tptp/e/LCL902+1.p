% SZS output start Proof
fof(skolem_definition, definition, ? [X21]: ~ '==>'('==>'(X21, '1'), '1') = X21 => ~ '==>'('==>'(esk1_0, '1'), '1') = esk1_0, introduced(definition, [new_symbols(definition, [esk1_0])], [])).
fof(sos_12, axiom, ! [X1]: '+'(X1, '1') = '1', file('Problems/LCL/LCL902+1.p', sos_12)).
fof(sos_02, axiom, ! [X1, X2]: '+'(X1, X2) = '+'(X2, X1), file('Problems/LCL/LCL902+1.p', sos_02)).
fof(sos_07, axiom, ! [X9, X10, X11]: ('>='('+'(X9, X10), X11) <=> '>='(X10, '==>'(X9, X11))), file('Problems/LCL/LCL902+1.p', sos_07)).
fof(sos_06, axiom, ! [X7, X8]: (('>='(X7, X8) & '>='(X8, X7)) => X7 = X8), file('Problems/LCL/LCL902+1.p', sos_06)).
fof(sos_08, axiom, ! [X1]: '>='(X1, '0'), file('Problems/LCL/LCL902+1.p', sos_08)).
fof(sos_04, axiom, ! [X1]: '>='(X1, X1), file('Problems/LCL/LCL902+1.p', sos_04)).
fof(sos_03, axiom, ! [X1]: '+'(X1, '0') = X1, file('Problems/LCL/LCL902+1.p', sos_03)).
fof(sos_09, axiom, ! [X12, X13, X14]: ('>='(X12, X13) => '>='('+'(X12, X14), '+'(X13, X14))), file('Problems/LCL/LCL902+1.p', sos_09)).
fof(sos_13, axiom, ! [X1]: '==>'('==>'('==>'(X1, '1'), X1), X1) = '0', file('Problems/LCL/LCL902+1.p', sos_13)).
fof(sos_11, axiom, ! [X18, X19, X20]: ('>='(X18, X19) => '>='('==>'(X20, X18), '==>'(X20, X19))), file('Problems/LCL/LCL902+1.p', sos_11)).
fof(axiom_5, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [sos_07])).
fof(axiom_10, plain, ! [X,Y,Z] : ('>='(X,'==>'(Y,Z)) => '>='('+'(Y,X),Z)), inference(clausify, [status(thm)], [sos_07])).
fof(s1, plain, ! [X] : '+'('1',X) = '+'(X,'1'), inference(instantiate, [status(thm)], [sos_02])).
fof(lemma_12, lemma, ! [X] : '+'('1',X) = '1', inference(rewrite, [status(thm)], [sos_12, s1])).
fof(s2, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(s3, plain, '>='('+'('0','1'),'1'), inference(rewrite, [status(thm)], [sos_12, s2])).
fof(lemma_13, lemma, '>='('+'('1','0'),'1'), inference(rewrite, [status(thm)], [sos_02, s3])).
fof(lemma_14, lemma, '>='('0','==>'('1','1')), inference(mp, [status(thm)], [axiom_5, lemma_13])).
fof(s4, plain, '>='('==>'('1','1'),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(lemma_15, lemma, '0' = '==>'('1','1'), inference(mp, [status(thm)], [sos_06, s4, lemma_14])).
fof(lemma_16, lemma, ! [X] : '==>'('==>'('==>'(X,'1'),X),X) = '==>'('1','1'), inference(rewrite, [status(thm)], [lemma_15, sos_13])).
fof(s5, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'(X,'==>'('1','1'))), inference(instantiate, [status(thm)], [sos_04])).
fof(s6, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'('==>'('1','1'),X)), inference(rewrite, [status(thm)], [sos_02, s5])).
fof(s7, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'('0',X)), inference(rewrite, [status(thm)], [lemma_15, s6])).
fof(s8, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'(X,'0')), inference(rewrite, [status(thm)], [sos_02, s7])).
fof(lemma_17, lemma, ! [X] : '>='('+'(X,'==>'('1','1')),X), inference(rewrite, [status(thm)], [sos_03, s8])).
fof(s9, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_18, lemma, ! [X] : '>='('+'('1','==>'(X,X)),'1'), inference(rewrite, [status(thm)], [lemma_12, s9])).
fof(lemma_19, lemma, ! [X] : '>='('==>'('1','1'),'==>'(X,X)), inference(mp, [status(thm)], [axiom_5, lemma_17])).
fof(s10, plain, ! [X] : '>='('==>'(X,X),'==>'('1','1')), inference(mp, [status(thm)], [axiom_5, lemma_18])).
fof(lemma_20, lemma, ! [X] : '==>'(X,X) = '==>'('1','1'), inference(mp, [status(thm)], [sos_06, s10, lemma_19])).
fof(s11, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('==>'(Y,Y),X), inference(instantiate, [status(thm)], [sos_02])).
fof(s12, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('==>'('1','1'),X), inference(rewrite, [status(thm)], [lemma_20, s11])).
fof(s13, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('0',X), inference(rewrite, [status(thm)], [lemma_15, s12])).
fof(s14, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'(X,'0'), inference(rewrite, [status(thm)], [sos_02, s13])).
fof(lemma_21, lemma, ! [X,Y] : '+'(X,'==>'(Y,Y)) = X, inference(rewrite, [status(thm)], [sos_03, s14])).
fof(s15, plain, '>='('1','0'), inference(instantiate, [status(thm)], [sos_08])).
fof(s16, plain, '>='('1','==>'('1','1')), inference(rewrite, [status(thm)], [lemma_15, s15])).
fof(lemma_22, lemma, ! [X] : '>='('+'('1',X),'+'('==>'('1','1'),X)), inference(mp, [status(thm)], [sos_09, s16])).
fof(s17, plain, '>='('+'('1','+'(esk1_0,'==>'(esk1_0,'1'))),'+'('==>'('1','1'),'+'(esk1_0,'==>'(esk1_0,'1')))), inference(instantiate, [status(thm)], [lemma_22])).
fof(s18, plain, '>='('1','+'('==>'('1','1'),'+'(esk1_0,'==>'(esk1_0,'1')))), inference(rewrite, [status(thm)], [lemma_12, s17])).
fof(s19, plain, '>='('1','+'('0','+'(esk1_0,'==>'(esk1_0,'1')))), inference(rewrite, [status(thm)], [lemma_15, s18])).
fof(s20, plain, '>='('1','+'('+'(esk1_0,'==>'(esk1_0,'1')),'0')), inference(rewrite, [status(thm)], [sos_02, s19])).
fof(lemma_23, lemma, '>='('1','+'(esk1_0,'==>'(esk1_0,'1'))), inference(rewrite, [status(thm)], [sos_03, s20])).
fof(s21, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(s22, plain, '>='('==>'(esk1_0,'1'),'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_11, s21])).
fof(lemma_24, lemma, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(mp, [status(thm)], [axiom_10, s22])).
fof(lemma_25, lemma, '1' = '+'(esk1_0,'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_06, lemma_23, lemma_24])).
fof(s23, plain, '>='('+'('1',esk1_0),'+'('==>'('1','1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_22])).
fof(s24, plain, '>='('1','+'('==>'('1','1'),esk1_0)), inference(rewrite, [status(thm)], [lemma_12, s23])).
fof(s25, plain, '>='('1','+'('==>'('1','+'(esk1_0,'==>'(esk1_0,'1'))),esk1_0)), inference(rewrite, [status(thm)], [lemma_25, s24])).
fof(s26, plain, '>='('1','+'('==>'('1','+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s25])).
fof(s27, plain, '>='('1','+'('==>'('+'(esk1_0,'==>'(esk1_0,'1')),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [lemma_25, s26])).
fof(s28, plain, '>='('1','+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s27])).
fof(s29, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [lemma_25, s28])).
fof(s30, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s29])).
fof(s31, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'(esk1_0,'==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)))), inference(rewrite, [status(thm)], [sos_02, s30])).
fof(lemma_26, lemma, '>='('+'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [lemma_21, s31])).
fof(lemma_27, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),esk1_0)), inference(mp, [status(thm)], [axiom_5, lemma_26])).
fof(s32, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),esk1_0), inference(rewrite, [status(thm)], [sos_02, lemma_26])).
fof(lemma_28, lemma, '>='('1',esk1_0), inference(rewrite, [status(thm)], [lemma_25, s32])).
fof(s33, plain, '>='('==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)), inference(instantiate, [status(thm)], [sos_04])).
fof(s34, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)),esk1_0), inference(mp, [status(thm)], [axiom_10, s33])).
fof(s35, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('1','1')),esk1_0), inference(rewrite, [status(thm)], [lemma_16, s34])).
fof(s36, plain, '>='('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [lemma_21, s35])).
fof(lemma_29, lemma, '==>'('==>'(esk1_0,'1'),esk1_0) = esk1_0, inference(mp, [status(thm)], [sos_06, s36, lemma_27])).
fof(lemma_30, lemma, ! [X] : '>='('==>'(X,'1'),'==>'(X,esk1_0)), inference(mp, [status(thm)], [sos_11, lemma_28])).
fof(s37, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),'==>'('==>'(esk1_0,'1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_30])).
fof(lemma_31, lemma, '>='('==>'('==>'(esk1_0,'1'),'1'),esk1_0), inference(rewrite, [status(thm)], [lemma_29, s37])).
fof(s38, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(s39, plain, '>='('==>'(esk1_0,'1'),'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_11, s38])).
fof(s40, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(mp, [status(thm)], [axiom_10, s39])).
fof(s41, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'1'), inference(rewrite, [status(thm)], [sos_02, s40])).
fof(lemma_32, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),'1')), inference(mp, [status(thm)], [axiom_5, s41])).
fof(s42, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(mp, [status(thm)], [sos_06, lemma_31, lemma_32])).
fof(discharged, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(conclude, [status(thm)], [s42])).
fof(goals_14, theorem, ! [X21]: '==>'('==>'(X21, '1'), '1') = X21, inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
