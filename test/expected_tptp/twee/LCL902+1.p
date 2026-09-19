% SZS output start Proof
fof(skolem_definition, definition, ? [X17]: ~ '==>'('==>'(X17, '1'), '1') = X17 => ~ '==>'('==>'(x17, '1'), '1') = x17, introduced(definition, [new_symbols(definition, [x17])], [])).
cnf(c4, axiom, '>='(A, '0'), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_08)).
fof(c5, axiom, ! [X8, X9, X10]: ('>='(X8, X9) => '>='('+'(X8, X10), '+'(X9, X10))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_09)).
fof(c9, axiom, ! [X14, X15, X16]: ('>='(X14, X15) => '>='('==>'(X16, X14), '==>'(X16, X15))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_11)).
cnf(c12, axiom, '+'(A2, '1') = '1', file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_12)).
cnf(c14, axiom, '+'(A2, B) = '+'(B, A2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_02)).
cnf(c16, axiom, '+'(A2, '0') = A2, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_03)).
cnf(c20, axiom, '>='(A2, A2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_04)).
fof(c21, axiom, ! [X5, X6, X7]: ('>='('+'(X5, X6), X7) <=> '>='(X6, '==>'(X5, X7))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_07)).
cnf(c25, axiom, '==>'('==>'('==>'(A2, '1'), A2), A2) = '0', file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_13)).
fof(c29, axiom, ! [X5_2, X6_2, X7_2]: ('>='('+'(X5_2, X6_2), X7_2) <=> '>='(X6_2, '==>'(X5_2, X7_2))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_07)).
fof(c34, axiom, ! [X3, X4]: (('>='(X3, X4) & '>='(X4, X3)) => X3 = X4), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/LCL/LCL902+1.p', sos_06)).
fof(axiom_4, plain, ! [Y,Z,A] : ('>='(Y,'==>'(Z,A)) => '>='('+'(Z,Y),A)), inference(clausify, [status(thm)], [c21])).
fof(axiom_8, plain, ! [Z,Y,A] : ('>='('+'(Z,Y),A) => '>='(Y,'==>'(Z,A))), inference(clausify, [status(thm)], [c29])).
fof(s1, plain, ! [X] : '+'('0',X) = '+'(X,'0'), inference(instantiate, [status(thm)], [c14])).
fof(lemma_12, lemma, ! [X] : '+'('0',X) = X, inference(rewrite, [status(thm)], [c16, s1])).
fof(s2, plain, '>='('==>'('==>'('==>'(x17,'1'),x17),x17),'==>'('==>'('==>'(x17,'1'),x17),x17)), inference(instantiate, [status(thm)], [c20])).
fof(lemma_13, lemma, '>='('+'('==>'('==>'(x17,'1'),x17),'==>'('==>'('==>'(x17,'1'),x17),x17)),x17), inference(mp, [status(thm)], [axiom_4, s2])).
fof(s3, plain, '>='('+'('==>'('==>'(x17,'1'),x17),'0'),x17), inference(rewrite, [status(thm)], [c25, lemma_13])).
fof(lemma_14, lemma, '>='('==>'('==>'(x17,'1'),x17),x17), inference(rewrite, [status(thm)], [c16, s3])).
fof(s4, plain, '>='('1','0'), inference(instantiate, [status(thm)], [c4])).
fof(lemma_15, lemma, ! [X] : '>='('+'('1',X),'+'('0',X)), inference(mp, [status(thm)], [c5, s4])).
fof(s5, plain, '>='('+'('1',x17),'+'('0',x17)), inference(instantiate, [status(thm)], [lemma_15])).
fof(s6, plain, ! [Z] : '>='('+'('+'(Z,'1'),x17),'+'('0',x17)), inference(rewrite, [status(thm)], [c12, s5])).
fof(s7, plain, ! [Z] : '>='('+'('+'(Z,'1'),x17),x17), inference(rewrite, [status(thm)], [lemma_12, s6])).
fof(s8, plain, '>='('+'('1',x17),x17), inference(rewrite, [status(thm)], [c12, s7])).
fof(lemma_16, lemma, '>='('+'(x17,'1'),x17), inference(rewrite, [status(thm)], [c14, s8])).
fof(s9, plain, '>='('==>'(x17,'1'),'0'), inference(instantiate, [status(thm)], [c4])).
fof(s10, plain, '>='('+'('==>'(x17,'1'),x17),'+'('0',x17)), inference(mp, [status(thm)], [c5, s9])).
fof(s11, plain, '>='(x17,'==>'('==>'(x17,'1'),'+'('0',x17))), inference(mp, [status(thm)], [axiom_8, s10])).
fof(s12, plain, '>='(x17,'==>'('==>'(x17,'1'),x17)), inference(rewrite, [status(thm)], [lemma_12, s11])).
fof(lemma_17, lemma, x17 = '==>'('==>'(x17,'1'),x17), inference(mp, [status(thm)], [c34, s12, lemma_14])).
fof(s13, plain, '>='('1',x17), inference(rewrite, [status(thm)], [c12, lemma_16])).
fof(lemma_18, lemma, ! [X] : '>='('==>'(X,'1'),'==>'(X,x17)), inference(mp, [status(thm)], [c9, s13])).
fof(s14, plain, '>='('==>'('==>'(x17,'1'),'1'),'==>'('==>'(x17,'1'),x17)), inference(instantiate, [status(thm)], [lemma_18])).
fof(lemma_19, lemma, '>='('==>'('==>'(x17,'1'),'1'),x17), inference(rewrite, [status(thm)], [lemma_17, s14])).
fof(s15, plain, '>='('==>'(x17,'1'),'==>'(x17,'1')), inference(instantiate, [status(thm)], [c20])).
fof(s16, plain, '>='('+'(x17,'==>'(x17,'1')),'1'), inference(mp, [status(thm)], [axiom_4, s15])).
fof(s17, plain, '>='('+'('==>'(x17,'1'),x17),'1'), inference(rewrite, [status(thm)], [c14, s16])).
fof(s18, plain, '>='(x17,'==>'('==>'(x17,'1'),'1')), inference(mp, [status(thm)], [axiom_8, s17])).
fof(s19, plain, '==>'('==>'(x17,'1'),'1') = x17, inference(mp, [status(thm)], [c34, s18, lemma_19])).
fof(discharged, plain, '==>'('==>'(x17,'1'),'1') = x17, inference(conclude, [status(thm)], [s19])).
fof(c1, theorem, ! [X17]: '==>'('==>'(X17, '1'), '1') = X17, inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
