% SZS output start Proof
fof(c_50, plain, s0(d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_1)).
fof(c_66, plain, ! [X0]: q0(X0, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_17)).
fof(c_73, plain, l0(c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_24)).
fof(c_77, plain, k0(e), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', axiom_28)).
fof(c_204, plain, ~ s0(d) | ~ k0(e) | q1(d, d, d), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_117)).
fof(c_211, plain, ! [X0, X1]: (~ q1(d, X0, d) | ~ q0(X1, X0) | ~ s0(d) | r1(X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_124)).
fof(c_275, plain, ! [X0]: (~ l0(X0) | ~ r1(X0) | r2(X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/SYN001-0.ax', rule_188)).
fof(s1, plain, q1(d,d,d), inference(mp, [status(thm)], [c_204, c_50, c_77])).
fof(s2, plain, q0(c,d), inference(instantiate, [status(thm)], [c_66])).
fof(lemma_8, lemma, r1(c), inference(mp, [status(thm)], [c_211, s1, s2, c_50])).
fof(goal_1, theorem, r2(c), inference(mp, [status(thm)], [c_275, c_73, lemma_8])).
% SZS output end Proof
