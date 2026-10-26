% SZS output start Proof
fof(f2, axiom, ! [X0, X1]: '+'(X0, X1) = '+'(X1, X0), file('Problems/LCL/LCL902+1.p', sos_02)).
fof(f3, axiom, ! [X0]: '+'(X0, '0') = X0, file('Problems/LCL/LCL902+1.p', sos_03)).
fof(f4, axiom, ! [X0]: '>='(X0, X0), file('Problems/LCL/LCL902+1.p', sos_04)).
fof(f5, axiom, ! [X3, X4, X5]: (('>='(X4, X5) & '>='(X3, X4)) => '>='(X3, X5)), file('Problems/LCL/LCL902+1.p', sos_05)).
fof(f6, axiom, ! [X6, X7]: (('>='(X7, X6) & '>='(X6, X7)) => X6 = X7), file('Problems/LCL/LCL902+1.p', sos_06)).
fof(f7, axiom, ! [X8, X9, X10]: ('>='('+'(X8, X9), X10) <=> '>='(X9, '==>'(X8, X10))), file('Problems/LCL/LCL902+1.p', sos_07)).
fof(f8, axiom, ! [X0]: '>='(X0, '0'), file('Problems/LCL/LCL902+1.p', sos_08)).
fof(f12, axiom, ! [X0]: '1' = '+'(X0, '1'), file('Problems/LCL/LCL902+1.p', sos_12)).
fof(f13, axiom, ! [X0]: '0' = '==>'('==>'('==>'(X0, '1'), X0), X0), file('Problems/LCL/LCL902+1.p', sos_13)).
fof(f32, plain, ? [X0]: '==>'('==>'(X0, '1'), '1') != X0 => sK0 != '==>'('==>'(sK0, '1'), '1'), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(axiom_2, plain, ! [X,Y,Z] : ('>='(X,'==>'(Y,Z)) => '>='('+'(Y,X),Z)), inference(clausify, [status(thm)], [f7])).
fof(axiom_7, plain, ! [X,Y,Z] : ('>='('+'(X,Y),Z) => '>='(Y,'==>'(X,Z))), inference(clausify, [status(thm)], [f7])).
fof(s1, plain, ! [X,Y] : '>='('==>'(X,Y),'==>'(X,Y)), inference(instantiate, [status(thm)], [f4])).
fof(lemma_11, lemma, ! [X,Y] : '>='('+'(X,'==>'(X,Y)),Y), inference(mp, [status(thm)], [axiom_2, s1])).
fof(s2, plain, ! [X] : '+'('1',X) = '+'(X,'1'), inference(instantiate, [status(thm)], [f2])).
fof(lemma_12, lemma, ! [X] : '+'('1',X) = '1', inference(rewrite, [status(thm)], [f12, s2])).
fof(s3, plain, ! [X] : '>='('+'('1','==>'('1',X)),X), inference(instantiate, [status(thm)], [lemma_11])).
fof(lemma_13, lemma, ! [X] : '>='('1',X), inference(rewrite, [status(thm)], [lemma_12, s3])).
fof(s4, plain, ! [X] : '>='('+'(X,'==>'(X,'1')),'1'), inference(instantiate, [status(thm)], [lemma_11])).
fof(lemma_14, lemma, ! [X,Y] : '>='('+'(X,'==>'(X,'1')),Y), inference(mp, [status(thm)], [f5, lemma_13, s4])).
fof(s5, plain, ! [Y,X] : '>='('+'(Y,X),'+'(Y,X)), inference(instantiate, [status(thm)], [f4])).
fof(lemma_15, lemma, ! [X,Y] : '>='(X,'==>'(Y,'+'(Y,X))), inference(mp, [status(thm)], [axiom_7, s5])).
fof(s6, plain, '>='('0','==>'(sK0,'+'(sK0,'0'))), inference(instantiate, [status(thm)], [lemma_15])).
fof(s7, plain, '>='('0','==>'(sK0,sK0)), inference(rewrite, [status(thm)], [f3, s6])).
fof(s8, plain, '>='('==>'(sK0,'1'),'0'), inference(instantiate, [status(thm)], [f8])).
fof(s9, plain, '>='('==>'(sK0,'1'),'==>'(sK0,sK0)), inference(mp, [status(thm)], [f5, s7, s8])).
fof(s10, plain, '>='('+'(sK0,'==>'(sK0,'1')),sK0), inference(mp, [status(thm)], [axiom_2, s9])).
fof(s11, plain, '>='('+'('==>'(sK0,'1'),sK0),sK0), inference(rewrite, [status(thm)], [f2, s10])).
fof(lemma_16, lemma, '>='(sK0,'==>'('==>'(sK0,'1'),sK0)), inference(mp, [status(thm)], [axiom_7, s11])).
fof(s12, plain, '>='('0','0'), inference(instantiate, [status(thm)], [f8])).
fof(s13, plain, '>='('0','==>'('==>'('==>'(sK0,'1'),sK0),sK0)), inference(rewrite, [status(thm)], [f13, s12])).
fof(s14, plain, '>='('+'('==>'('==>'(sK0,'1'),sK0),'0'),sK0), inference(mp, [status(thm)], [axiom_2, s13])).
fof(s15, plain, '>='('==>'('==>'(sK0,'1'),sK0),sK0), inference(rewrite, [status(thm)], [f3, s14])).
fof(s16, plain, '>='(sK0,'==>'('==>'(sK0,'1'),sK0)), inference(instantiate, [status(thm)], [lemma_16])).
fof(lemma_17, lemma, sK0 = '==>'('==>'(sK0,'1'),sK0), inference(mp, [status(thm)], [f6, s15, s16])).
fof(s17, plain, '>='('1','+'(sK0,'==>'(sK0,'1'))), inference(instantiate, [status(thm)], [lemma_13])).
fof(s18, plain, '>='('+'(sK0,'==>'(sK0,'1')),'1'), inference(instantiate, [status(thm)], [lemma_14])).
fof(lemma_18, lemma, '+'(sK0,'==>'(sK0,'1')) = '1', inference(mp, [status(thm)], [f6, s17, s18])).
fof(s19, plain, '>='(sK0,'==>'('==>'(sK0,'1'),'+'('==>'(sK0,'1'),sK0))), inference(instantiate, [status(thm)], [lemma_15])).
fof(s20, plain, '>='(sK0,'==>'('==>'(sK0,'1'),'+'(sK0,'==>'(sK0,'1')))), inference(rewrite, [status(thm)], [f2, s19])).
fof(lemma_19, lemma, '>='(sK0,'==>'('==>'(sK0,'1'),'1')), inference(rewrite, [status(thm)], [lemma_18, s20])).
fof(s21, plain, '>='('+'('==>'(sK0,'1'),'==>'('==>'(sK0,'1'),'1')),sK0), inference(instantiate, [status(thm)], [lemma_14])).
fof(s22, plain, '>='('==>'('==>'(sK0,'1'),'1'),'==>'('==>'(sK0,'1'),sK0)), inference(mp, [status(thm)], [axiom_7, s21])).
fof(s23, plain, '>='('==>'('==>'(sK0,'1'),'1'),sK0), inference(rewrite, [status(thm)], [lemma_17, s22])).
fof(s24, plain, '>='(sK0,'==>'('==>'(sK0,'1'),'1')), inference(instantiate, [status(thm)], [lemma_19])).
fof(s25, plain, '==>'('==>'(sK0,'1'),'1') = sK0, inference(mp, [status(thm)], [f6, s23, s24])).
fof(discharged, plain, '==>'('==>'(sK0,'1'),'1') = sK0, inference(conclude, [status(thm)], [s25])).
fof(f14, theorem, ! [X20]: '==>'('==>'(X20, '1'), '1') = X20, inference(generalization, [status(thm)], [discharged, f32])).
% SZS output end Proof
