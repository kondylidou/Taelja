% SZS output start Proof
fof(skolem_definition, definition, ? [X2, X4]: ~ (property(X2) => (? [X3]: (object(X3) & is_the(X3, X2)) => (object(X4) => (is_the(X4, X2) => exemplifies_property(X2, X4))))) => ~ (property(esk1_0) => (? [X3]: (object(X3) & is_the(X3, esk1_0)) => (object(esk3_0) => (is_the(esk3_0, esk1_0) => exemplifies_property(esk1_0, esk3_0))))), introduced(definition, [new_symbols(definition, [esk1_0,esk3_0])], [])).
fof(lemma_1, axiom, ! [X1, X2, X3]: ((object(X1) & property(X2) & object(X3)) => ((is_the(X1, X2) & X1 = X3) => exemplifies_property(X2, X3))), file('Problems/PHI/PHI011+1.p', lemma_1)).
fof(description_is_property_and_described_is_object, axiom, ! [X1, X2]: (is_the(X1, X2) => (property(X2) & object(X1))), file('Problems/PHI/PHI011+1.p', description_is_property_and_described_is_object)).
fof(c_0_12, assumption, is_the(esk3_0,esk1_0), introduced(assumption, [], [])).
fof(axiom_2, plain, ! [X,Y] : (is_the(X,Y) => property(Y)), inference(clausify, [status(thm)], [description_is_property_and_described_is_object])).
fof(axiom_3, plain, ! [Y,X] : (is_the(Y,X) => object(Y)), inference(clausify, [status(thm)], [description_is_property_and_described_is_object])).
fof(lemma_5, lemma, property(esk1_0), inference(mp, [status(thm), assumptions([c_0_12])], [axiom_2, c_0_12])).
fof(lemma_6, lemma, object(esk3_0), inference(mp, [status(thm), assumptions([c_0_12])], [axiom_3, c_0_12])).
fof(s1, plain, object(esk3_0), inference(mp, [status(thm), assumptions([c_0_12])], [axiom_3, c_0_12])).
fof(s2, plain, exemplifies_property(esk1_0,esk3_0), inference(mp, [status(thm), assumptions([c_0_12])], [lemma_1, s1, lemma_5, lemma_6, c_0_12])).
fof(discharged, plain, (is_the(esk3_0,esk1_0) => exemplifies_property(esk1_0,esk3_0)), inference(implies, [status(thm), discharge(implies, [c_0_12])], [s2, c_0_12])).
fof(description_theorem_2, theorem, ! [X2]: (property(X2) => (? [X3]: (object(X3) & is_the(X3, X2)) => ! [X4]: (object(X4) => (is_the(X4, X2) => exemplifies_property(X2, X4))))), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
