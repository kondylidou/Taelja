% SZS output start Proof
cnf(c2, axiom, p0(b, X2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_14)).
cnf(c3, axiom, m0(X2, d, Y), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_19)).
cnf(c4, axiom, q0(X2, d), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_17)).
cnf(c5, axiom, s1(I) | ~ p0(I, I), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_125)).
cnf(c7, axiom, s1(F) | ~ q0(F, G) | ~ s1(H), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_126)).
cnf(c10, axiom, l2(J, J) | ~ p0(A, A) | ~ s1(B) | ~ m0(C, B, J), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_133)).
cnf(c14, axiom, k0(b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_32)).
cnf(c15, axiom, p1(B2, B2, B2) | ~ p0(C2, B2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_085)).
cnf(c17, axiom, q2(E, F2, F2) | ~ k0(F2) | ~ p1(E, E, E), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_177)).
cnf(c21, axiom, l0(a), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_20)).
cnf(c22, axiom, n0(b, a), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_37)).
cnf(c23, axiom, l1(G2, G2) | ~ n0(H2, G2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_002)).
cnf(c25, axiom, s0(b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', axiom_5)).
cnf(c26, axiom, n1(D, E2, D) | ~ s0(b) | ~ l0(D) | ~ p0(b, E2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_050)).
cnf(c30, axiom, n1(E2, F2, F2) | ~ l0(G2) | ~ l1(G2, E2) | ~ n1(E2, F2, E2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_054)).
cnf(c34, axiom, q2(F2, G2, F2) | ~ p1(F2, F2, H2) | ~ n1(G2, F2, H2) | ~ q2(G2, H2, F2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_182)).
cnf(c39, axiom, s2(H2) | ~ q2(b, H2, b) | ~ s1(b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_189)).
cnf(c43, axiom, q2(I2, I2, I2) | ~ p1(I2, I2, I2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_181)).
cnf(c45, axiom, s3(I2, J2) | ~ q2(A2, I2, A2) | ~ s2(I2) | ~ m0(A2, B2, J2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_273)).
cnf(c49, axiom, m4(E2, F2) | ~ l2(G2, F2) | ~ s3(a, E2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/SYN/SYN140-1.p', rule_279)).
fof(s1, plain, p0(b,b), inference(instantiate, [status(thm)], [c2])).
fof(lemma_21, lemma, s1(b), inference(mp, [status(thm)], [c5, s1])).
fof(s2, plain, q0(d,d), inference(instantiate, [status(thm)], [c4])).
fof(lemma_22, lemma, s1(d), inference(mp, [status(thm)], [c7, s2, lemma_21])).
fof(s3, plain, p0(b,a), inference(instantiate, [status(thm)], [c2])).
fof(lemma_23, lemma, p1(a,a,a), inference(mp, [status(thm)], [c15, s3])).
fof(lemma_24, lemma, q2(a,b,b), inference(mp, [status(thm)], [c17, c14, lemma_23])).
fof(lemma_25, lemma, l1(a,a), inference(mp, [status(thm)], [c23, c22])).
fof(s4, plain, p0(b,b), inference(instantiate, [status(thm)], [c2])).
fof(lemma_26, lemma, n1(a,b,a), inference(mp, [status(thm)], [c26, c25, c21, s4])).
fof(lemma_27, lemma, n1(a,b,b), inference(mp, [status(thm)], [c30, c21, lemma_25, lemma_26])).
fof(s5, plain, p0(b,b), inference(instantiate, [status(thm)], [c2])).
fof(s6, plain, p1(b,b,b), inference(mp, [status(thm)], [c15, s5])).
fof(s7, plain, q2(b,a,b), inference(mp, [status(thm)], [c34, s6, lemma_27, lemma_24])).
fof(lemma_28, lemma, s2(a), inference(mp, [status(thm)], [c39, s7, lemma_21])).
fof(s8, plain, p0(b,a), inference(instantiate, [status(thm)], [c2])).
fof(s9, plain, p1(a,a,a), inference(mp, [status(thm)], [c15, s8])).
fof(s10, plain, q2(a,a,a), inference(mp, [status(thm)], [c43, s9])).
fof(s11, plain, m0(a,d,b), inference(instantiate, [status(thm)], [c3])).
fof(lemma_29, lemma, s3(a,b), inference(mp, [status(thm)], [c45, s10, lemma_28, s11])).
fof(s12, plain, p0(b,b), inference(instantiate, [status(thm)], [c2])).
fof(s13, plain, ! [X] : l2(X,X), inference(mp, [status(thm)], [c10, s12, lemma_22, c3])).
fof(goal_1, theorem, ! [X] : m4(b,X), inference(mp, [status(thm)], [c49, s13, lemma_29])).
% SZS output end Proof
