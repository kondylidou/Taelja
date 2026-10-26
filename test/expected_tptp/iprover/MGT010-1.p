% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ organization(X0, X1) | reproducibility(X0, sk1(X1, X0), X1)), file('Problems/MGT/MGT010-1.p', mp3_1)).
fof(c_50, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reliability(X0, X6, X2) | ~ reliability(X3, X7, X5) | ~ accountability(X0, X8, X2) | ~ accountability(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X4, X1) | greater(X7, X6)), file('Problems/MGT/MGT010-1.p', a2_FOL_2)).
fof(c_51, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reliability(X0, X6, X2) | ~ reliability(X3, X7, X5) | ~ accountability(X0, X8, X2) | ~ accountability(X3, X9, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X4, X1) | greater(X9, X8)), file('Problems/MGT/MGT010-1.p', a2_FOL_3)).
fof(c_53, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8]: (~ reproducibility(X0, X1, X2) | ~ reproducibility(X3, X4, X5) | ~ reorganization_free(X0, X2, X2) | ~ reorganization_free(X3, X5, X5) | ~ class(X0, X6, X2) | ~ class(X3, X6, X5) | ~ size(X0, X7, X2) | ~ size(X3, X8, X5) | ~ organization(X0, X2) | ~ organization(X3, X5) | ~ greater(X8, X7) | greater(X4, X1)), file('Problems/MGT/MGT010-1.p', t9_FOL_5)).
fof(c_54, plain, organization(sk2, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_6)).
fof(c_55, plain, organization(sk3, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_7)).
fof(c_56, plain, reorganization_free(sk2, sk11, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_8)).
fof(c_57, plain, reorganization_free(sk3, sk12, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_9)).
fof(c_58, plain, class(sk2, sk4, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_10)).
fof(c_59, plain, class(sk3, sk4, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_11)).
fof(c_60, plain, reliability(sk2, sk5, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_12)).
fof(c_61, plain, reliability(sk3, sk6, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_13)).
fof(c_62, plain, accountability(sk2, sk7, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_14)).
fof(c_63, plain, accountability(sk3, sk8, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_15)).
fof(c_64, plain, size(sk2, sk9, sk11), file('Problems/MGT/MGT010-1.p', t10_FOL_16)).
fof(c_65, plain, size(sk3, sk10, sk12), file('Problems/MGT/MGT010-1.p', t10_FOL_17)).
fof(c_66, plain, greater(sk10, sk9), file('Problems/MGT/MGT010-1.p', t10_FOL_18)).
fof(lemma_18, lemma, reproducibility(sk2,sk1(sk11,sk2),sk11), inference(mp, [status(thm)], [c_49, c_54])).
fof(lemma_19, lemma, reproducibility(sk3,sk1(sk12,sk3),sk12), inference(mp, [status(thm)], [c_49, c_55])).
fof(lemma_20, lemma, greater(sk1(sk12,sk3),sk1(sk11,sk2)), inference(mp, [status(thm)], [c_53, lemma_18, lemma_19, c_56, c_57, c_58, c_59, c_64, c_65, c_54, c_55, c_66])).
fof(goal_1, theorem, greater(sk6,sk5), inference(mp, [status(thm)], [c_50, lemma_18, lemma_19, c_60, c_61, c_62, c_63, c_54, c_55, lemma_20])).
fof(goal_2, theorem, greater(sk8,sk7), inference(mp, [status(thm)], [c_51, lemma_18, lemma_19, c_60, c_61, c_62, c_63, c_54, c_55, lemma_20])).
% SZS output end Proof
