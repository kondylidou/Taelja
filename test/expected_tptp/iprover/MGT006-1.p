% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ organization(X0, X1) | reproducibility(X0, sk1(X1, X0), X1)), file('Problems/MGT/MGT006-1.p', mp3_1)).
fof(c_50, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reliability(X0, X6, X2) | ~ reliability(X3, X7, X5) | ~ accountability(X0, X8, X2) | ~ accountability(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X4, X1) | greater(X7, X6)), file('Problems/MGT/MGT006-1.p', a2_FOL_2)).
fof(c_51, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reliability(X0, X6, X2) | ~ reliability(X3, X7, X5) | ~ accountability(X0, X8, X2) | ~ accountability(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X4, X1) | greater(X9, X8)), file('Problems/MGT/MGT006-1.p', a2_FOL_3)).
fof(c_53, plain, ! [X0, X1, X2, X3, X4]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X0, X3, X4) | ~ reorganization_free(X0, X2, X4) | ~ organization(X0, X2) | ~ organization(X0, X4) | ~ greater(X4, X2) | greater(X3, X1)), file('Problems/MGT/MGT006-1.p', a4_FOL_5)).
fof(c_54, plain, organization(sk2, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_6)).
fof(c_55, plain, organization(sk2, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_7)).
fof(c_56, plain, reorganization_free(sk2, sk7, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_8)).
fof(c_57, plain, reliability(sk2, sk3, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_9)).
fof(c_58, plain, reliability(sk2, sk4, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_10)).
fof(c_59, plain, accountability(sk2, sk5, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_11)).
fof(c_60, plain, accountability(sk2, sk6, sk8), file('Problems/MGT/MGT006-1.p', t6_FOL_12)).
fof(c_61, plain, greater(sk8, sk7), file('Problems/MGT/MGT006-1.p', t6_FOL_13)).
fof(lemma_13, lemma, reproducibility(sk2,sk1(sk7,sk2),sk7), inference(mp, [status(thm)], [c_49, c_54])).
fof(lemma_14, lemma, reproducibility(sk2,sk1(sk8,sk2),sk8), inference(mp, [status(thm)], [c_49, c_55])).
fof(lemma_15, lemma, greater(sk1(sk8,sk2),sk1(sk7,sk2)), inference(mp, [status(thm)], [c_53, lemma_13, lemma_14, c_56, c_54, c_55, c_61])).
fof(goal_1, theorem, greater(sk4,sk3), inference(mp, [status(thm)], [c_50, lemma_13, lemma_14, c_57, c_58, c_59, c_60, c_54, c_55, lemma_15])).
fof(goal_2, theorem, greater(sk6,sk5), inference(mp, [status(thm)], [c_51, lemma_13, lemma_14, c_57, c_58, c_59, c_60, c_54, c_55, lemma_15])).
% SZS output end Proof
