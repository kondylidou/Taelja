% SZS output start Proof
cnf(a2_FOL_3, hypothesis, greater(X8, X7) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT006-1.p', a2_FOL_3)).
cnf(t6_FOL_12, negated_conjecture, accountability(sk2, sk6, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_12)).
cnf(t6_FOL_7, negated_conjecture, organization(sk2, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_7)).
cnf(a4_FOL_5, hypothesis, greater(X5, X4) | ~ organization(X1, X2) | ~ organization(X1, X3) | ~ reorganization_free(X1, X2, X3) | ~ reproducibility(X1, X4, X2) | ~ reproducibility(X1, X5, X3) | ~ greater(X3, X2), file('Problems/MGT/MGT006-1.p', a4_FOL_5)).
cnf(a2_FOL_2, hypothesis, greater(X6, X5) | ~ organization(X1, X2) | ~ organization(X3, X4) | ~ reliability(X1, X5, X2) | ~ reliability(X3, X6, X4) | ~ accountability(X1, X7, X2) | ~ accountability(X3, X8, X4) | ~ reproducibility(X1, X9, X2) | ~ reproducibility(X3, X10, X4) | ~ greater(X10, X9), file('Problems/MGT/MGT006-1.p', a2_FOL_2)).
cnf(t6_FOL_10, negated_conjecture, reliability(sk2, sk4, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_10)).
cnf(mp3_1, axiom, reproducibility(X1, sk1(X2, X1), X2) | ~ organization(X1, X2), file('Problems/MGT/MGT006-1.p', mp3_1)).
cnf(t6_FOL_8, negated_conjecture, reorganization_free(sk2, sk7, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_8)).
cnf(t6_FOL_13, negated_conjecture, greater(sk8, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_13)).
cnf(t6_FOL_6, negated_conjecture, organization(sk2, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_6)).
cnf(t6_FOL_11, negated_conjecture, accountability(sk2, sk5, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_11)).
cnf(t6_FOL_9, negated_conjecture, reliability(sk2, sk3, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_9)).
fof(lemma_13, lemma, reproducibility(sk2,sk1(sk7,sk2),sk7), inference(mp, [status(thm)], [mp3_1, t6_FOL_6])).
fof(lemma_14, lemma, reproducibility(sk2,sk1(sk8,sk2),sk8), inference(mp, [status(thm)], [mp3_1, t6_FOL_7])).
fof(lemma_15, lemma, greater(sk1(sk8,sk2),sk1(sk7,sk2)), inference(mp, [status(thm)], [a4_FOL_5, t6_FOL_6, t6_FOL_7, t6_FOL_8, lemma_13, lemma_14, t6_FOL_13])).
fof(goal_1, theorem, greater(sk4,sk3), inference(mp, [status(thm)], [a2_FOL_2, t6_FOL_6, t6_FOL_7, t6_FOL_9, t6_FOL_10, t6_FOL_11, t6_FOL_12, lemma_13, lemma_14, lemma_15])).
fof(goal_2, theorem, greater(sk6,sk5), inference(mp, [status(thm)], [a2_FOL_3, t6_FOL_6, t6_FOL_7, t6_FOL_9, t6_FOL_10, t6_FOL_11, t6_FOL_12, lemma_13, lemma_14, lemma_15])).
% SZS output end Proof
