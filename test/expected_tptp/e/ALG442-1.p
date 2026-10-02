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
fof(lemma_19, lemma, r(u(a,b,b),u(b,a,a),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_014, sos_015, sos_015])).
fof(s4, plain, r(u(a,b,b),u(b,a,a),a), inference(rewrite, [status(thm)], [sos_002, lemma_19])).
fof(lemma_20, lemma, r(u(a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos_005, s4])).
fof(lemma_21, lemma, r(u(a,a,b),u(a,a,a),u(b,b,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_013, sos_015])).
fof(s5, plain, r(u(a,a,b),a,u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, lemma_21])).
fof(lemma_22, lemma, r(u(a,a,b),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s5])).
fof(lemma_23, lemma, r(v(a,a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_015])).
fof(lemma_24, lemma, r(u(a,a,b),u(a,b,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_015])).
fof(s6, plain, r(u(a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(rewrite, [status(thm)], [sos_009, lemma_23])).
fof(lemma_25, lemma, r(u(a,a,b),v(b,b,a,a),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_16, s6])).
fof(s7, plain, r(u(a,a,b),u(a,b,a),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, lemma_24])).
fof(lemma_26, lemma, r(u(a,a,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_004, s7])).
fof(s8, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_25, lemma_26, lemma_20])).
fof(lemma_27, lemma, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s8])).
fof(s9, plain, r(u(a,b,b),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, lemma_27])).
fof(lemma_28, lemma, r(u(a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos, s9])).
fof(lemma_29, lemma, r(u(a,a,a),u(a,a,b),u(b,b,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_013, sos_014])).
fof(s10, plain, r(a,u(a,a,b),u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, lemma_29])).
fof(lemma_30, lemma, r(a,u(a,a,b),u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s10])).
fof(s11, plain, r(v(a,a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_013])).
fof(s12, plain, r(u(a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s11])).
fof(s13, plain, r(a,v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s12])).
fof(s14, plain, r(m(a,u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(mp, [status(thm)], [sos_010, s13, lemma_28, lemma_20])).
fof(s15, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(rewrite, [status(thm)], [sos_001, s14])).
fof(s16, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s15])).
fof(s17, plain, r(a,u(a,a,b),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s16])).
fof(s18, plain, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, s17, lemma_30, lemma_22])).
fof(lemma_31, lemma, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s18])).
fof(s19, plain, r(u(a,a,b),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, lemma_31])).
fof(lemma_32, lemma, r(u(a,a,b),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s19])).
fof(lemma_33, lemma, r(u(a,a,b),u(b,b,a),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_014, sos_014, sos_015])).
fof(s20, plain, r(u(a,a,b),u(b,b,a),a), inference(rewrite, [status(thm)], [sos_002, lemma_33])).
fof(lemma_34, lemma, r(u(a,a,b),u(a,b,b),a), inference(rewrite, [status(thm)], [sos_005, s20])).
fof(s21, plain, r(v(a,a,b,b),v(b,b,a,a),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_015, sos_015])).
fof(s22, plain, r(v(a,a,b,b),v(b,b,a,a),u(a,a,a)), inference(rewrite, [status(thm)], [lemma_18, s21])).
fof(s23, plain, r(v(a,a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos_002, s22])).
fof(s24, plain, r(m(v(a,a,b,b),u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s23, lemma_28, lemma_20])).
fof(s25, plain, r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s24])).
fof(s26, plain, r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),a), inference(rewrite, [status(thm)], [sos, s25])).
fof(lemma_35, lemma, r(v(a,a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s26])).
fof(lemma_36, lemma, r(u(a,a,a),u(a,b,b),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_014])).
fof(s27, plain, r(a,u(a,b,b),u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, lemma_36])).
fof(lemma_37, lemma, r(a,u(a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s27])).
fof(s28, plain, r(v(a,a,b,b),v(a,b,a,a),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_014, sos_015, sos_015])).
fof(s29, plain, r(v(a,a,b,b),v(a,b,a,a),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_18, s28])).
fof(s30, plain, r(v(a,a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s29])).
fof(s31, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),a,a)), inference(mp, [status(thm)], [sos_010, s30, lemma_35, lemma_20])).
fof(s32, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),m(u(a,a,b),a,a)), inference(rewrite, [status(thm)], [sos, s31])).
fof(s33, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_001, s32])).
fof(lemma_38, lemma, r(u(a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos, s33])).
fof(s34, plain, r(v(b,b,a,a),v(a,a,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_013, sos_013])).
fof(s35, plain, r(v(b,b,a,a),u(a,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s34])).
fof(s36, plain, r(v(b,b,a,a),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s35])).
fof(s37, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, s36, lemma_32, lemma_22])).
fof(s38, plain, r(v(b,b,a,a),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos_001, s37])).
fof(s39, plain, r(v(b,b,a,a),a,m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, s38])).
fof(s40, plain, r(v(b,b,a,a),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos, s39])).
fof(s41, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(mp, [status(thm)], [sos_010, s40, lemma_22, lemma_34])).
fof(lemma_39, lemma, r(v(b,b,a,a),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos_001, s41])).
fof(s42, plain, r(v(b,b,a,a),u(a,b,b),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos, lemma_39])).
fof(lemma_40, lemma, r(v(b,b,a,a),u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s42])).
fof(s43, plain, r(m(a,u(a,b,b),u(a,b,b)),m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_37, lemma_38, lemma_20])).
fof(s44, plain, r(a,m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s43])).
fof(s45, plain, r(a,u(a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s44])).
fof(lemma_41, lemma, r(a,u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s45])).
fof(s46, plain, r(v(a,b,a,a),v(a,a,b,b),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_015, sos_014, sos_014])).
fof(s47, plain, r(v(a,b,a,a),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_18, s46])).
fof(s48, plain, r(u(a,a,b),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s47])).
fof(s49, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(a,a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, s48, lemma_26, lemma_20])).
fof(lemma_42, lemma, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s49])).
fof(s50, plain, r(u(a,b,b),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, lemma_42])).
fof(lemma_43, lemma, r(u(a,b,b),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos, s50])).
fof(lemma_44, lemma, r(u(a,b,b),u(a,a,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_015, sos_015])).
fof(s51, plain, r(u(a,b,b),a,u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, lemma_44])).
fof(lemma_45, lemma, r(u(a,b,b),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s51])).
fof(s52, plain, r(v(b,b,a,a),v(a,a,b,b),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_014, sos_014])).
fof(s53, plain, r(v(b,b,a,a),v(a,a,b,b),u(a,a,a)), inference(rewrite, [status(thm)], [lemma_18, s52])).
fof(s54, plain, r(v(b,b,a,a),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos_002, s53])).
fof(s55, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s54, lemma_43, lemma_20])).
fof(s56, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s55])).
fof(s57, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),a), inference(rewrite, [status(thm)], [sos, s56])).
fof(s58, plain, r(v(b,b,a,a),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s57])).
fof(s59, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(mp, [status(thm)], [sos_010, s58, lemma_20, lemma_45])).
fof(lemma_46, lemma, r(v(b,b,a,a),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos_001, s59])).
fof(s60, plain, r(v(b,b,a,a),a,m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos, lemma_46])).
fof(lemma_47, lemma, r(v(b,b,a,a),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos, s60])).
fof(s61, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_47, lemma_38, lemma_20])).
fof(s62, plain, r(v(b,b,a,a),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s61])).
fof(s63, plain, r(v(b,b,a,a),a,m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s62])).
fof(lemma_48, lemma, r(v(b,b,a,a),a,a), inference(rewrite, [status(thm)], [sos, s63])).
fof(s64, plain, r(m(v(b,b,a,a),a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, lemma_40, lemma_41, sos_014])).
fof(s65, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s64])).
fof(s66, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),a), inference(rewrite, [status(thm)], [sos, s65])).
fof(s67, plain, r(v(b,b,a,a),b,a), inference(rewrite, [status(thm)], [sos, s66])).
fof(s68, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),m(b,a,a),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s67, lemma_48, sos_015])).
fof(s69, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s68])).
fof(s70, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,a), inference(rewrite, [status(thm)], [sos, s69])).
fof(lemma_49, lemma, r(b,b,a), inference(rewrite, [status(thm)], [sos, s70])).
fof(s71, plain, r(m(b,b,a),m(a,b,b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, sos_015, lemma_49, sos_014])).
fof(s72, plain, r(m(b,b,a),a,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s71])).
fof(s73, plain, r(m(b,b,a),a,a), inference(rewrite, [status(thm)], [sos, s72])).
fof(goal_1, theorem, r(a,a,a), inference(rewrite, [status(thm)], [sos, s73])).
% SZS output end Proof
