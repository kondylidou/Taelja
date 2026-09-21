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
fof(s5, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_16, lemma, '>='('+'('1','1'),'1'), inference(rewrite, [status(thm)], [lemma_12, s5])).
fof(s6, plain, '>='('1','==>'('1','1')), inference(mp, [status(thm)], [axiom_5, lemma_16])).
fof(lemma_17, lemma, ! [X] : '>='('+'('1',X),'+'('==>'('1','1'),X)), inference(mp, [status(thm)], [sos_09, s6])).
fof(s7, plain, '>='('+'('1','+'(esk1_0,'==>'(esk1_0,'1'))),'+'('==>'('1','1'),'+'(esk1_0,'==>'(esk1_0,'1')))), inference(instantiate, [status(thm)], [lemma_17])).
fof(s8, plain, '>='('1','+'('==>'('1','1'),'+'(esk1_0,'==>'(esk1_0,'1')))), inference(rewrite, [status(thm)], [lemma_12, s7])).
fof(s9, plain, '>='('1','+'('0','+'(esk1_0,'==>'(esk1_0,'1')))), inference(rewrite, [status(thm)], [lemma_15, s8])).
fof(s10, plain, '>='('1','+'('+'(esk1_0,'==>'(esk1_0,'1')),'0')), inference(rewrite, [status(thm)], [sos_02, s9])).
fof(lemma_18, lemma, '>='('1','+'(esk1_0,'==>'(esk1_0,'1'))), inference(rewrite, [status(thm)], [sos_03, s10])).
fof(s11, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(s12, plain, '>='('==>'(esk1_0,'1'),'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_11, s11])).
fof(lemma_19, lemma, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(mp, [status(thm)], [axiom_10, s12])).
fof(lemma_20, lemma, '1' = '+'(esk1_0,'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_06, lemma_18, lemma_19])).
fof(s13, plain, '>='('+'('1',esk1_0),'+'('==>'('1','1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_17])).
fof(s14, plain, '>='('1','+'('==>'('1','1'),esk1_0)), inference(rewrite, [status(thm)], [lemma_12, s13])).
fof(s15, plain, '>='('1','+'('==>'('1','+'(esk1_0,'==>'(esk1_0,'1'))),esk1_0)), inference(rewrite, [status(thm)], [lemma_20, s14])).
fof(s16, plain, '>='('1','+'('==>'('1','+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s15])).
fof(s17, plain, '>='('1','+'('==>'('+'(esk1_0,'==>'(esk1_0,'1')),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [lemma_20, s16])).
fof(s18, plain, '>='('1','+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s17])).
fof(s19, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [lemma_20, s18])).
fof(s20, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'(esk1_0,'1'),esk1_0)),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s19])).
fof(s21, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'+'(esk1_0,'==>'(esk1_0,'1'))),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s20])).
fof(s22, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('+'('==>'(esk1_0,'1'),esk1_0),'1'),esk1_0)), inference(rewrite, [status(thm)], [lemma_20, s21])).
fof(s23, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('+'(esk1_0,'==>'(esk1_0,'1')),'1'),esk1_0)), inference(rewrite, [status(thm)], [sos_02, s22])).
fof(s24, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('==>'('1','1'),esk1_0)), inference(rewrite, [status(thm)], [lemma_20, s23])).
fof(s25, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'('0',esk1_0)), inference(rewrite, [status(thm)], [lemma_15, s24])).
fof(s26, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'+'(esk1_0,'0')), inference(rewrite, [status(thm)], [sos_02, s25])).
fof(lemma_21, lemma, '>='('+'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [sos_03, s26])).
fof(lemma_22, lemma, ! [X] : '==>'('==>'('==>'(X,'1'),X),X) = '==>'('1','1'), inference(rewrite, [status(thm)], [lemma_15, sos_13])).
fof(s27, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'(X,'==>'('1','1'))), inference(instantiate, [status(thm)], [sos_04])).
fof(s28, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'('==>'('1','1'),X)), inference(rewrite, [status(thm)], [sos_02, s27])).
fof(s29, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'('0',X)), inference(rewrite, [status(thm)], [lemma_15, s28])).
fof(s30, plain, ! [X] : '>='('+'(X,'==>'('1','1')),'+'(X,'0')), inference(rewrite, [status(thm)], [sos_02, s29])).
fof(lemma_23, lemma, ! [X] : '>='('+'(X,'==>'('1','1')),X), inference(rewrite, [status(thm)], [sos_03, s30])).
fof(s31, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_24, lemma, ! [X] : '>='('+'('1','==>'(X,X)),'1'), inference(rewrite, [status(thm)], [lemma_12, s31])).
fof(lemma_25, lemma, ! [X] : '>='('==>'('1','1'),'==>'(X,X)), inference(mp, [status(thm)], [axiom_5, lemma_23])).
fof(s32, plain, ! [X] : '>='('==>'(X,X),'==>'('1','1')), inference(mp, [status(thm)], [axiom_5, lemma_24])).
fof(lemma_26, lemma, ! [X] : '==>'(X,X) = '==>'('1','1'), inference(mp, [status(thm)], [sos_06, s32, lemma_25])).
fof(s33, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('==>'(Y,Y),X), inference(instantiate, [status(thm)], [sos_02])).
fof(s34, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('==>'('1','1'),X), inference(rewrite, [status(thm)], [lemma_26, s33])).
fof(s35, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'('0',X), inference(rewrite, [status(thm)], [lemma_15, s34])).
fof(s36, plain, ! [X,Y] : '+'(X,'==>'(Y,Y)) = '+'(X,'0'), inference(rewrite, [status(thm)], [sos_02, s35])).
fof(lemma_27, lemma, ! [X,Y] : '+'(X,'==>'(Y,Y)) = X, inference(rewrite, [status(thm)], [sos_03, s36])).
fof(lemma_28, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),esk1_0)), inference(mp, [status(thm)], [axiom_5, lemma_21])).
fof(s37, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),esk1_0), inference(rewrite, [status(thm)], [sos_02, lemma_21])).
fof(lemma_29, lemma, '>='('1',esk1_0), inference(rewrite, [status(thm)], [lemma_20, s37])).
fof(s38, plain, '>='('==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)), inference(instantiate, [status(thm)], [sos_04])).
fof(s39, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)),esk1_0), inference(mp, [status(thm)], [axiom_10, s38])).
fof(s40, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('1','1')),esk1_0), inference(rewrite, [status(thm)], [lemma_22, s39])).
fof(s41, plain, '>='('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [lemma_27, s40])).
fof(lemma_30, lemma, '==>'('==>'(esk1_0,'1'),esk1_0) = esk1_0, inference(mp, [status(thm)], [sos_06, s41, lemma_28])).
fof(lemma_31, lemma, ! [X] : '>='('==>'(X,'1'),'==>'(X,esk1_0)), inference(mp, [status(thm)], [sos_11, lemma_29])).
fof(s42, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),'==>'('==>'(esk1_0,'1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_31])).
fof(lemma_32, lemma, '>='('==>'('==>'(esk1_0,'1'),'1'),esk1_0), inference(rewrite, [status(thm)], [lemma_30, s42])).
fof(s43, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'1'), inference(rewrite, [status(thm)], [sos_02, lemma_19])).
fof(lemma_33, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),'1')), inference(mp, [status(thm)], [axiom_5, s43])).
fof(s44, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(mp, [status(thm)], [sos_06, lemma_32, lemma_33])).
fof(discharged, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(conclude, [status(thm)], [s44])).
fof(goals_14, theorem, ! [X21]: '==>'('==>'(X21, '1'), '1') = X21, inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
