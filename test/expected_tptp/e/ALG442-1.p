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
fof(lemma_16, lemma, r(u(b,b,a),u(a,a,b),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_015, sos_015, sos_014])).
fof(s1, plain, r(u(a,b,b),u(a,a,b),u(a,a,a)), inference(rewrite, [status(thm)], [sos_005, lemma_16])).
fof(lemma_17, lemma, r(u(a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos_002, s1])).
fof(lemma_18, lemma, r(u(b,a,a),u(a,a,a),u(a,b,b)), inference(mp, [status(thm)], [sos_011, sos_015, sos_013, sos_013])).
fof(s2, plain, r(u(a,a,b),u(a,a,a),u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, lemma_18])).
fof(lemma_19, lemma, r(u(a,a,b),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos_002, s2])).
fof(lemma_20, lemma, r(v(a,a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_015])).
fof(lemma_21, lemma, r(u(a,a,b),u(a,b,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_015])).
fof(s3, plain, r(u(a,a,b),v(b,b,a,a),v(a,a,b,a)), inference(rewrite, [status(thm)], [sos_009, lemma_20])).
fof(s4, plain, r(u(a,a,b),v(b,b,a,a),v(a,a,a,b)), inference(rewrite, [status(thm)], [sos_006, s3])).
fof(lemma_22, lemma, r(u(a,a,b),v(b,b,a,a),u(a,a,b)), inference(rewrite, [status(thm)], [sos_009, s4])).
fof(s5, plain, r(u(a,a,b),u(a,b,a),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, lemma_21])).
fof(lemma_23, lemma, r(u(a,a,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_004, s5])).
fof(lemma_24, lemma, r(v(a,a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_013, sos_013])).
fof(lemma_25, lemma, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_22, lemma_23, lemma_17])).
fof(s6, plain, r(u(a,a,a),v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_009, lemma_24])).
fof(lemma_26, lemma, r(a,v(b,b,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s6])).
fof(s7, plain, r(u(a,b,b),m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, lemma_25])).
fof(s8, plain, r(u(a,b,b),v(b,b,a,a),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s7])).
fof(lemma_27, lemma, r(u(a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos, s8])).
fof(lemma_28, lemma, r(m(a,u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(mp, [status(thm)], [sos_010, lemma_26, lemma_27, lemma_17])).
fof(lemma_29, lemma, r(u(a,a,a),u(a,a,b),u(b,b,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_013, sos_014])).
fof(s9, plain, r(a,m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(v(a,a,b,b),a,a)), inference(rewrite, [status(thm)], [sos_001, lemma_28])).
fof(s10, plain, r(a,u(a,a,b),m(v(a,a,b,b),a,a)), inference(rewrite, [status(thm)], [sos, s9])).
fof(lemma_30, lemma, r(a,u(a,a,b),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s10])).
fof(s11, plain, r(a,u(a,a,b),u(b,b,a)), inference(rewrite, [status(thm)], [sos_002, lemma_29])).
fof(lemma_31, lemma, r(a,u(a,a,b),u(a,b,b)), inference(rewrite, [status(thm)], [sos_005, s11])).
fof(lemma_32, lemma, r(v(b,b,a,a),v(a,a,a,a),v(a,a,b,b)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_013, sos_013])).
fof(lemma_33, lemma, r(m(a,a,u(a,a,b)),m(u(a,a,b),u(a,a,b),a),m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, lemma_30, lemma_31, lemma_19])).
fof(s12, plain, r(v(b,b,a,a),u(a,a,a),v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_009, lemma_32])).
fof(lemma_34, lemma, r(v(b,b,a,a),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_002, s12])).
fof(s13, plain, r(u(a,a,b),m(u(a,a,b),u(a,a,b),a),m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, lemma_33])).
fof(s14, plain, r(u(a,a,b),a,m(v(a,a,b,b),u(a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, s13])).
fof(lemma_35, lemma, r(u(a,a,b),a,v(a,a,b,b)), inference(rewrite, [status(thm)], [sos_001, s14])).
fof(lemma_36, lemma, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(mp, [status(thm)], [sos_010, lemma_34, lemma_35, lemma_19])).
fof(lemma_37, lemma, r(u(a,a,b),u(b,b,a),u(a,a,a)), inference(mp, [status(thm)], [sos_011, sos_014, sos_014, sos_015])).
fof(s15, plain, r(v(b,b,a,a),m(a,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos_001, lemma_36])).
fof(s16, plain, r(v(b,b,a,a),a,m(v(a,a,b,b),v(a,a,b,b),u(a,b,b))), inference(rewrite, [status(thm)], [sos, s15])).
fof(lemma_38, lemma, r(v(b,b,a,a),a,u(a,b,b)), inference(rewrite, [status(thm)], [sos, s16])).
fof(s17, plain, r(u(a,a,b),u(a,b,b),u(a,a,a)), inference(rewrite, [status(thm)], [sos_005, lemma_37])).
fof(lemma_39, lemma, r(u(a,a,b),u(a,b,b),a), inference(rewrite, [status(thm)], [sos_002, s17])).
fof(lemma_40, lemma, r(v(a,a,b,b),v(b,b,a,a),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_014, sos_014, sos_015, sos_015])).
fof(s18, plain, r(v(a,a,b,b),v(b,b,a,a),u(a,a,a)), inference(rewrite, [status(thm)], [sos_009, lemma_40])).
fof(lemma_41, lemma, r(v(a,a,b,b),v(b,b,a,a),a), inference(rewrite, [status(thm)], [sos_002, s18])).
fof(lemma_42, lemma, r(v(a,a,b,b),v(a,b,a,a),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_014, sos_015, sos_015])).
fof(lemma_43, lemma, r(m(v(a,a,b,b),u(a,b,b),u(a,b,b)),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, lemma_41, lemma_27, lemma_17])).
fof(s19, plain, r(v(a,a,b,b),v(a,a,b,a),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_007, lemma_42])).
fof(s20, plain, r(v(a,a,b,b),v(a,a,a,b),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_006, s19])).
fof(s21, plain, r(v(a,a,b,b),u(a,a,b),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_009, s20])).
fof(s22, plain, r(v(a,a,b,b),u(a,a,b),v(a,b,a,a)), inference(rewrite, [status(thm)], [sos_008, s21])).
fof(s23, plain, r(v(a,a,b,b),u(a,a,b),v(a,a,b,a)), inference(rewrite, [status(thm)], [sos_007, s22])).
fof(s24, plain, r(v(a,a,b,b),u(a,a,b),v(a,a,a,b)), inference(rewrite, [status(thm)], [sos_006, s23])).
fof(lemma_44, lemma, r(v(a,a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_009, s24])).
fof(s25, plain, r(v(a,a,b,b),m(v(b,b,a,a),v(b,b,a,a),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, lemma_43])).
fof(s26, plain, r(v(a,a,b,b),u(a,a,b),m(a,a,a)), inference(rewrite, [status(thm)], [sos, s25])).
fof(lemma_45, lemma, r(v(a,a,b,b),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s26])).
fof(lemma_46, lemma, r(u(a,a,a),u(a,b,b),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_014, sos_014])).
fof(lemma_47, lemma, r(m(v(a,a,b,b),v(a,a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),a,a)), inference(mp, [status(thm)], [sos_010, lemma_44, lemma_45, lemma_17])).
fof(s27, plain, r(a,u(a,b,b),u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, lemma_46])).
fof(lemma_48, lemma, r(a,u(a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s27])).
fof(s28, plain, r(u(a,b,b),m(u(a,a,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),a,a)), inference(rewrite, [status(thm)], [sos, lemma_47])).
fof(s29, plain, r(u(a,b,b),u(a,a,b),m(u(a,a,b),a,a)), inference(rewrite, [status(thm)], [sos, s28])).
fof(lemma_49, lemma, r(u(a,b,b),u(a,a,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_001, s29])).
fof(lemma_50, lemma, r(m(v(b,b,a,a),u(a,a,b),u(a,a,b)),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(mp, [status(thm)], [sos_010, lemma_38, lemma_19, lemma_39])).
fof(lemma_51, lemma, r(m(a,u(a,b,b),u(a,b,b)),m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_48, lemma_49, lemma_17])).
fof(s30, plain, r(v(b,b,a,a),m(a,a,u(a,b,b)),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos_001, lemma_50])).
fof(s31, plain, r(v(b,b,a,a),u(a,b,b),m(u(a,b,b),u(a,b,b),a)), inference(rewrite, [status(thm)], [sos, s30])).
fof(lemma_52, lemma, r(v(b,b,a,a),u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s31])).
fof(s32, plain, r(a,m(u(a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, lemma_51])).
fof(s33, plain, r(a,u(a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s32])).
fof(lemma_53, lemma, r(a,u(a,b,b),a), inference(rewrite, [status(thm)], [sos, s33])).
fof(lemma_54, lemma, r(v(a,b,a,a),v(a,a,b,b),v(b,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_013, sos_015, sos_014, sos_014])).
fof(s34, plain, r(v(a,a,b,a),v(a,a,b,b),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_007, lemma_54])).
fof(s35, plain, r(v(a,a,a,b),v(a,a,b,b),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_006, s34])).
fof(s36, plain, r(u(a,a,b),v(a,a,b,b),v(b,a,a,a)), inference(rewrite, [status(thm)], [sos_009, s35])).
fof(s37, plain, r(u(a,a,b),v(a,a,b,b),v(a,b,a,a)), inference(rewrite, [status(thm)], [sos_008, s36])).
fof(s38, plain, r(u(a,a,b),v(a,a,b,b),v(a,a,b,a)), inference(rewrite, [status(thm)], [sos_007, s37])).
fof(s39, plain, r(u(a,a,b),v(a,a,b,b),v(a,a,a,b)), inference(rewrite, [status(thm)], [sos_006, s38])).
fof(lemma_55, lemma, r(u(a,a,b),v(a,a,b,b),u(a,a,b)), inference(rewrite, [status(thm)], [sos_009, s39])).
fof(lemma_56, lemma, r(v(b,b,a,a),v(a,a,b,b),v(a,a,a,a)), inference(mp, [status(thm)], [sos_012, sos_015, sos_015, sos_014, sos_014])).
fof(lemma_57, lemma, r(m(u(a,a,b),u(a,a,b),u(a,b,b)),m(v(a,a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_55, lemma_23, lemma_17])).
fof(s40, plain, r(v(b,b,a,a),v(a,a,b,b),u(a,a,a)), inference(rewrite, [status(thm)], [sos_009, lemma_56])).
fof(lemma_58, lemma, r(v(b,b,a,a),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos_002, s40])).
fof(s41, plain, r(u(a,b,b),m(v(a,a,b,b),u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos, lemma_57])).
fof(s42, plain, r(u(a,b,b),v(a,a,b,b),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s41])).
fof(lemma_59, lemma, r(u(a,b,b),v(a,a,b,b),a), inference(rewrite, [status(thm)], [sos, s42])).
fof(lemma_60, lemma, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(mp, [status(thm)], [sos_010, lemma_58, lemma_59, lemma_17])).
fof(lemma_61, lemma, r(u(a,b,b),u(a,a,a),u(b,a,a)), inference(mp, [status(thm)], [sos_011, sos_013, sos_015, sos_015])).
fof(s43, plain, r(v(b,b,a,a),m(v(a,a,b,b),v(a,a,b,b),u(a,a,b)),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, lemma_60])).
fof(s44, plain, r(v(b,b,a,a),u(a,a,b),m(a,a,a)), inference(rewrite, [status(thm)], [sos, s43])).
fof(lemma_62, lemma, r(v(b,b,a,a),u(a,a,b),a), inference(rewrite, [status(thm)], [sos, s44])).
fof(s45, plain, r(u(a,b,b),a,u(b,a,a)), inference(rewrite, [status(thm)], [sos_002, lemma_61])).
fof(lemma_63, lemma, r(u(a,b,b),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos_005, s45])).
fof(lemma_64, lemma, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(mp, [status(thm)], [sos_010, lemma_62, lemma_17, lemma_63])).
fof(s46, plain, r(v(b,b,a,a),m(u(a,a,b),u(a,a,b),a),m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos_001, lemma_64])).
fof(s47, plain, r(v(b,b,a,a),a,m(a,a,u(a,a,b))), inference(rewrite, [status(thm)], [sos, s46])).
fof(lemma_65, lemma, r(v(b,b,a,a),a,u(a,a,b)), inference(rewrite, [status(thm)], [sos, s47])).
fof(lemma_66, lemma, r(m(v(b,b,a,a),a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, lemma_52, lemma_53, sos_014])).
fof(lemma_67, lemma, r(m(v(b,b,a,a),u(a,b,b),u(a,b,b)),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(mp, [status(thm)], [sos_010, lemma_65, lemma_49, lemma_17])).
fof(s48, plain, r(v(b,b,a,a),m(u(a,b,b),u(a,b,b),b),m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, lemma_66])).
fof(s49, plain, r(v(b,b,a,a),b,m(a,a,a)), inference(rewrite, [status(thm)], [sos, s48])).
fof(lemma_68, lemma, r(v(b,b,a,a),b,a), inference(rewrite, [status(thm)], [sos, s49])).
fof(s50, plain, r(v(b,b,a,a),m(a,u(a,a,b),u(a,a,b)),m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, lemma_67])).
fof(s51, plain, r(v(b,b,a,a),a,m(u(a,a,b),u(a,a,b),a)), inference(rewrite, [status(thm)], [sos_001, s50])).
fof(lemma_69, lemma, r(v(b,b,a,a),a,a), inference(rewrite, [status(thm)], [sos, s51])).
fof(lemma_70, lemma, r(m(v(b,b,a,a),v(b,b,a,a),b),m(b,a,a),m(a,a,a)), inference(mp, [status(thm)], [sos_010, lemma_68, lemma_69, sos_015])).
fof(s52, plain, r(b,m(b,a,a),m(a,a,a)), inference(rewrite, [status(thm)], [sos, lemma_70])).
fof(s53, plain, r(b,b,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s52])).
fof(lemma_71, lemma, r(b,b,a), inference(rewrite, [status(thm)], [sos, s53])).
fof(lemma_72, lemma, r(m(b,b,a),m(a,b,b),m(a,a,a)), inference(mp, [status(thm)], [sos_010, sos_015, lemma_71, sos_014])).
fof(s54, plain, r(a,m(a,b,b),m(a,a,a)), inference(rewrite, [status(thm)], [sos, lemma_72])).
fof(s55, plain, r(a,a,m(a,a,a)), inference(rewrite, [status(thm)], [sos_001, s54])).
fof(goal_1, theorem, r(a,a,a), inference(rewrite, [status(thm)], [sos, s55])).
% SZS output end Proof
