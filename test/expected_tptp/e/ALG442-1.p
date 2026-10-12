% SZS output start Proof
cnf(sos_011, axiom, r(u(X1, X4, X7), u(X2, X5, X8), u(X3, X6, X9)) | ~ r(X1, X2, X3) | ~ r(X4, X5, X6) | ~ r(X7, X8, X9), file('Problems/ALG/ALG442-1.p', sos_011)).
cnf(sos_015, axiom, r(b, a, a), file('Problems/ALG/ALG442-1.p', sos_015)).
cnf(sos_012, axiom, r(v(X1, X4, X7, X10), v(X2, X5, X8, X11), v(X3, X6, X9, X12)) | ~ r(X1, X2, X3) | ~ r(X4, X5, X6) | ~ r(X7, X8, X9) | ~ r(X10, X11, X12), file('Problems/ALG/ALG442-1.p', sos_012)).
cnf(sos_010, axiom, r(m(X1, X4, X7), m(X2, X5, X8), m(X3, X6, X9)) | ~ r(X1, X2, X3) | ~ r(X4, X5, X6) | ~ r(X7, X8, X9), file('Problems/ALG/ALG442-1.p', sos_010)).
cnf(sos_014, axiom, r(a, b, a), file('Problems/ALG/ALG442-1.p', sos_014)).
cnf(sos_002, axiom, u(X1, X1, X1) = X1, file('Problems/ALG/ALG442-1.p', sos_002)).
cnf(sos_005, axiom, u(X1, X1, X2) = u(X2, X1, X1), file('Problems/ALG/ALG442-1.p', sos_005)).
cnf(sos_013, axiom, r(a, a, b), file('Problems/ALG/ALG442-1.p', sos_013)).
cnf(sos_006, axiom, v(X1, X1, X1, X2) = v(X1, X1, X2, X1), file('Problems/ALG/ALG442-1.p', sos_006)).
cnf(sos_009, axiom, u(X1, X1, X2) = v(X1, X1, X1, X2), file('Problems/ALG/ALG442-1.p', sos_009)).
cnf(sos_004, axiom, u(X1, X1, X2) = u(X1, X2, X1), file('Problems/ALG/ALG442-1.p', sos_004)).
cnf(sos_007, axiom, v(X1, X1, X2, X1) = v(X1, X2, X1, X1), file('Problems/ALG/ALG442-1.p', sos_007)).
cnf(sos_001, axiom, m(X1, X2, X2) = X1, file('Problems/ALG/ALG442-1.p', sos_001)).
cnf(sos_008, axiom, v(X1, X2, X1, X1) = v(X2, X1, X1, X1), file('Problems/ALG/ALG442-1.p', sos_008)).
cnf(sos, axiom, m(X1, X1, X2) = X2, file('Problems/ALG/ALG442-1.p', sos)).
fof(s1, plain, ! [X,Y] : v(X,X,Y,X) = v(X,X,X,Y), inference(instantiate, [status(thm)], [sos_006])).
fof(lemma_16, lemma, ! [X,Y] : v(X,X,Y,X) = u(X,X,Y), inference(rewrite, [status(thm)], [sos_009, s1])).
fof(s2, plain, ! [X,Y] : v(X,Y,X,X) = v(X,X,Y,X), inference(instantiate, [status(thm)], [sos_007])).
fof(lemma_17, lemma, ! [X,Y] : v(X,Y,X,X) = u(X,X,Y), inference(rewrite, [status(thm)], [lemma_16, s2])).
fof(s3, plain, ! [X,Y] : v(X,Y,Y,Y) = v(Y,X,Y,Y), inference(instantiate, [status(thm)], [sos_008])).
fof(lemma_18, lemma, ! [X,Y] : v(X,Y,Y,Y) = u(Y,Y,X), inference(rewrite, [status(thm)], [lemma_17, s3])).
fof(s4, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s5, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_19, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(v(A,X,a,a),v(B,Y,a,a),v(C,Z,b,b))), inference(mp, [status(thm)], [sos_012, s4, s5, sos_013, sos_013])).
fof(s6, plain, ! [X,Y,Z,A,B,C,U,V,W] : ((r(X,Y,Z) & r(A,B,C) & r(U,V,W)) => r(U,V,W)), inference(assumption, [status(thm)], [])).
fof(s7, plain, ! [X,Y,Z,A,B,C,U,V,W] : ((r(X,Y,Z) & r(A,B,C) & r(U,V,W)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s8, plain, ! [X,Y,Z,A,B,C,U,V,W] : ((r(X,Y,Z) & r(A,B,C) & r(U,V,W)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_20, lemma, ! [X,Y,Z,A,B,C,U,V,W] : ((r(X,Y,Z) & r(A,B,C) & r(U,V,W)) => r(v(U,A,X,b),v(V,B,Y,a),v(W,C,Z,a))), inference(mp, [status(thm)], [sos_012, s6, s7, s8, sos_015])).
fof(s9, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s10, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_21, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(u(A,X,b),u(B,Y,a),u(C,Z,a))), inference(mp, [status(thm)], [sos_011, s9, s10, sos_015])).
fof(s11, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_22, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(u(X,a,b),u(Y,b,a),u(Z,a,a))), inference(mp, [status(thm)], [lemma_21, sos_014, s11])).
fof(s12, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_23, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(u(X,b,b),u(Y,a,a),u(Z,a,a))), inference(mp, [status(thm)], [lemma_21, sos_015, s12])).
fof(s13, plain, r(u(a,b,b),u(b,a,a),u(a,a,a)), inference(mp, [status(thm)], [lemma_23, sos_014])).
fof(s14, plain, r(u(a,b,b),u(b,a,a),a), inference(rewrite, [status(thm)], [sos_002, s13])).
fof(lemma_24, lemma, r(u(a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos_005, s14])).
fof(s15, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s16, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_25, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(m(A,X,u(a,b,b)),m(B,Y,u(a,a,b)),m(C,Z,a))), inference(mp, [status(thm)], [sos_010, s15, s16, lemma_24])).
fof(s17, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,a,b),u(a,b,a),u(b,a,a))), inference(mp, [status(thm)], [lemma_22, sos_013])).
fof(s18, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,a,b),u(a,b,a),u(a,a,b))), inference(rewrite, [status(thm)], [sos_005, s17])).
fof(s19, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,a,b),u(a,a,b),u(a,a,b))), inference(rewrite, [status(thm)], [sos_004, s18])).
fof(s20, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s21, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(X,u(a,a,b),u(a,b,b)),m(Y,u(a,a,b),u(a,a,b)),m(Z,u(a,a,b),a))), inference(mp, [status(thm)], [lemma_25, s19, s20])).
fof(lemma_26, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(m(X,u(a,a,b),u(a,b,b)),Y,m(Z,u(a,a,b),a))), inference(rewrite, [status(thm)], [sos_001, s21])).
fof(s22, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(a,a,a,b),v(b,b,a,a),v(a,a,b,a))), inference(mp, [status(thm)], [lemma_20, sos_013, sos_014, sos_014])).
fof(s23, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,a,b),v(b,b,a,a),v(a,a,b,a))), inference(rewrite, [status(thm)], [sos_009, s22])).
fof(s24, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,a,b),v(b,b,a,a),u(a,a,b))), inference(rewrite, [status(thm)], [lemma_16, s23])).
fof(s25, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a))), inference(mp, [status(thm)], [lemma_26, s24])).
fof(s26, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,b,b),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a))), inference(rewrite, [status(thm)], [sos, s25])).
fof(s27, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,b,b),v(b,b,a,a),a)), inference(rewrite, [status(thm)], [sos, s26])).
fof(s28, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s29, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(X,u(a,b,b),u(a,b,b)),m(Y,v(b,b,a,a),u(a,a,b)),m(Z,a,a))), inference(mp, [status(thm)], [lemma_25, s27, s28])).
fof(s30, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,m(Y,v(b,b,a,a),u(a,a,b)),m(Z,a,a))), inference(rewrite, [status(thm)], [sos_001, s29])).
fof(lemma_27, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(X,m(Y,v(b,b,a,a),u(a,a,b)),Z)), inference(rewrite, [status(thm)], [sos_001, s30])).
fof(s31, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s32, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_28, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(u(A,X,a),u(B,Y,b),u(C,Z,a))), inference(mp, [status(thm)], [sos_011, s31, s32, sos_014])).
fof(s33, plain, r(u(a,a,b),u(a,a,a),u(b,b,a)), inference(mp, [status(thm)], [lemma_21, sos_013, sos_013])).
fof(s34, plain, r(u(a,a,b),a,u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, s33])).
fof(lemma_29, lemma, r(u(a,a,b),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s34])).
fof(s35, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s36, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_30, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(m(A,X,u(a,a,b)),m(B,Y,a),m(C,Z,u(a,b,b)))), inference(mp, [status(thm)], [sos_010, s35, s36, lemma_29])).
fof(s37, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s38, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(X,a,b,b),v(Y,b,a,a),v(Z,a,a,a))), inference(mp, [status(thm)], [lemma_20, sos_015, sos_014, s37])).
fof(lemma_31, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(v(X,a,b,b),v(Y,b,a,a),u(a,a,Z))), inference(rewrite, [status(thm)], [lemma_18, s38])).
fof(s39, plain, r(v(a,a,b,b),v(a,b,a,a),u(a,a,b)), inference(mp, [status(thm)], [lemma_31, sos_013])).
fof(lemma_32, lemma, r(v(a,a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s39])).
fof(s40, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(a,a,b,b),v(b,b,a,a),u(a,a,a))), inference(mp, [status(thm)], [lemma_31, sos_014])).
fof(s41, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(a,a,b,b),v(b,b,a,a),a)), inference(rewrite, [status(thm)], [sos_002, s40])).
fof(s42, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),a)), inference(mp, [status(thm)], [lemma_27, s41])).
fof(s43, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(a,a,b,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, s42])).
fof(s44, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),a,a))), inference(mp, [status(thm)], [lemma_25, s43, lemma_32])).
fof(s45, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),m(u(a,a,b),a,a))), inference(rewrite, [status(thm)], [sos_001, s44])).
fof(s46, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),u(a,a,b))), inference(rewrite, [status(thm)], [sos_001, s45])).
fof(s47, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(u(a,b,b),u(a,a,b),u(a,a,b))), inference(rewrite, [status(thm)], [sos, s46])).
fof(s48, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s49, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(m(X,u(a,b,b),u(a,b,b)),m(Y,u(a,a,b),u(a,a,b)),m(Z,u(a,a,b),a))), inference(mp, [status(thm)], [lemma_25, s47, s48])).
fof(s50, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,m(Y,u(a,a,b),u(a,a,b)),m(Z,u(a,a,b),a))), inference(rewrite, [status(thm)], [sos_001, s49])).
fof(lemma_33, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,m(Z,u(a,a,b),a))), inference(rewrite, [status(thm)], [sos_001, s50])).
fof(s51, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(A,B,C)), inference(assumption, [status(thm)], [])).
fof(s52, plain, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_34, lemma, ! [X,Y,Z,A,B,C] : ((r(X,Y,Z) & r(A,B,C)) => r(m(A,X,a),m(B,Y,b),m(C,Z,a))), inference(mp, [status(thm)], [sos_010, s51, s52, sos_014])).
fof(s53, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s54, plain, ! [X,Y,Z] : (r(X,Y,Z) => r(v(X,b,a,a),v(Y,a,b,b),v(Z,a,a,a))), inference(mp, [status(thm)], [sos_012, s53, sos_015, sos_014, sos_014])).
fof(lemma_35, lemma, ! [X,Y,Z] : (r(X,Y,Z) => r(v(X,b,a,a),v(Y,a,b,b),u(a,a,Z))), inference(rewrite, [status(thm)], [lemma_18, s54])).
fof(s55, plain, r(v(a,a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [lemma_19, sos_014, sos_014])).
fof(s56, plain, r(u(a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s55])).
fof(s57, plain, r(a,v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s56])).
fof(s58, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),v(a,a,b,b)), inference(mp, [status(thm)], [lemma_27, s57])).
fof(lemma_36, lemma, r(a,u(a,a,b),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s58])).
fof(s59, plain, r(v(b,b,a,a),v(a,a,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [lemma_19, sos_015, sos_015])).
fof(s60, plain, r(v(b,b,a,a),u(a,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s59])).
fof(lemma_37, lemma, r(v(b,b,a,a),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s60])).
fof(s61, plain, r(u(a,a,b),u(b,b,a),u(a,a,a)), inference(mp, [status(thm)], [lemma_22, sos_014])).
fof(s62, plain, r(u(a,a,b),u(b,b,a),a), inference(rewrite, [status(thm)], [sos_002, s61])).
fof(lemma_38, lemma, r(u(a,a,b),u(a,b,b),a), inference(rewrite, [status(thm)], [sos_005, s62])).
fof(s63, plain, r(u(a,a,a),u(a,a,b),u(b,b,a)), inference(mp, [status(thm)], [lemma_28, sos_013, sos_013])).
fof(s64, plain, r(a,u(a,a,b),u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, s63])).
fof(s65, plain, r(a,u(a,a,b),u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s64])).
fof(s66, plain, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(mp, [status(thm)], [lemma_30, s65, lemma_36])).
fof(s67, plain, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s66])).
fof(s68, plain, r(u(a,a,b),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s67])).
fof(s69, plain, r(u(a,a,b),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s68])).
fof(s70, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(mp, [status(thm)], [lemma_30, s69, lemma_37])).
fof(s71, plain, r(v(b,b,a,a),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos_001, s70])).
fof(s72, plain, r(v(b,b,a,a),a,m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, s71])).
fof(s73, plain, r(v(b,b,a,a),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos, s72])).
fof(s74, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(mp, [status(thm)], [sos_010, s73, lemma_29, lemma_38])).
fof(s75, plain, r(v(b,b,a,a),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos_001, s74])).
fof(s76, plain, r(v(b,b,a,a),u(a,b,b),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos, s75])).
fof(lemma_39, lemma, r(v(b,b,a,a),u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s76])).
fof(s77, plain, r(v(b,b,a,a),v(a,a,b,b),u(a,a,a)), inference(mp, [status(thm)], [lemma_35, sos_015])).
fof(lemma_40, lemma, r(v(b,b,a,a),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos_002, s77])).
fof(s78, plain, r(u(a,b,b),u(a,a,a),u(b,a,a)), inference(mp, [status(thm)], [lemma_23, sos_013])).
fof(s79, plain, r(u(a,b,b),a,u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, s78])).
fof(lemma_41, lemma, r(u(a,b,b),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s79])).
fof(s80, plain, r(v(a,b,a,a),v(a,a,b,b),u(a,a,b)), inference(mp, [status(thm)], [lemma_35, sos_013])).
fof(s81, plain, r(u(a,a,b),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s80])).
fof(s82, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [lemma_26, s81])).
fof(s83, plain, r(u(a,b,b),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, s82])).
fof(s84, plain, r(u(a,b,b),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos, s83])).
fof(s85, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [lemma_25, s84, lemma_40])).
fof(s86, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s85])).
fof(s87, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),a), inference(rewrite, [status(thm)], [sos, s86])).
fof(s88, plain, r(v(b,b,a,a),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s87])).
fof(s89, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(mp, [status(thm)], [sos_010, s88, lemma_24, lemma_41])).
fof(s90, plain, r(v(b,b,a,a),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos_001, s89])).
fof(s91, plain, r(v(b,b,a,a),a,m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos, s90])).
fof(s92, plain, r(v(b,b,a,a),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos, s91])).
fof(s93, plain, r(v(b,b,a,a),a,m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [lemma_33, s92])).
fof(lemma_42, lemma, r(v(b,b,a,a),a,a), inference(rewrite, [status(thm)], [sos, s93])).
fof(s94, plain, r(u(a,a,a),u(a,b,b),u(b,a,a)), inference(mp, [status(thm)], [lemma_28, sos_014, sos_013])).
fof(s95, plain, r(a,u(a,b,b),u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, s94])).
fof(s96, plain, r(a,u(a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s95])).
fof(s97, plain, r(a,u(a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [lemma_33, s96])).
fof(s98, plain, r(a,u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s97])).
fof(s99, plain, r(m(v(b,b,a,a),a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(mp, [status(thm)], [lemma_34, s98, lemma_39])).
fof(s100, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s99])).
fof(s101, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),a), inference(rewrite, [status(thm)], [sos, s100])).
fof(s102, plain, r(v(b,b,a,a),b,a), inference(rewrite, [status(thm)], [sos, s101])).
fof(s103, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),m(b,a,a),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s102, lemma_42, sos_015])).
fof(s104, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s103])).
fof(s105, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,a), inference(rewrite, [status(thm)], [sos, s104])).
fof(s106, plain, r(b,b,a), inference(rewrite, [status(thm)], [sos, s105])).
fof(s107, plain, r(m(b,b,a),m(a,b,b),m(a,a,a)), inference(mp, [status(thm)], [lemma_34, s106, sos_015])).
fof(s108, plain, r(m(b,b,a),a,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s107])).
fof(s109, plain, r(m(b,b,a),a,a), inference(rewrite, [status(thm)], [sos, s108])).
fof(goal_1, theorem, r(a,a,a), inference(rewrite, [status(thm)], [sos, s109])).
% SZS output end Proof
