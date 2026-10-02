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
fof(s4, plain, r(u(a,b,b),u(b,a,a),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_014, sos_015, sos_015])).
fof(s5, plain, r(u(a,b,b),u(b,a,a),a), inference(rewrite, [status(thm)], [sos_002, s4])).
fof(lemma_19, lemma, r(u(a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos_005, s5])).
fof(s6, plain, r(u(a,a,b),u(a,a,a),u(b,b,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_013, sos_015])).
fof(s7, plain, r(u(a,a,b),a,u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, s6])).
fof(lemma_20, lemma, r(u(a,a,b),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s7])).
fof(s8, plain, r(u(a,a,b),u(a,b,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_015])).
fof(s9, plain, r(u(a,a,b),u(a,b,a),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s8])).
fof(lemma_21, lemma, r(u(a,a,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_004, s9])).
fof(s10, plain, r(v(a,a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_015])).
fof(s11, plain, r(u(a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(rewrite, [status(thm)], [sos_009, s10])).
fof(s12, plain, r(u(a,a,b),v(b,b,a,a),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_16, s11])).
fof(s13, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, s12, lemma_21, lemma_19])).
fof(s14, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s13])).
fof(s15, plain, r(u(a,b,b),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, s14])).
fof(lemma_22, lemma, r(u(a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos, s15])).
fof(s16, plain, r(u(a,a,a),u(a,a,b),u(b,b,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_013, sos_014])).
fof(s17, plain, r(a,u(a,a,b),u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, s16])).
fof(lemma_23, lemma, r(a,u(a,a,b),u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s17])).
fof(s18, plain, r(v(a,a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_013])).
fof(s19, plain, r(u(a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s18])).
fof(s20, plain, r(a,v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s19])).
fof(s21, plain, r(m(a,u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(mp, [status(thm)], [sos_010, s20, lemma_22, lemma_19])).
fof(s22, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(rewrite, [status(thm)], [sos_001, s21])).
fof(s23, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s22])).
fof(s24, plain, r(a,u(a,a,b),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s23])).
fof(s25, plain, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, s24, lemma_23, lemma_20])).
fof(s26, plain, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s25])).
fof(s27, plain, r(u(a,a,b),m(u(a,a,b),u(a,a,b),a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s26])).
fof(lemma_24, lemma, r(u(a,a,b),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos, s27])).
fof(s28, plain, r(u(a,a,b),u(b,b,a),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_014, sos_014, sos_015])).
fof(s29, plain, r(u(a,a,b),u(b,b,a),a), inference(rewrite, [status(thm)], [sos_002, s28])).
fof(lemma_25, lemma, r(u(a,a,b),u(a,b,b),a), inference(rewrite, [status(thm)], [sos_005, s29])).
fof(s30, plain, r(v(a,a,b,b),v(b,b,a,a),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_015, sos_015])).
fof(s31, plain, r(v(a,a,b,b),v(b,b,a,a),u(a,a,a)), inference(rewrite, [status(thm)], [lemma_18, s30])).
fof(s32, plain, r(v(a,a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos_002, s31])).
fof(s33, plain, r(m(v(a,a,b,b),u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s32, lemma_22, lemma_19])).
fof(s34, plain, r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s33])).
fof(s35, plain, r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),a), inference(rewrite, [status(thm)], [sos, s34])).
fof(lemma_26, lemma, r(v(a,a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s35])).
fof(s36, plain, r(v(a,a,b,b),v(a,b,a,a),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_014, sos_015, sos_015])).
fof(s37, plain, r(v(a,a,b,b),v(a,b,a,a),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_18, s36])).
fof(s38, plain, r(v(a,a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s37])).
fof(s39, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),a,a)), inference(mp, [status(thm)], [sos_010, s38, lemma_26, lemma_19])).
fof(s40, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),m(u(a,a,b),a,a)), inference(rewrite, [status(thm)], [sos, s39])).
fof(s41, plain, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_001, s40])).
fof(lemma_27, lemma, r(u(a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos, s41])).
fof(s42, plain, r(u(a,a,a),u(a,b,b),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_014])).
fof(s43, plain, r(a,u(a,b,b),u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, s42])).
fof(s44, plain, r(a,u(a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s43])).
fof(s45, plain, r(m(a,u(a,b,b),u(a,b,b)),m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, s44, lemma_27, lemma_19])).
fof(s46, plain, r(a,m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s45])).
fof(s47, plain, r(a,u(a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s46])).
fof(lemma_28, lemma, r(a,u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s47])).
fof(s48, plain, r(v(a,b,a,a),v(a,a,b,b),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_015, sos_014, sos_014])).
fof(s49, plain, r(v(a,b,a,a),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_18, s48])).
fof(s50, plain, r(u(a,a,b),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [lemma_17, s49])).
fof(s51, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(a,a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, s50, lemma_21, lemma_19])).
fof(s52, plain, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s51])).
fof(s53, plain, r(u(a,b,b),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, s52])).
fof(lemma_29, lemma, r(u(a,b,b),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos, s53])).
fof(s54, plain, r(u(a,b,b),u(a,a,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_015, sos_015])).
fof(s55, plain, r(u(a,b,b),a,u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, s54])).
fof(lemma_30, lemma, r(u(a,b,b),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s55])).
fof(s56, plain, r(v(b,b,a,a),v(a,a,b,b),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_014, sos_014])).
fof(s57, plain, r(v(b,b,a,a),v(a,a,b,b),u(a,a,a)), inference(rewrite, [status(thm)], [lemma_18, s56])).
fof(s58, plain, r(v(b,b,a,a),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos_002, s57])).
fof(s59, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s58, lemma_29, lemma_19])).
fof(s60, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s59])).
fof(s61, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),a), inference(rewrite, [status(thm)], [sos, s60])).
fof(s62, plain, r(v(b,b,a,a),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s61])).
fof(s63, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(mp, [status(thm)], [sos_010, s62, lemma_19, lemma_30])).
fof(s64, plain, r(v(b,b,a,a),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos_001, s63])).
fof(s65, plain, r(v(b,b,a,a),a,m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos, s64])).
fof(s66, plain, r(v(b,b,a,a),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos, s65])).
fof(s67, plain, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, s66, lemma_27, lemma_19])).
fof(s68, plain, r(v(b,b,a,a),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s67])).
fof(s69, plain, r(v(b,b,a,a),a,m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s68])).
fof(lemma_31, lemma, r(v(b,b,a,a),a,a), inference(rewrite, [status(thm)], [sos, s69])).
fof(s70, plain, r(v(b,b,a,a),v(a,a,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_013, sos_013])).
fof(s71, plain, r(v(b,b,a,a),u(a,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [lemma_18, s70])).
fof(s72, plain, r(v(b,b,a,a),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s71])).
fof(s73, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, s72, lemma_24, lemma_20])).
fof(s74, plain, r(v(b,b,a,a),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos_001, s73])).
fof(s75, plain, r(v(b,b,a,a),a,m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, s74])).
fof(s76, plain, r(v(b,b,a,a),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos, s75])).
fof(s77, plain, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(mp, [status(thm)], [sos_010, s76, lemma_20, lemma_25])).
fof(s78, plain, r(v(b,b,a,a),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos_001, s77])).
fof(s79, plain, r(v(b,b,a,a),u(a,b,b),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos, s78])).
fof(s80, plain, r(v(b,b,a,a),u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s79])).
fof(s81, plain, r(m(v(b,b,a,a),a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s80, lemma_28, sos_014])).
fof(s82, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s81])).
fof(s83, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),a), inference(rewrite, [status(thm)], [sos, s82])).
fof(s84, plain, r(v(b,b,a,a),b,a), inference(rewrite, [status(thm)], [sos, s83])).
fof(s85, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),m(b,a,a),m(a,a,a)), inference(mp, [status(thm)], [sos_010, s84, lemma_31, sos_015])).
fof(s86, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s85])).
fof(s87, plain, r(m(v(b,b,a,a),v(b,b,a,a),b),b,a), inference(rewrite, [status(thm)], [sos, s86])).
fof(lemma_32, lemma, r(b,b,a), inference(rewrite, [status(thm)], [sos, s87])).
fof(s88, plain, r(m(b,b,a),m(a,b,b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, sos_015, lemma_32, sos_014])).
fof(s89, plain, r(m(b,b,a),a,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s88])).
fof(s90, plain, r(m(b,b,a),a,a), inference(rewrite, [status(thm)], [sos, s89])).
fof(goal_1, theorem, r(a,a,a), inference(rewrite, [status(thm)], [sos, s90])).
% SZS output end Proof
