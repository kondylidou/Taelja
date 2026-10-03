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
fof(axiom_4, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [sos_07])).
fof(axiom_10, plain, ! [X,Y,Z] : ('>='(X,'==>'(Y,Z)) => '>='('+'(Y,X),Z)), inference(clausify, [status(thm)], [sos_07])).
fof(s1, plain, ! [X] : '+'('1',X) = '+'(X,'1'), inference(instantiate, [status(thm)], [sos_02])).
fof(lemma_12, lemma, ! [X] : '+'('1',X) = '1', inference(rewrite, [status(thm)], [sos_12, s1])).
fof(s2, plain, '>='('1','1'), inference(instantiate, [status(thm)], [sos_04])).
fof(s3, plain, ! [X] : '>='('+'('1',X),'1'), inference(rewrite, [status(thm)], [lemma_12, s2])).
fof(lemma_13, lemma, ! [X] : '>='(X,'==>'('1','1')), inference(mp, [status(thm)], [axiom_4, s3])).
fof(s4, plain, '>='('==>'('1','1'),'0'), inference(instantiate, [status(thm)], [sos_08])).
fof(s5, plain, '>='('0','==>'('1','1')), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_14, lemma, '0' = '==>'('1','1'), inference(mp, [status(thm)], [sos_06, s4, s5])).
fof(s6, plain, ! [X] : '+'('==>'('1','1'),X) = '+'('0',X), inference(instantiate, [status(thm)], [lemma_14])).
fof(s7, plain, ! [X] : '+'('==>'('1','1'),X) = '+'(X,'0'), inference(rewrite, [status(thm)], [sos_02, s6])).
fof(lemma_15, lemma, ! [X] : '+'('==>'('1','1'),X) = X, inference(rewrite, [status(thm)], [sos_03, s7])).
fof(s8, plain, ! [X,Y] : '>='('+'(X,Y),'+'('==>'('1','1'),Y)), inference(mp, [status(thm)], [sos_09, lemma_13])).
fof(lemma_16, lemma, ! [X,Y] : '>='('+'(X,Y),Y), inference(rewrite, [status(thm)], [lemma_15, s8])).
fof(s9, plain, ! [X] : '>='('+'('1',X),X), inference(instantiate, [status(thm)], [lemma_16])).
fof(lemma_17, lemma, ! [X] : '>='('1',X), inference(rewrite, [status(thm)], [lemma_12, s9])).
fof(lemma_18, lemma, ! [X,Y] : '>='('==>'(X,'1'),'==>'(X,Y)), inference(mp, [status(thm)], [sos_11, lemma_17])).
fof(s10, plain, '>='('==>'(esk1_0,'1'),'==>'(esk1_0,'1')), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_19, lemma, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(mp, [status(thm)], [axiom_10, s10])).
fof(s11, plain, '>='('1','+'(esk1_0,'==>'(esk1_0,'1'))), inference(instantiate, [status(thm)], [lemma_17])).
fof(s12, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(instantiate, [status(thm)], [lemma_19])).
fof(lemma_20, lemma, '1' = '+'(esk1_0,'==>'(esk1_0,'1')), inference(mp, [status(thm)], [sos_06, s11, s12])).
fof(s13, plain, '+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('1','1')) = '+'('==>'('==>'(esk1_0,'1'),esk1_0),'0'), inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_21, lemma, '+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('1','1')) = '==>'('==>'(esk1_0,'1'),esk1_0), inference(rewrite, [status(thm)], [sos_03, s13])).
fof(lemma_22, lemma, ! [X] : '==>'('==>'('==>'(X,'1'),X),X) = '==>'('1','1'), inference(rewrite, [status(thm)], [lemma_14, sos_13])).
fof(s14, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(instantiate, [status(thm)], [lemma_16])).
fof(lemma_23, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),esk1_0)), inference(mp, [status(thm)], [axiom_4, s14])).
fof(s15, plain, '>='('==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)), inference(instantiate, [status(thm)], [sos_04])).
fof(s16, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)),esk1_0), inference(mp, [status(thm)], [axiom_10, s15])).
fof(s17, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('1','1')),esk1_0), inference(rewrite, [status(thm)], [lemma_22, s16])).
fof(s18, plain, '>='('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [lemma_21, s17])).
fof(s19, plain, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_23])).
fof(lemma_24, lemma, '==>'('==>'(esk1_0,'1'),esk1_0) = esk1_0, inference(mp, [status(thm)], [sos_06, s18, s19])).
fof(s20, plain, '>='('1','1'), inference(instantiate, [status(thm)], [lemma_17])).
fof(s21, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(rewrite, [status(thm)], [lemma_20, s20])).
fof(s22, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'1'), inference(rewrite, [status(thm)], [sos_02, s21])).
fof(lemma_25, lemma, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),'1')), inference(mp, [status(thm)], [axiom_4, s22])).
fof(s23, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),'==>'('==>'(esk1_0,'1'),esk1_0)), inference(instantiate, [status(thm)], [lemma_18])).
fof(s24, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),esk1_0), inference(rewrite, [status(thm)], [lemma_24, s23])).
fof(s25, plain, '>='(esk1_0,'==>'('==>'(esk1_0,'1'),'1')), inference(instantiate, [status(thm)], [lemma_25])).
fof(s26, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(mp, [status(thm)], [sos_06, s24, s25])).
fof(discharged, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(conclude, [status(thm)], [s26])).
fof(goals_14, theorem, ! [X21]: '==>'('==>'(X21, '1'), '1') = X21, inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
