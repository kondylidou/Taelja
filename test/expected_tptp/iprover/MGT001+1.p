% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (organization(X0, X1) => ? [X2]: reliability(X0, X2, X1)), file('Problems/MGT/MGT001+1.p', mp1)).
fof(f2, axiom, ! [X0, X1]: (organization(X0, X1) => ? [X3]: accountability(X0, X3, X1)), file('Problems/MGT/MGT001+1.p', mp2)).
fof(f3, axiom, ! [X0, X1]: (organization(X0, X1) => ? [X4]: reproducibility(X0, X4, X1)), file('Problems/MGT/MGT001+1.p', mp3)).
fof(f4, axiom, ! [X0, X5, X6, X7, X8, X9, X10, X11, X12, X13]: ((greater(X9, X8) & greater(X7, X6) & survival_chance(X5, X11, X13) & survival_chance(X0, X10, X12) & accountability(X5, X9, X13) & accountability(X0, X8, X12) & reliability(X5, X7, X13) & reliability(X0, X6, X12) & organization(X5, X13) & organization(X0, X12)) => greater(X11, X10)), file('Problems/MGT/MGT001+1.p', a1_FOL)).
fof(f5, axiom, ! [X0, X5, X12, X13, X6, X7, X8, X9, X14, X15]: ((reproducibility(X5, X15, X13) & reproducibility(X0, X14, X12) & accountability(X5, X9, X13) & accountability(X0, X8, X12) & reliability(X5, X7, X13) & reliability(X0, X6, X12) & organization(X5, X13) & organization(X0, X12)) => (greater(X15, X14) <=> (greater(X9, X8) & greater(X7, X6)))), file('Problems/MGT/MGT001+1.p', a2_FOL)).
fof(f6, axiom, ! [X0, X5, X12, X13, X14, X15, X16, X17]: ((inertia(X5, X17, X13) & inertia(X0, X16, X12) & reproducibility(X5, X15, X13) & reproducibility(X0, X14, X12) & reorganization_free(X5, X13, X13) & reorganization_free(X0, X12, X12) & organization(X5, X13) & organization(X0, X12)) => (greater(X15, X14) <=> greater(X17, X16))), file('Problems/MGT/MGT001+1.p', a3_FOL)).
fof(f26, plain, ! [X0, X1]: (? [X2]: reliability(X0, X2, X1) => reliability(X0, sK0(X0, X1), X1)), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(f28, plain, ! [X0, X1]: (? [X2]: accountability(X0, X2, X1) => accountability(X0, sK1(X0, X1), X1)), introduced(choice_axiom, [new_symbols(definition, [sK1])], [])).
fof(f30, plain, ! [X0, X1]: (? [X2]: reproducibility(X0, X2, X1) => reproducibility(X0, sK2(X0, X1), X1)), introduced(choice_axiom, [new_symbols(definition, [sK2])], [])).
fof(f35, plain, ? [X0, X1, X2, X3, X4, X5, X6, X7]: (~ greater(X7, X6) & greater(X5, X4) & survival_chance(X1, X7, X3) & survival_chance(X0, X6, X2) & inertia(X1, X5, X3) & inertia(X0, X4, X2) & reorganization_free(X1, X3, X3) & reorganization_free(X0, X2, X2) & organization(X1, X3) & organization(X0, X2)) => (~ greater(sK10, sK9) & greater(sK8, sK7) & survival_chance(sK4, sK10, sK6) & survival_chance(sK3, sK9, sK5) & inertia(sK4, sK8, sK6) & inertia(sK3, sK7, sK5) & reorganization_free(sK4, sK6, sK6) & reorganization_free(sK3, sK5, sK5) & organization(sK4, sK6) & organization(sK3, sK5)), introduced(choice_axiom, [new_symbols(definition, [sK10,sK9,sK8,sK7,sK4,sK6,sK3,sK5])], [])).
fof(c_66, assumption, organization(sK4,sK6), introduced(assumption, [], [])).
fof(axiom_2, plain, (organization(sK4,sK6) => reproducibility(sK4,sK2(sK4,sK6),sK6)), inference(clausify, [status(thm)], [f3, f30])).
fof(c_67, assumption, organization(sK3,sK5), introduced(assumption, [], [])).
fof(axiom_4, plain, (organization(sK3,sK5) => reproducibility(sK3,sK2(sK3,sK5),sK5)), inference(clausify, [status(thm)], [f3, f30])).
fof(c_59, assumption, greater(sK8,sK7), introduced(assumption, [], [])).
fof(c_65, assumption, reorganization_free(sK3,sK5,sK5), introduced(assumption, [], [])).
fof(c_64, assumption, reorganization_free(sK4,sK6,sK6), introduced(assumption, [], [])).
fof(c_63, assumption, inertia(sK3,sK7,sK5), introduced(assumption, [], [])).
fof(c_62, assumption, inertia(sK4,sK8,sK6), introduced(assumption, [], [])).
fof(axiom_10, plain, ((reproducibility(sK4,sK2(sK4,sK6),sK6) & reproducibility(sK3,sK2(sK3,sK5),sK5) & inertia(sK4,sK8,sK6) & inertia(sK3,sK7,sK5) & reorganization_free(sK4,sK6,sK6) & reorganization_free(sK3,sK5,sK5) & organization(sK4,sK6) & organization(sK3,sK5) & greater(sK8,sK7)) => greater(sK2(sK4,sK6),sK2(sK3,sK5))), inference(clausify, [status(thm)], [f6])).
fof(axiom_11, plain, (organization(sK4,sK6) => reliability(sK4,sK0(sK4,sK6),sK6)), inference(clausify, [status(thm)], [f1, f26])).
fof(axiom_12, plain, (organization(sK3,sK5) => reliability(sK3,sK0(sK3,sK5),sK5)), inference(clausify, [status(thm)], [f1, f26])).
fof(axiom_13, plain, (organization(sK4,sK6) => accountability(sK4,sK1(sK4,sK6),sK6)), inference(clausify, [status(thm)], [f2, f28])).
fof(axiom_14, plain, (organization(sK3,sK5) => accountability(sK3,sK1(sK3,sK5),sK5)), inference(clausify, [status(thm)], [f2, f28])).
fof(axiom_15, plain, ((greater(sK2(sK4,sK6),sK2(sK3,sK5)) & reliability(sK4,sK0(sK4,sK6),sK6) & reliability(sK3,sK0(sK3,sK5),sK5) & accountability(sK4,sK1(sK4,sK6),sK6) & accountability(sK3,sK1(sK3,sK5),sK5) & reproducibility(sK4,sK2(sK4,sK6),sK6) & reproducibility(sK3,sK2(sK3,sK5),sK5) & organization(sK4,sK6) & organization(sK3,sK5)) => greater(sK1(sK4,sK6),sK1(sK3,sK5))), inference(clausify, [status(thm)], [f5])).
fof(axiom_16, plain, ((greater(sK2(sK4,sK6),sK2(sK3,sK5)) & reliability(sK4,sK0(sK4,sK6),sK6) & reliability(sK3,sK0(sK3,sK5),sK5) & accountability(sK4,sK1(sK4,sK6),sK6) & accountability(sK3,sK1(sK3,sK5),sK5) & reproducibility(sK4,sK2(sK4,sK6),sK6) & reproducibility(sK3,sK2(sK3,sK5),sK5) & organization(sK4,sK6) & organization(sK3,sK5)) => greater(sK0(sK4,sK6),sK0(sK3,sK5))), inference(clausify, [status(thm)], [f5])).
fof(c_61, assumption, survival_chance(sK3,sK9,sK5), introduced(assumption, [], [])).
fof(c_60, assumption, survival_chance(sK4,sK10,sK6), introduced(assumption, [], [])).
fof(lemma_20, lemma, reproducibility(sK4,sK2(sK4,sK6),sK6), inference(mp, [status(thm), assumptions([c_66])], [axiom_2, c_66])).
fof(lemma_21, lemma, reproducibility(sK3,sK2(sK3,sK5),sK5), inference(mp, [status(thm), assumptions([c_67])], [axiom_4, c_67])).
fof(lemma_22, lemma, greater(sK2(sK4,sK6),sK2(sK3,sK5)), inference(mp, [status(thm), assumptions([c_66, c_67, c_62, c_63, c_64, c_65, c_59])], [axiom_10, lemma_20, lemma_21, c_62, c_63, c_64, c_65, c_66, c_67, c_59])).
fof(lemma_23, lemma, reliability(sK4,sK0(sK4,sK6),sK6), inference(mp, [status(thm), assumptions([c_66])], [axiom_11, c_66])).
fof(lemma_24, lemma, reliability(sK3,sK0(sK3,sK5),sK5), inference(mp, [status(thm), assumptions([c_67])], [axiom_12, c_67])).
fof(lemma_25, lemma, accountability(sK4,sK1(sK4,sK6),sK6), inference(mp, [status(thm), assumptions([c_66])], [axiom_13, c_66])).
fof(lemma_26, lemma, accountability(sK3,sK1(sK3,sK5),sK5), inference(mp, [status(thm), assumptions([c_67])], [axiom_14, c_67])).
fof(lemma_27, lemma, greater(sK0(sK4,sK6),sK0(sK3,sK5)), inference(mp, [status(thm), assumptions([c_66, c_67, c_62, c_63, c_64, c_65, c_59])], [axiom_16, lemma_22, lemma_23, lemma_24, lemma_25, lemma_26, lemma_20, lemma_21, c_66, c_67])).
fof(s1, plain, greater(sK1(sK4,sK6),sK1(sK3,sK5)), inference(mp, [status(thm), assumptions([c_66, c_67, c_62, c_63, c_64, c_65, c_59])], [axiom_15, lemma_22, lemma_23, lemma_24, lemma_25, lemma_26, lemma_20, lemma_21, c_66, c_67])).
fof(s2, plain, greater(sK10,sK9), inference(mp, [status(thm), assumptions([c_66, c_67, c_62, c_63, c_64, c_65, c_59, c_60, c_61])], [f4, s1, lemma_27, c_60, c_61, lemma_25, lemma_26, lemma_23, lemma_24, c_66, c_67])).
fof(discharged, plain, ((organization(sK4,sK6) & organization(sK3,sK5) & greater(sK8,sK7) & reorganization_free(sK3,sK5,sK5) & reorganization_free(sK4,sK6,sK6) & inertia(sK3,sK7,sK5) & inertia(sK4,sK8,sK6) & survival_chance(sK3,sK9,sK5) & survival_chance(sK4,sK10,sK6)) => greater(sK10,sK9)), inference(implies, [status(thm), discharge(implies, [c_66, c_67, c_59, c_65, c_64, c_63, c_62, c_61, c_60])], [s2, c_66, c_67, c_59, c_65, c_64, c_63, c_62, c_61, c_60])).
fof(f7, theorem, ! [X0, X5, X12, X13, X16, X17, X10, X11]: ((greater(X17, X16) & survival_chance(X5, X11, X13) & survival_chance(X0, X10, X12) & inertia(X5, X17, X13) & inertia(X0, X16, X12) & reorganization_free(X5, X13, X13) & reorganization_free(X0, X12, X12) & organization(X5, X13) & organization(X0, X12)) => greater(X11, X10)), inference(generalization, [status(thm)], [discharged, f35])).
% SZS output end Proof
