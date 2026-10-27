% SZS output start Proof
fof(skolem_definition, definition, ? [X21]: ~ '==>'('==>'(X21, '1'), '1') = X21 => ~ '==>'('==>'(esk1_0, '1'), '1') = esk1_0, introduced(definition, [new_symbols(definition, [esk1_0])], [])).
fof(sos_03, axiom, ! [X1]: '+'(X1, '0') = X1, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_03)).
fof(sos_02, axiom, ! [X1, X2]: '+'(X1, X2) = '+'(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_02)).
fof(sos_09, axiom, ! [X12, X13, X14]: ('>='(X12, X13) => '>='('+'(X12, X14), '+'(X13, X14))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_09)).
fof(sos_08, axiom, ! [X1]: '>='(X1, '0'), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_08)).
fof(sos_12, axiom, ! [X1]: '+'(X1, '1') = '1', file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_12)).
fof(sos_06, axiom, ! [X7, X8]: (('>='(X7, X8) & '>='(X8, X7)) => X7 = X8), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_06)).
fof(sos_07, axiom, ! [X9, X10, X11]: ('>='('+'(X9, X10), X11) <=> '>='(X10, '==>'(X9, X11))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_07)).
fof(sos_04, axiom, ! [X1]: '>='(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_04)).
fof(sos_13, axiom, ! [X1]: '==>'('==>'('==>'(X1, '1'), X1), X1) = '0', file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_13)).
fof(axiom_2, plain, ! [X,Y,Z] : ('>='(X,'==>'(Y,Z)) => '>='('+'(Y,X),Z)), inference(clausify, [status(thm)], [sos_07])).
fof(axiom_10, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [sos_07])).
fof(s1, plain, ! [X,Y] : '>='('+'(X,Y),'+'('0',Y)), inference(mp, [status(thm)], [sos_09, sos_08])).
fof(s2, plain, ! [X,Y] : '>='('+'(X,Y),'+'(Y,'0')), inference(rewrite, [status(thm)], [sos_02, s1])).
fof(lemma_11, lemma, ! [X,Y] : '>='('+'(X,Y),Y), inference(rewrite, [status(thm)], [sos_03, s2])).
fof(s3, plain, ! [X] : '+'('1',X) = '+'(X,'1'), inference(instantiate, [status(thm)], [sos_02])).
fof(lemma_12, lemma, ! [X] : '+'('1',X) = '1', inference(rewrite, [status(thm)], [sos_12, s3])).
fof(s4, plain, ! [X] : '>='('+'('1',X),X), inference(instantiate, [status(thm)], [lemma_11])).
fof(lemma_13, lemma, ! [X] : '>='('1',X), inference(rewrite, [status(thm)], [lemma_12, s4])).
fof(s5, plain, ! [X,Y] : '>='('==>'(X,Y),'==>'(X,Y)), inference(instantiate, [status(thm)], [sos_04])).
fof(lemma_14, lemma, ! [X,Y] : '>='('+'(X,'==>'(X,Y)),Y), inference(mp, [status(thm)], [axiom_2, s5])).
fof(s6, plain, ! [X] : '>='('1','+'(X,'==>'(X,'1'))), inference(instantiate, [status(thm)], [lemma_13])).
fof(s7, plain, ! [X] : '>='('+'(X,'==>'(X,'1')),'1'), inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_15, lemma, ! [X] : '+'(X,'==>'(X,'1')) = '1', inference(mp, [status(thm)], [sos_06, s6, s7])).
fof(s8, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='('+'(X,Z),Y)), inference(assumption, [status(thm)], [])).
fof(s9, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='(Z,'==>'(X,Y))), inference(mp, [status(thm)], [axiom_10, s8])).
fof(s10, plain, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '>='('==>'(X,Y),Z)), inference(assumption, [status(thm)], [])).
fof(lemma_16, lemma, ! [X,Y,Z] : (('>='('==>'(X,Y),Z) & '>='('+'(X,Z),Y)) => '==>'(X,Y) = Z), inference(mp, [status(thm)], [sos_06, s9, s10])).
fof(s11, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'==>'('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0)),esk1_0), inference(instantiate, [status(thm)], [lemma_14])).
fof(s12, plain, '>='('+'('==>'('==>'(esk1_0,'1'),esk1_0),'0'),esk1_0), inference(rewrite, [status(thm)], [sos_13, s11])).
fof(s13, plain, '>='('==>'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(rewrite, [status(thm)], [sos_03, s12])).
fof(s14, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),esk1_0), inference(instantiate, [status(thm)], [lemma_11])).
fof(lemma_17, lemma, '==>'('==>'(esk1_0,'1'),esk1_0) = esk1_0, inference(mp, [status(thm)], [lemma_16, s13, s14])).
fof(s15, plain, '>='('1','1'), inference(instantiate, [status(thm)], [lemma_13])).
fof(s16, plain, '>='('+'(esk1_0,'==>'(esk1_0,'1')),'1'), inference(rewrite, [status(thm)], [lemma_15, s15])).
fof(lemma_18, lemma, '>='('+'('==>'(esk1_0,'1'),esk1_0),'1'), inference(rewrite, [status(thm)], [sos_02, s16])).
fof(s17, plain, '>='('1',esk1_0), inference(instantiate, [status(thm)], [lemma_13])).
fof(s18, plain, '>='('+'('==>'(esk1_0,'1'),'==>'('==>'(esk1_0,'1'),'1')),esk1_0), inference(rewrite, [status(thm)], [lemma_15, s17])).
fof(s19, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),'==>'('==>'(esk1_0,'1'),esk1_0)), inference(mp, [status(thm)], [axiom_10, s18])).
fof(s20, plain, '>='('==>'('==>'(esk1_0,'1'),'1'),esk1_0), inference(rewrite, [status(thm)], [lemma_17, s19])).
fof(s21, plain, '>='('+'('==>'(esk1_0,'1'),esk1_0),'1'), inference(instantiate, [status(thm)], [lemma_18])).
fof(s22, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(mp, [status(thm)], [lemma_16, s20, s21])).
fof(discharged, plain, '==>'('==>'(esk1_0,'1'),'1') = esk1_0, inference(conclude, [status(thm)], [s22])).
fof(goals_14, theorem, ! [X21]: '==>'('==>'(X21, '1'), '1') = X21, inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
