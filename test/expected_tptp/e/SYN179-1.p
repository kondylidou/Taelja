% SZS output start Proof
cnf(rule_126, axiom, s1(X1) | ~ q0(X1, X2) | ~ s1(X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_126)).
cnf(rule_125, axiom, s1(X1) | ~ p0(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_125)).
cnf(axiom_17, axiom, q0(X1, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_17)).
cnf(axiom_14, axiom, p0(b, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_14)).
cnf(rule_133, axiom, l2(X1, X1) | ~ p0(X2, X2) | ~ s1(X3) | ~ m0(X4, X3, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_133)).
cnf(rule_050, axiom, n1(X1, X2, X1) | ~ s0(b) | ~ l0(X1) | ~ p0(b, X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_050)).
cnf(axiom_5, axiom, s0(b), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_5)).
cnf(rule_183, axiom, q2(X1, c, X2) | ~ k1(X2) | ~ l0(c) | ~ l2(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_183)).
cnf(axiom_24, axiom, l0(c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_24)).
cnf(axiom_19, axiom, m0(X1, d, X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_19)).
cnf(rule_190, axiom, s2(d) | ~ s1(a) | ~ s0(d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_190)).
cnf(rule_257, axiom, q3(X1, X2) | ~ n1(X3, X1, X2) | ~ s2(X1) | ~ q3(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_257)).
cnf(rule_255, axiom, q3(X1, X2) | ~ q2(X3, X1, X2) | ~ n0(X3, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_255)).
cnf(axiom_1, axiom, s0(d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_1)).
cnf(axiom_36, axiom, q0(a, b), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_36)).
cnf(rule_001, axiom, k1(X1) | ~ n0(X2, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_001)).
cnf(axiom_34, axiom, n0(c, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_34)).
cnf(axiom_26, axiom, n0(d, c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_26)).
fof(s1, plain, p0(b,b), inference(instantiate, [status(thm)], [axiom_14])).
fof(lemma_19, lemma, s1(b), inference(mp, [status(thm)], [rule_125, s1])).
fof(s2, plain, q0(d,d), inference(instantiate, [status(thm)], [axiom_17])).
fof(lemma_20, lemma, s1(d), inference(mp, [status(thm)], [rule_126, s2, lemma_19])).
fof(s3, plain, p0(b,b), inference(instantiate, [status(thm)], [axiom_14])).
fof(s4, plain, ! [X] : m0(X,d,d), inference(instantiate, [status(thm)], [axiom_19])).
fof(lemma_21, lemma, l2(d,d), inference(mp, [status(thm)], [rule_133, s3, lemma_20, s4])).
fof(s5, plain, s1(a), inference(mp, [status(thm)], [rule_126, axiom_36, lemma_19])).
fof(lemma_22, lemma, s2(d), inference(mp, [status(thm)], [rule_190, s5, axiom_1])).
fof(s6, plain, k1(d), inference(mp, [status(thm)], [rule_001, axiom_34])).
fof(s7, plain, q2(d,c,d), inference(mp, [status(thm)], [rule_183, s6, axiom_24, lemma_21])).
fof(lemma_23, lemma, q3(c,d), inference(mp, [status(thm)], [rule_255, s7, axiom_26])).
fof(s8, plain, p0(b,d), inference(instantiate, [status(thm)], [axiom_14])).
fof(s9, plain, n1(c,d,c), inference(mp, [status(thm)], [rule_050, axiom_5, axiom_24, s8])).
fof(goal_1, theorem, q3(d,c), inference(mp, [status(thm)], [rule_257, s9, lemma_22, lemma_23])).
% SZS output end Proof
