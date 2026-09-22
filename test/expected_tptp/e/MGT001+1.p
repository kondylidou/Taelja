% SZS output start Proof
fof(a3_FOL, hypothesis, ! [X1, X6, X13, X14, X15, X16, X17, X18]: ((organization(X1, X13) & organization(X6, X14) & reorganization_free(X1, X13, X13) & reorganization_free(X6, X14, X14) & reproducibility(X1, X15, X13) & reproducibility(X6, X16, X14) & inertia(X1, X17, X13) & inertia(X6, X18, X14)) => (greater(X16, X15) <=> greater(X18, X17))), file('Problems/MGT/MGT001+1.p', a3_FOL)).
fof(mp3, axiom, ! [X1, X2]: (organization(X1, X2) => ? [X5]: reproducibility(X1, X5, X2)), file('Problems/MGT/MGT001+1.p', mp3)).
fof(a2_FOL, hypothesis, ! [X1, X6, X13, X14, X7, X8, X9, X10, X15, X16]: ((organization(X1, X13) & organization(X6, X14) & reliability(X1, X7, X13) & reliability(X6, X8, X14) & accountability(X1, X9, X13) & accountability(X6, X10, X14) & reproducibility(X1, X15, X13) & reproducibility(X6, X16, X14)) => (greater(X16, X15) <=> (greater(X8, X7) & greater(X10, X9)))), file('Problems/MGT/MGT001+1.p', a2_FOL)).
fof(mp2, axiom, ! [X1, X2]: (organization(X1, X2) => ? [X4]: accountability(X1, X4, X2)), file('Problems/MGT/MGT001+1.p', mp2)).
fof(a1_FOL, hypothesis, ! [X1, X6, X7, X8, X9, X10, X11, X12, X13, X14]: ((organization(X1, X13) & organization(X6, X14) & reliability(X1, X7, X13) & reliability(X6, X8, X14) & accountability(X1, X9, X13) & accountability(X6, X10, X14) & survival_chance(X1, X11, X13) & survival_chance(X6, X12, X14) & greater(X8, X7) & greater(X10, X9)) => greater(X12, X11)), file('Problems/MGT/MGT001+1.p', a1_FOL)).
fof(mp1, axiom, ! [X1, X2]: (organization(X1, X2) => ? [X3]: reliability(X1, X3, X2)), file('Problems/MGT/MGT001+1.p', mp1)).
fof(skolem_c_0_32, definition, ! [X1, X2]: (organization(X1, X2) => ? [X3]: reliability(X1, X3, X2)) => ! [X19, X20]: (~ organization(X19, X20) | reliability(X19, esk1_2(X19, X20), X20)), introduced(definition, [new_symbols(definition, [esk1_2])], [])).
fof(skolem_c_0_28, definition, ! [X1, X2]: (organization(X1, X2) => ? [X4]: accountability(X1, X4, X2)) => ! [X22, X23]: (~ organization(X22, X23) | accountability(X22, esk2_2(X22, X23), X23)), introduced(definition, [new_symbols(definition, [esk2_2])], [])).
fof(skolem_c_0_14, definition, ! [X1, X2]: (organization(X1, X2) => ? [X5]: reproducibility(X1, X5, X2)) => ! [X25, X26]: (~ organization(X25, X26) | reproducibility(X25, esk3_2(X25, X26), X26)), introduced(definition, [new_symbols(definition, [esk3_2])], [])).
fof(c_0_23, assumption, organization(esk4_0,esk6_0), introduced(assumption, [], [])).
fof(axiom_2, plain, ! [X,Y] : (organization(X,Y) => reliability(X,esk1_2(X,Y),Y)), inference(clausify, [status(thm)], [mp1, skolem_c_0_32])).
fof(c_0_13, assumption, organization(esk5_0,esk7_0), introduced(assumption, [], [])).
fof(axiom_4, plain, ! [X,Y] : (organization(X,Y) => accountability(X,esk2_2(X,Y),Y)), inference(clausify, [status(thm)], [mp2, skolem_c_0_28])).
fof(axiom_5, plain, ! [X,Y] : (organization(X,Y) => reproducibility(X,esk3_2(X,Y),Y)), inference(clausify, [status(thm)], [mp3, skolem_c_0_14])).
fof(c_0_22, assumption, greater(esk9_0,esk8_0), introduced(assumption, [], [])).
fof(c_0_21, assumption, reorganization_free(esk4_0,esk6_0,esk6_0), introduced(assumption, [], [])).
fof(c_0_20, assumption, inertia(esk4_0,esk8_0,esk6_0), introduced(assumption, [], [])).
fof(c_0_12, assumption, reorganization_free(esk5_0,esk7_0,esk7_0), introduced(assumption, [], [])).
fof(c_0_11, assumption, inertia(esk5_0,esk9_0,esk7_0), introduced(assumption, [], [])).
fof(axiom_11, plain, ! [X,Y,Z,A,B,C,U,V] : ((greater(X,Y) & organization(Z,A) & organization(B,C) & reorganization_free(Z,A,A) & reorganization_free(B,C,C) & reproducibility(Z,U,A) & reproducibility(B,V,C) & inertia(Z,Y,A) & inertia(B,X,C)) => greater(V,U)), inference(clausify, [status(thm)], [a3_FOL])).
fof(axiom_12, plain, ! [V,U,Z,A,B,C,Y,X,W,X1] : ((greater(V,U) & organization(Z,A) & organization(B,C) & reliability(Z,Y,A) & reliability(B,X,C) & accountability(Z,W,A) & accountability(B,X1,C) & reproducibility(Z,U,A) & reproducibility(B,V,C)) => greater(X,Y)), inference(clausify, [status(thm)], [a2_FOL])).
fof(c_0_47, assumption, survival_chance(esk4_0,esk10_0,esk6_0), introduced(assumption, [], [])).
fof(axiom_14, plain, ! [V,U,Z,A,B,C,W,X1,Y,X] : ((greater(V,U) & organization(Z,A) & organization(B,C) & reliability(Z,W,A) & reliability(B,X1,C) & accountability(Z,Y,A) & accountability(B,X,C) & reproducibility(Z,U,A) & reproducibility(B,V,C)) => greater(X,Y)), inference(clausify, [status(thm)], [a2_FOL])).
fof(c_0_34, assumption, survival_chance(esk5_0,esk11_0,esk7_0), introduced(assumption, [], [])).
fof(lemma_17, lemma, reproducibility(esk4_0,esk3_2(esk4_0,esk6_0),esk6_0), inference(mp, [status(thm), assumptions([c_0_23])], [axiom_5, c_0_23])).
fof(lemma_18, lemma, reproducibility(esk5_0,esk3_2(esk5_0,esk7_0),esk7_0), inference(mp, [status(thm), assumptions([c_0_13])], [axiom_5, c_0_13])).
fof(lemma_19, lemma, reliability(esk4_0,esk1_2(esk4_0,esk6_0),esk6_0), inference(mp, [status(thm), assumptions([c_0_23])], [axiom_2, c_0_23])).
fof(lemma_20, lemma, reliability(esk5_0,esk1_2(esk5_0,esk7_0),esk7_0), inference(mp, [status(thm), assumptions([c_0_13])], [axiom_2, c_0_13])).
fof(lemma_21, lemma, accountability(esk4_0,esk2_2(esk4_0,esk6_0),esk6_0), inference(mp, [status(thm), assumptions([c_0_23])], [axiom_4, c_0_23])).
fof(lemma_22, lemma, accountability(esk5_0,esk2_2(esk5_0,esk7_0),esk7_0), inference(mp, [status(thm), assumptions([c_0_13])], [axiom_4, c_0_13])).
fof(s1, plain, greater(esk3_2(esk5_0,esk7_0),esk3_2(esk4_0,esk6_0)), inference(mp, [status(thm), assumptions([c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, c_0_20, c_0_11])], [axiom_11, c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, lemma_17, lemma_18, c_0_20, c_0_11])).
fof(lemma_23, lemma, greater(esk1_2(esk5_0,esk7_0),esk1_2(esk4_0,esk6_0)), inference(mp, [status(thm), assumptions([c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, c_0_20, c_0_11])], [axiom_12, s1, c_0_23, c_0_13, lemma_19, lemma_20, lemma_21, lemma_22, lemma_17, lemma_18])).
fof(s2, plain, greater(esk3_2(esk5_0,esk7_0),esk3_2(esk4_0,esk6_0)), inference(mp, [status(thm), assumptions([c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, c_0_20, c_0_11])], [axiom_11, c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, lemma_17, lemma_18, c_0_20, c_0_11])).
fof(lemma_24, lemma, greater(esk2_2(esk5_0,esk7_0),esk2_2(esk4_0,esk6_0)), inference(mp, [status(thm), assumptions([c_0_22, c_0_23, c_0_13, c_0_21, c_0_12, c_0_20, c_0_11])], [axiom_14, s2, c_0_23, c_0_13, lemma_19, lemma_20, lemma_21, lemma_22, lemma_17, lemma_18])).
fof(s3, plain, survival_chance(esk4_0,esk10_0,esk6_0), inference(instantiate, [status(thm), assumptions([c_0_47])], [c_0_47])).
fof(s4, plain, survival_chance(esk5_0,esk11_0,esk7_0), inference(instantiate, [status(thm), assumptions([c_0_34])], [c_0_34])).
fof(s5, plain, greater(esk11_0,esk10_0), inference(mp, [status(thm), assumptions([c_0_23, c_0_13, c_0_47, c_0_34, c_0_22, c_0_21, c_0_12, c_0_20, c_0_11])], [a1_FOL, c_0_23, c_0_13, lemma_19, lemma_20, lemma_21, lemma_22, s3, s4, lemma_23, lemma_24])).
fof(discharged, plain, ((organization(esk4_0,esk6_0) & organization(esk5_0,esk7_0) & greater(esk9_0,esk8_0) & reorganization_free(esk4_0,esk6_0,esk6_0) & inertia(esk4_0,esk8_0,esk6_0) & reorganization_free(esk5_0,esk7_0,esk7_0) & inertia(esk5_0,esk9_0,esk7_0) & survival_chance(esk4_0,esk10_0,esk6_0) & survival_chance(esk5_0,esk11_0,esk7_0)) => greater(esk11_0,esk10_0)), inference(implies, [status(thm), discharge(implies, [c_0_23, c_0_13, c_0_22, c_0_21, c_0_20, c_0_12, c_0_11, c_0_47, c_0_34])], [s5, c_0_23, c_0_13, c_0_22, c_0_21, c_0_20, c_0_12, c_0_11, c_0_47, c_0_34])).
fof(t1_FOL, theorem, ! [X1, X6, X13, X14, X17, X18, X11, X12]: ((organization(X1, X13) & organization(X6, X14) & reorganization_free(X1, X13, X13) & reorganization_free(X6, X14, X14) & inertia(X1, X17, X13) & inertia(X6, X18, X14) & survival_chance(X1, X11, X13) & survival_chance(X6, X12, X14) & greater(X18, X17)) => greater(X12, X11)), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
