% SZS output start Proof
cnf(c2, axiom, '+'(A, ' = =>'(A, B)) = '+'(B, ' = =>'(B, A)), file('TPTP/Problems/LCL/LCL897-10.p', sos_08)).
cnf(c3, axiom, ' = =>'('+'(A2, B2), C) = ' = =>'(A2, ' = =>'(B2, C)), file('TPTP/Problems/LCL/LCL897-10.p', sos_07)).
cnf(c5, axiom, '+'(A2, B2) = '+'(B2, A2), file('TPTP/Problems/LCL/LCL897-10.p', sos_02)).
cnf(c9, axiom, '+'(A2, '0') = A2, file('TPTP/Problems/LCL/LCL897-10.p', sos_03)).
cnf(c11, axiom, ' = =>'(A2, A2) = '0', file('TPTP/Problems/LCL/LCL897-10.p', sos_04)).
cnf(c23, axiom, ' = =>'(A2, '0') = '0', file('TPTP/Problems/LCL/LCL897-10.p', sos_05)).
cnf(c31, axiom, '+'('+'(A2, B2), C2) = '+'(A2, '+'(B2, C2)), file('TPTP/Problems/LCL/LCL897-10.p', sos_01)).
fof(s1, plain, ! [X,Y,Z] : ' = =>'('+'(X,' = =>'(X,Y)),Z) = ' = =>'('+'(Y,' = =>'(Y,X)),Z), inference(instantiate, [status(thm)], [c2])).
fof(lemma_8, lemma, ! [X,Y,Z] : ' = =>'('+'(X,' = =>'(X,Y)),Z) = ' = =>'(Y,' = =>'(' = =>'(Y,X),Z)), inference(rewrite, [status(thm)], [c3, s1])).
fof(s2, plain, ! [X,Y,Z] : ' = =>'(X,' = =>'(Y,Z)) = ' = =>'('+'(X,Y),Z), inference(instantiate, [status(thm)], [c3])).
fof(s3, plain, ! [X,Y,Z] : ' = =>'(X,' = =>'(Y,Z)) = ' = =>'('+'(Y,X),Z), inference(rewrite, [status(thm)], [c5, s2])).
fof(lemma_9, lemma, ! [X,Y,Z] : ' = =>'(X,' = =>'(Y,Z)) = ' = =>'(Y,' = =>'(X,Z)), inference(rewrite, [status(thm)], [c3, s3])).
fof(s4, plain, ! [X,Y,Z] : ' = =>'('+'(X,Y),Z) = ' = =>'('+'(Y,X),Z), inference(instantiate, [status(thm)], [c5])).
fof(lemma_10, lemma, ! [X,Y,Z] : ' = =>'('+'(X,Y),Z) = ' = =>'(Y,' = =>'(X,Z)), inference(rewrite, [status(thm)], [c3, s4])).
fof(s5, plain, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'(X,'+'(Z,Y)), inference(instantiate, [status(thm)], [c5])).
fof(s6, plain, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'('+'(Z,Y),X), inference(rewrite, [status(thm)], [c5, s5])).
fof(s7, plain, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'(Z,'+'(Y,X)), inference(rewrite, [status(thm)], [c31, s6])).
fof(lemma_11, lemma, ! [X,Y,Z] : '+'(X,'+'(Y,Z)) = '+'(Z,'+'(X,Y)), inference(rewrite, [status(thm)], [c5, s7])).
fof(s8, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(b,' = =>'(' = =>'(b,a),c))), inference(instantiate, [status(thm)], [lemma_8])).
fof(s9, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),' = =>'(b,c))), inference(rewrite, [status(thm)], [lemma_9, s8])).
fof(s10, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,c),'0'))), inference(rewrite, [status(thm)], [c9, s9])).
fof(s11, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,c),' = =>'('+'(b,' = =>'(b,c)),'+'(b,' = =>'(b,c)))))), inference(rewrite, [status(thm)], [c11, s10])).
fof(s12, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,c),' = =>'(' = =>'(b,c),' = =>'(b,'+'(b,' = =>'(b,c))))))), inference(rewrite, [status(thm)], [lemma_10, s11])).
fof(s13, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(b,c))))), inference(rewrite, [status(thm)], [c2, s12])).
fof(s14, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(b,' = =>'(' = =>'(b,'+'(b,' = =>'(b,c))),c))))), inference(rewrite, [status(thm)], [lemma_9, s13])).
fof(s15, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'('+'(b,' = =>'(b,'+'(b,' = =>'(b,c)))),c)))), inference(rewrite, [status(thm)], [c3, s14])).
fof(s16, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'('+'('+'(b,' = =>'(b,c)),' = =>'('+'(b,' = =>'(b,c)),b)),c)))), inference(rewrite, [status(thm)], [c2, s15])).
fof(s17, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'('+'(b,' = =>'(b,c)),' = =>'(' = =>'('+'(b,' = =>'(b,c)),b),c))))), inference(rewrite, [status(thm)], [c3, s16])).
fof(s18, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(' = =>'('+'(b,' = =>'(b,c)),b),' = =>'('+'(b,' = =>'(b,c)),c))))), inference(rewrite, [status(thm)], [lemma_9, s17])).
fof(s19, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(' = =>'('+'(b,' = =>'(b,c)),b),' = =>'(' = =>'(b,c),' = =>'(b,c)))))), inference(rewrite, [status(thm)], [lemma_10, s18])).
fof(s20, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),' = =>'(' = =>'('+'(b,' = =>'(b,c)),b),'0')))), inference(rewrite, [status(thm)], [c11, s19])).
fof(s21, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),'+'(' = =>'(b,'+'(b,' = =>'(b,c))),'0'))), inference(rewrite, [status(thm)], [c23, s20])).
fof(s22, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(b,a),' = =>'(b,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c9, s21])).
fof(s23, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(b,' = =>'(' = =>'(b,a),'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [lemma_9, s22])).
fof(s24, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),'+'(b,' = =>'(b,c)))), inference(rewrite, [status(thm)], [lemma_8, s23])).
fof(s25, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,b)),' = =>'(' = =>'(a,b),' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [lemma_10, s24])).
fof(s26, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(' = =>'(a,b),' = =>'(a,'+'(b,' = =>'(b,c)))),'+'(a,' = =>'(a,b))), inference(rewrite, [status(thm)], [c5, s25])).
fof(s27, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(a,b),'+'(' = =>'(' = =>'(a,b),' = =>'(a,'+'(b,' = =>'(b,c)))),a)), inference(rewrite, [status(thm)], [lemma_11, s26])).
fof(s28, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(' = =>'(a,b),' = =>'(' = =>'(a,b),' = =>'(a,'+'(b,' = =>'(b,c))))),a), inference(rewrite, [status(thm)], [c31, s27])).
fof(s29, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(' = =>'(a,'+'(b,' = =>'(b,c))),' = =>'(' = =>'(a,'+'(b,' = =>'(b,c))),' = =>'(a,b))),a), inference(rewrite, [status(thm)], [c2, s28])).
fof(s30, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(a,'+'(b,' = =>'(b,c))),'+'(' = =>'(' = =>'(a,'+'(b,' = =>'(b,c))),' = =>'(a,b)),a)), inference(rewrite, [status(thm)], [c31, s29])).
fof(s31, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(a,'+'(b,' = =>'(b,c))),'+'(a,' = =>'(' = =>'(a,'+'(b,' = =>'(b,c))),' = =>'(a,b)))), inference(rewrite, [status(thm)], [c5, s30])).
fof(s32, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(a,'+'(b,' = =>'(b,c))),'+'(a,' = =>'('+'(a,' = =>'(a,'+'(b,' = =>'(b,c)))),b))), inference(rewrite, [status(thm)], [lemma_10, s31])).
fof(s33, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(a,'+'(b,' = =>'(b,c))),'+'(' = =>'('+'(a,' = =>'(a,'+'(b,' = =>'(b,c)))),b),a)), inference(rewrite, [status(thm)], [c5, s32])).
fof(s34, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'('+'(a,' = =>'(a,'+'(b,' = =>'(b,c)))),b),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [lemma_11, s33])).
fof(s35, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'('+'('+'(b,' = =>'(b,c)),' = =>'('+'(b,' = =>'(b,c)),a)),b),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c2, s34])).
fof(s36, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'('+'(b,' = =>'(b,c)),' = =>'(' = =>'('+'(b,' = =>'(b,c)),a),b)),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c3, s35])).
fof(s37, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(' = =>'('+'(b,' = =>'(b,c)),a),' = =>'('+'(b,' = =>'(b,c)),b)),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [lemma_9, s36])).
fof(s38, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(' = =>'('+'(b,' = =>'(b,c)),a),' = =>'(' = =>'(b,c),' = =>'(b,b))),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [lemma_10, s37])).
fof(s39, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(' = =>'('+'(b,' = =>'(b,c)),a),' = =>'(' = =>'(b,c),'0')),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c11, s38])).
fof(s40, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(' = =>'(' = =>'('+'(b,' = =>'(b,c)),a),'0'),'+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c23, s39])).
fof(s41, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('0','+'(a,' = =>'(a,'+'(b,' = =>'(b,c))))), inference(rewrite, [status(thm)], [c23, s40])).
fof(s42, plain, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'('+'(a,' = =>'(a,'+'(b,' = =>'(b,c)))),'0'), inference(rewrite, [status(thm)], [c5, s41])).
fof(goal_1, theorem, '+'('+'(a,' = =>'(a,b)),' = =>'('+'(a,' = =>'(a,b)),c)) = '+'(a,' = =>'(a,'+'(b,' = =>'(b,c)))), inference(rewrite, [status(thm)], [c9, s42])).
% SZS output end Proof
