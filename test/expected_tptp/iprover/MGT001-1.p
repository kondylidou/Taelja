% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ organization(X0, X1) | reliability(X0, sk1(X1, X0), X1)), file('Problems/MGT/MGT001-1.p', mp1_1)).
fof(c_50, plain, ! [X0, X1]: (~ organization(X0, X1) | accountability(X0, sk2(X1, X0), X1)), file('Problems/MGT/MGT001-1.p', mp2_2)).
fof(c_51, plain, ! [X0, X1]: (~ organization(X0, X1) | reproducibility(X0, sk3(X1, X0), X1)), file('Problems/MGT/MGT001-1.p', mp3_3)).
fof(c_52, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reliability(X0, X1, X2) | ~ reliability(X3, X4, X5) | ~ accountability(X0, X6, X2) | ~ accountability(X3, X7, X5) | ~ survival_chance(X0, X8, X2) | ~ survival_chance(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X4, X1) | ~ greater(X7, X6) | greater(X9, X8)), file('Problems/MGT/MGT001-1.p', a1_FOL_4)).
fof(c_53, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reliability(X0, X1, X2) | ~ reliability(X3, X4, X5) | ~ accountability(X0, X6, X2) | ~ accountability(X3, X7, X5) | ~ reproducibility(X0, X8, X2) | ~ reproducibility(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X9, X8) | greater(X4, X1)), file('Problems/MGT/MGT001-1.p', a2_FOL_5)).
fof(c_54, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reliability(X0, X1, X2) | ~ reliability(X3, X4, X5) | ~ accountability(X0, X6, X2) | ~ accountability(X3, X7, X5) | ~ reproducibility(X0, X8, X2) | ~ reproducibility(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X9, X8) | greater(X7, X6)), file('Problems/MGT/MGT001-1.p', a2_FOL_6)).
fof(c_57, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reorganization_free(X0, X2, X2) | ~ reorganization_free(X3, X5, X5) | ~ inertia(X0, X6, X2) | ~ inertia(X3, X7, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X7, X6) | greater(X4, X1)), file('Problems/MGT/MGT001-1.p', a3_FOL_9)).
fof(c_58, plain, organization(sk4, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_10)).
fof(c_59, plain, organization(sk5, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_11)).
fof(c_60, plain, reorganization_free(sk4, sk6, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_12)).
fof(c_61, plain, reorganization_free(sk5, sk7, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_13)).
fof(c_62, plain, inertia(sk4, sk8, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_14)).
fof(c_63, plain, inertia(sk5, sk9, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_15)).
fof(c_64, plain, survival_chance(sk4, sk10, sk6), file('Problems/MGT/MGT001-1.p', t1_FOL_16)).
fof(c_65, plain, survival_chance(sk5, sk11, sk7), file('Problems/MGT/MGT001-1.p', t1_FOL_17)).
fof(c_66, plain, greater(sk9, sk8), file('Problems/MGT/MGT001-1.p', t1_FOL_18)).
fof(lemma_17, lemma, reproducibility(sk4,sk3(sk6,sk4),sk6), inference(mp, [status(thm)], [c_51, c_58])).
fof(lemma_18, lemma, reproducibility(sk5,sk3(sk7,sk5),sk7), inference(mp, [status(thm)], [c_51, c_59])).
fof(lemma_19, lemma, greater(sk3(sk7,sk5),sk3(sk6,sk4)), inference(mp, [status(thm)], [c_57, lemma_17, lemma_18, c_60, c_61, c_62, c_63, c_58, c_59, c_66])).
fof(lemma_20, lemma, reliability(sk4,sk1(sk6,sk4),sk6), inference(mp, [status(thm)], [c_49, c_58])).
fof(lemma_21, lemma, reliability(sk5,sk1(sk7,sk5),sk7), inference(mp, [status(thm)], [c_49, c_59])).
fof(lemma_22, lemma, accountability(sk4,sk2(sk6,sk4),sk6), inference(mp, [status(thm)], [c_50, c_58])).
fof(lemma_23, lemma, accountability(sk5,sk2(sk7,sk5),sk7), inference(mp, [status(thm)], [c_50, c_59])).
fof(lemma_24, lemma, greater(sk1(sk7,sk5),sk1(sk6,sk4)), inference(mp, [status(thm)], [c_53, lemma_20, lemma_21, lemma_22, lemma_23, lemma_17, lemma_18, c_58, c_59, lemma_19])).
fof(lemma_25, lemma, greater(sk2(sk7,sk5),sk2(sk6,sk4)), inference(mp, [status(thm)], [c_54, lemma_20, lemma_21, lemma_22, lemma_23, lemma_17, lemma_18, c_58, c_59, lemma_19])).
fof(goal_1, theorem, greater(sk11,sk10), inference(mp, [status(thm)], [c_52, lemma_20, lemma_21, lemma_22, lemma_23, c_64, c_65, c_58, c_59, lemma_24, lemma_25])).
% SZS output end Proof
