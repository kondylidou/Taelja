% SZS output start Proof
fof(c_49, plain, defined(h, a), file('Problems/CAT/CAT006-1.p', ha_defined)).
fof(c_50, plain, identity_map(h), file('Problems/CAT/CAT006-1.p', h_is_the_identity_map)).
fof(c_54, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ defined(X2, X3) | defined(X1, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', associative_property2)).
fof(c_56, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X1, X3, X4) | ~ product(X2, X3, X5) | product(X0, X4, X5)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', category_theory_axiom2)).
fof(c_57, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ defined(X3, X2) | defined(X3, X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', category_theory_axiom3)).
fof(c_62, plain, ! [X0]: identity_map(codomain(X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', codomain_is_an_identity_map)).
fof(c_66, plain, ! [X0]: product(codomain(X0), X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', product_on_codomain)).
fof(c_67, plain, ! [X0, X1]: (~ defined(X0, X1) | ~ identity_map(X0) | product(X0, X1, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', identity1)).
fof(c_68, plain, ! [X0, X1]: (~ defined(X0, X1) | ~ identity_map(X1) | product(X0, X1, X0)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', identity2)).
fof(c_69, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT001-0.ax', composition_is_well_defined)).
fof(s1, plain, ! [X,Y,Z] : ((defined(X,Y) & defined(X,Z) & identity_map(Y)) => defined(X,Y)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y,Z] : ((defined(X,Y) & defined(X,Z) & identity_map(Y)) => identity_map(Y)), inference(assumption, [status(thm)], [])).
fof(s3, plain, ! [X,Y,Z] : ((defined(X,Y) & defined(X,Z) & identity_map(Y)) => product(X,Y,X)), inference(mp, [status(thm)], [c_68, s1, s2])).
fof(s4, plain, ! [X,Y,Z] : ((defined(X,Y) & defined(X,Z) & identity_map(Y)) => defined(X,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_11, lemma, ! [X,Y,Z] : ((defined(X,Y) & defined(X,Z) & identity_map(Y)) => defined(Y,Z)), inference(mp, [status(thm)], [c_54, s3, s4])).
fof(s5, plain, product(h,a,a), inference(mp, [status(thm)], [c_67, c_49, c_50])).
fof(lemma_12, lemma, defined(h,h), inference(mp, [status(thm)], [c_57, s5, c_49])).
fof(s6, plain, product(codomain(a),a,a), inference(instantiate, [status(thm)], [c_66])).
fof(s7, plain, defined(h,codomain(a)), inference(mp, [status(thm)], [c_57, s6, c_49])).
fof(s8, plain, identity_map(codomain(a)), inference(instantiate, [status(thm)], [c_62])).
fof(s9, plain, defined(codomain(a),h), inference(mp, [status(thm)], [lemma_11, s7, lemma_12, s8])).
fof(s10, plain, identity_map(codomain(a)), inference(instantiate, [status(thm)], [c_62])).
fof(lemma_13, lemma, product(codomain(a),h,h), inference(mp, [status(thm)], [c_67, s9, s10])).
fof(s11, plain, product(codomain(a),a,a), inference(instantiate, [status(thm)], [c_66])).
fof(s12, plain, defined(h,codomain(a)), inference(mp, [status(thm)], [c_57, s11, c_49])).
fof(s13, plain, identity_map(codomain(a)), inference(instantiate, [status(thm)], [c_62])).
fof(s14, plain, defined(codomain(a),h), inference(mp, [status(thm)], [lemma_11, s12, lemma_12, s13])).
fof(lemma_14, lemma, product(codomain(a),h,codomain(a)), inference(mp, [status(thm)], [c_68, s14, c_50])).
fof(s15, plain, product(codomain(codomain(a)),codomain(a),codomain(a)), inference(instantiate, [status(thm)], [c_66])).
fof(lemma_15, lemma, product(codomain(codomain(a)),codomain(a),h), inference(mp, [status(thm)], [c_56, s15, lemma_14, lemma_13])).
fof(s16, plain, product(codomain(codomain(a)),codomain(a),codomain(a)), inference(instantiate, [status(thm)], [c_66])).
fof(goal_1, theorem, codomain(a) = h, inference(mp, [status(thm)], [c_69, s16, lemma_15])).
% SZS output end Proof
