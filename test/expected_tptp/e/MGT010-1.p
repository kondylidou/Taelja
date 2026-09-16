% SZS output start Proof
cnf(t9_FOL_5, hypothesis, greater(X7, X6) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reorganization_free(X1, X2, X2) | ~ reorganization_free(X3, X4, X4) | ~ class(X1, X5, X2) | ~ class(X3, X5, X4) | ~ reproducibility(X1, X6, X2) | ~ reproducibility(X3, X7, X4) | ~ size(X1, X8, X2) | ~ size(X3, X9, X4) | ~ greater(X9, X8), file('Problems/MGT/MGT010-1.p', t9_FOL_5)).
cnf(a2_FOL_3, hypothesis, greater(X8, X7) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT010-1.p', a2_FOL_3)).
cnf(t10_FOL_17, negated_conjecture, size(sk3, sk10, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_17)).
cnf(t10_FOL_9, negated_conjecture, reorganization_free(sk3, sk12, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_9)).
cnf(t10_FOL_7, negated_conjecture, organization(sk3, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_7)).
cnf(t10_FOL_15, negated_conjecture, accountability(sk3, sk8, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_15)).
cnf(t10_FOL_11, negated_conjecture, class(sk3, sk4, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_11)).
cnf(mp3_1, axiom, reproducibility(X1, sk1(X2, X1), X2) | ~ organization(X1, X2), file('Problems/MGT/MGT010-1.p', mp3_1)).
cnf(a2_FOL_2, hypothesis, greater(X6, X5) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT010-1.p', a2_FOL_2)).
cnf(t10_FOL_13, negated_conjecture, reliability(sk3, sk6, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_13)).
cnf(t10_FOL_16, negated_conjecture, size(sk2, sk9, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_16)).
cnf(t10_FOL_10, negated_conjecture, class(sk2, sk4, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_10)).
cnf(t10_FOL_8, negated_conjecture, reorganization_free(sk2, sk11, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_8)).
cnf(t10_FOL_18, negated_conjecture, greater(sk10, sk9), file('Problems/MGT/MGT010-1.p', t10_FOL_18)).
cnf(t10_FOL_6, negated_conjecture, organization(sk2, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_6)).
cnf(t10_FOL_14, negated_conjecture, accountability(sk2, sk7, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_14)).
cnf(t10_FOL_12, negated_conjecture, reliability(sk2, sk5, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_12)).
fof(lemma_18, lemma, reproducibility(sk2,sk1(sk11,sk2),sk11), inference(mp, [status(thm)], [mp3_1, t10_FOL_6])).
fof(lemma_19, lemma, reproducibility(sk3,sk1(sk12,sk3),sk12), inference(mp, [status(thm)], [mp3_1, t10_FOL_7])).
fof(lemma_20, lemma, greater(sk1(sk12,sk3),sk1(sk11,sk2)), inference(mp, [status(thm)], [t9_FOL_5, t10_FOL_6, t10_FOL_7, t10_FOL_8, t10_FOL_9, t10_FOL_10, t10_FOL_11, lemma_18, lemma_19, t10_FOL_16, t10_FOL_17, t10_FOL_18])).
fof(goal_1, theorem, greater(sk6,sk5), inference(mp, [status(thm)], [a2_FOL_2, t10_FOL_6, t10_FOL_7, t10_FOL_12, t10_FOL_13, t10_FOL_14, t10_FOL_15, lemma_18, lemma_19, lemma_20])).
fof(goal_2, theorem, greater(sk8,sk7), inference(mp, [status(thm)], [a2_FOL_3, t10_FOL_6, t10_FOL_7, t10_FOL_12, t10_FOL_13, t10_FOL_14, t10_FOL_15, lemma_18, lemma_19, lemma_20])).
% SZS output end Proof
