% SZS output start Proof
fof(c_50, plain, s0(d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_1)).
fof(c_63, plain, ! [X0]: p0(b, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_14)).
fof(c_68, plain, ! [X0, X1]: m0(X0, d, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_19)).
fof(c_73, plain, l0(c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_24)).
fof(c_74, plain, q0(d, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_25)).
fof(c_75, plain, n0(d, c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_26)).
fof(c_77, plain, k0(e), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_28)).
fof(c_83, plain, n0(c, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_34)).
fof(c_88, plain, ! [X0, X1]: (~ n0(X0, X1) | k1(X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_001)).
fof(c_146, plain, ! [X0, X1, X2, X3]: (~ m0(X0, X1, X2) | ~ m0(X1, X3, X3) | n1(X2, X2, X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_059)).
fof(c_204, plain, ~ s0(d) | ~ k0(e) | q1(d, d, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_117)).
fof(c_211, plain, ! [X0, X1]: (~ q1(d, X0, d) | ~ q0(X1, X0) | ~ s0(d) | r1(X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_124)).
fof(c_212, plain, ! [X0]: (~ p0(X0, X0) | s1(X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_125)).
fof(c_213, plain, ! [X0, X1, X2]: (~ q0(X0, X1) | ~ s1(X2) | s1(X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_126)).
fof(c_220, plain, ! [X0, X1, X2, X3]: (~ m0(X0, X1, X2) | ~ p0(X3, X3) | ~ s1(X1) | l2(X2, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_133)).
fof(c_270, plain, ! [X0, X1]: (~ l2(X0, X1) | ~ k1(X0) | ~ l0(c) | q2(X1, c, X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_183)).
fof(c_278, plain, ~ r1(d) | ~ s1(d) | s2(d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_191)).
fof(c_342, plain, ! [X0, X1, X2]: (~ q2(X0, X1, X2) | ~ n0(X0, X1) | q3(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_255)).
fof(c_344, plain, ! [X0, X1, X2]: (~ n1(X0, X1, X2) | ~ q3(X2, X1) | ~ s2(X1) | q3(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_257)).
fof(s1, plain, p0(b,b), inference(instantiate, [status(thm)], [c_63])).
fof(lemma_20, lemma, s1(b), inference(mp, [status(thm)], [c_212, s1])).
fof(lemma_21, lemma, s1(d), inference(mp, [status(thm)], [c_213, c_74, lemma_20])).
fof(lemma_22, lemma, k1(d), inference(mp, [status(thm)], [c_88, c_83])).
fof(s2, plain, ! [X] : m0(X,d,d), inference(instantiate, [status(thm)], [c_68])).
fof(s3, plain, p0(b,b), inference(instantiate, [status(thm)], [c_63])).
fof(s4, plain, l2(d,d), inference(mp, [status(thm)], [c_220, s2, s3, lemma_21])).
fof(s5, plain, q2(d,c,d), inference(mp, [status(thm)], [c_270, s4, lemma_22, c_73])).
fof(lemma_23, lemma, q3(c,d), inference(mp, [status(thm)], [c_342, s5, c_75])).
fof(s6, plain, q1(d,d,d), inference(mp, [status(thm)], [c_204, c_50, c_77])).
fof(s7, plain, r1(d), inference(mp, [status(thm)], [c_211, s6, c_74, c_50])).
fof(lemma_24, lemma, s2(d), inference(mp, [status(thm)], [c_278, s7, lemma_21])).
fof(s8, plain, m0(c,d,d), inference(instantiate, [status(thm)], [c_68])).
fof(s9, plain, m0(d,d,d), inference(instantiate, [status(thm)], [c_68])).
fof(s10, plain, n1(d,d,c), inference(mp, [status(thm)], [c_146, s8, s9])).
fof(goal_1, theorem, q3(d,c), inference(mp, [status(thm)], [c_344, s10, lemma_23, lemma_24])).
% SZS output end Proof
