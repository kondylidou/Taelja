% SZS output start Proof
cnf(a3_FOL_9, hypothesis, greater(X6, X5) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reorganization_free(X1, X2, X2) | ~ reorganization_free(X3, X4, X4) | ~ reproducibility(X1, X5, X2) | ~ reproducibility(X3, X6, X4) | ~ inertia(X1, X7, X2) | ~ inertia(X3, X8, X4) | ~ greater(X8, X7), file('Problems/MGT/MGT001-1.p', a3_FOL_9)).
cnf(t1_FOL_15, negated_conjecture, inertia(sk5, sk9, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_15)).
cnf(t1_FOL_13, negated_conjecture, reorganization_free(sk5, sk7, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_13)).
cnf(t1_FOL_11, negated_conjecture, organization(sk5, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_11)).
cnf(mp3_3, axiom, reproducibility(X1, sk3(X2, X1), X2) | ~ organization(X1, X2), file('Problems/MGT/MGT001-1.p', mp3_3)).
cnf(a2_FOL_6, hypothesis, greater(X8, X7) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT001-1.p', a2_FOL_6)).
cnf(t1_FOL_14, negated_conjecture, inertia(sk4, sk8, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_14)).
cnf(t1_FOL_12, negated_conjecture, reorganization_free(sk4, sk6, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_12)).
cnf(t1_FOL_18, negated_conjecture, greater(sk9, sk8), file('Problems/MGT/MGT001-1.p', t1_FOL_18)).
cnf(t1_FOL_10, negated_conjecture, organization(sk4, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_10)).
cnf(mp2_2, axiom, accountability(X1, sk2(X2, X1), X2) | ~ organization(X1, X2), file('Problems/MGT/MGT001-1.p', mp2_2)).
cnf(a1_FOL_4, hypothesis, greater(X10, X9) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ survival_chance(X1, X9, X2) | ~ survival_chance(X3, X10, X4) | ~ greater(X6, X5) | ~ greater(X8, X7), file('Problems/MGT/MGT001-1.p', a1_FOL_4)).
cnf(mp1_1, axiom, reliability(X1, sk1(X2, X1), X2) | ~ organization(X1, X2), file('Problems/MGT/MGT001-1.p', mp1_1)).
cnf(t1_FOL_17, negated_conjecture, survival_chance(sk5, sk11, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_17)).
cnf(a2_FOL_5, hypothesis, greater(X6, X5) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT001-1.p', a2_FOL_5)).
cnf(t1_FOL_16, negated_conjecture, survival_chance(sk4, sk10, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_16)).
fof(lemma_17, lemma, accountability(sk4,sk2(sk6,sk4),sk6), inference(mp, [status(thm)], [mp2_2, t1_FOL_10])).
fof(lemma_18, lemma, reliability(sk5,sk1(sk7,sk5),sk7), inference(mp, [status(thm)], [mp1_1, t1_FOL_11])).
fof(lemma_19, lemma, reliability(sk4,sk1(sk6,sk4),sk6), inference(mp, [status(thm)], [mp1_1, t1_FOL_10])).
fof(lemma_20, lemma, accountability(sk5,sk2(sk7,sk5),sk7), inference(mp, [status(thm)], [mp2_2, t1_FOL_11])).
fof(lemma_21, lemma, reproducibility(sk4,sk3(sk6,sk4),sk6), inference(mp, [status(thm)], [mp3_3, t1_FOL_10])).
fof(lemma_22, lemma, reproducibility(sk5,sk3(sk7,sk5),sk7), inference(mp, [status(thm)], [mp3_3, t1_FOL_11])).
fof(lemma_23, lemma, greater(sk3(sk7,sk5),sk3(sk6,sk4)), inference(mp, [status(thm)], [a3_FOL_9, t1_FOL_10, t1_FOL_11, t1_FOL_12, t1_FOL_13, lemma_21, lemma_22, t1_FOL_14, t1_FOL_15, t1_FOL_18])).
fof(lemma_24, lemma, greater(sk1(sk7,sk5),sk1(sk6,sk4)), inference(mp, [status(thm)], [a2_FOL_5, t1_FOL_10, t1_FOL_11, lemma_19, lemma_18, lemma_17, lemma_20, lemma_21, lemma_22, lemma_23])).
fof(lemma_25, lemma, greater(sk2(sk7,sk5),sk2(sk6,sk4)), inference(mp, [status(thm)], [a2_FOL_6, t1_FOL_10, t1_FOL_11, lemma_19, lemma_18, lemma_17, lemma_20, lemma_21, lemma_22, lemma_23])).
fof(goal_1, theorem, greater(sk11,sk10), inference(mp, [status(thm)], [a1_FOL_4, t1_FOL_10, t1_FOL_11, lemma_19, lemma_18, lemma_17, lemma_20, t1_FOL_16, t1_FOL_17, lemma_24, lemma_25])).
% SZS output end Proof
