% SZS output start Proof
cnf(axiom_9, axiom, r0(b), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_9)).
cnf(axiom_14, axiom, p0(b, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_14)).
cnf(axiom_19, axiom, m0(X1, d, X2), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_19)).
cnf(rule_003, axiom, l1(X1, X2) | ~ p0(X3, X1) | ~ r0(X4) | ~ m0(X2, X1, X3), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_003)).
cnf(rule_125, axiom, s1(X1) | ~ p0(X1, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_125)).
cnf(axiom_36, axiom, q0(a, b), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_36)).
cnf(rule_126, axiom, s1(X1) | ~ q0(X1, X2) | ~ s1(X3), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_126)).
cnf(axiom_1, axiom, s0(d), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_1)).
cnf(rule_190, axiom, s2(d) | ~ s1(a) | ~ s0(d), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_190)).
cnf(axiom_30, axiom, n0(e, e), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_30)).
cnf(rule_186, axiom, q2(X1, X1, X2) | ~ l1(X2, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_186)).
cnf(rule_255, axiom, q3(X1, X2) | ~ q2(X3, X1, X2) | ~ n0(X3, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_255)).
cnf(rule_059, axiom, n1(X1, X1, X2) | ~ m0(X3, X4, X4) | ~ m0(X2, X3, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_059)).
cnf(rule_257, axiom, q3(X1, X2) | ~ n1(X3, X1, X2) | ~ s2(X1) | ~ q3(X2, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_257)).
fof(s1, plain, p0(b,b), inference(instantiate, [status(thm)], [axiom_14])).
fof(lemma_15, lemma, s1(b), inference(mp, [status(thm)], [rule_125, s1])).
fof(s2, plain, p0(b,d), inference(instantiate, [status(thm)], [axiom_14])).
fof(s3, plain, m0(e,d,b), inference(instantiate, [status(thm)], [axiom_19])).
fof(lemma_16, lemma, l1(d,e), inference(mp, [status(thm)], [rule_003, s2, axiom_9, s3])).
fof(s4, plain, s1(a), inference(mp, [status(thm)], [rule_126, axiom_36, lemma_15])).
fof(lemma_17, lemma, s2(d), inference(mp, [status(thm)], [rule_190, s4, axiom_1])).
fof(s5, plain, q2(e,e,d), inference(mp, [status(thm)], [rule_186, lemma_16])).
fof(lemma_18, lemma, q3(e,d), inference(mp, [status(thm)], [rule_255, s5, axiom_30])).
fof(s6, plain, m0(d,d,d), inference(instantiate, [status(thm)], [axiom_19])).
fof(s7, plain, m0(e,d,d), inference(instantiate, [status(thm)], [axiom_19])).
fof(s8, plain, n1(d,d,e), inference(mp, [status(thm)], [rule_059, s6, s7])).
fof(goal_1, theorem, q3(d,e), inference(mp, [status(thm)], [rule_257, s8, lemma_17, lemma_18])).
% SZS output end Proof
