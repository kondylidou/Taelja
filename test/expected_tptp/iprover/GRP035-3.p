% SZS output start Proof
fof(c_49, plain, subgroup_member(a), file('GRP035-3.p', a_is_in_subgroup)).
fof(c_50, plain, subgroup_member(b), file('GRP035-3.p', b_is_in_subgroup)).
fof(c_51, plain, product(a, b, c), file('GRP035-3.p', a_times_b_is_c)).
fof(c_53, plain, ! [X0, X1, X2]: (~ product(X0, inverse(X1), X2) | ~ subgroup_member(X0) | ~ subgroup_member(X1) | subgroup_member(X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-2.ax', closure_of_product_and_inverse)).
fof(c_54, plain, ! [X0]: product(identity, X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
fof(c_55, plain, ! [X0]: product(X0, identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(c_57, plain, ! [X0]: product(X0, inverse(X0), identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
fof(c_58, plain, ! [X0, X1]: product(X0, X1, multiply(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
fof(c_59, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
fof(c_60, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X1, X3, X4) | ~ product(X2, X3, X5) | product(X0, X4, X5)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity1)).
fof(c_61, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X0, X3, X4) | ~ product(X1, X5, X3) | product(X2, X5, X4)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
fof(s1, plain, product(a,inverse(a),identity), inference(instantiate, [status(thm)], [c_57])).
fof(lemma_12, lemma, subgroup_member(identity), inference(mp, [status(thm)], [c_53, s1, c_49, c_49])).
fof(s2, plain, product(b,identity,b), inference(instantiate, [status(thm)], [c_55])).
fof(lemma_13, lemma, product(c,identity,c), inference(mp, [status(thm)], [c_61, c_51, c_51, s2])).
fof(s3, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [c_57])).
fof(s4, plain, product(c,inverse(b),multiply(c,inverse(b))), inference(instantiate, [status(thm)], [c_58])).
fof(lemma_14, lemma, product(a,identity,multiply(c,inverse(b))), inference(mp, [status(thm)], [c_60, c_51, s3, s4])).
fof(s5, plain, product(a,identity,a), inference(instantiate, [status(thm)], [c_55])).
fof(lemma_15, lemma, a = multiply(c,inverse(b)), inference(mp, [status(thm)], [c_59, s5, lemma_14])).
fof(s6, plain, product(identity,inverse(b),inverse(b)), inference(instantiate, [status(thm)], [c_54])).
fof(lemma_16, lemma, subgroup_member(inverse(b)), inference(mp, [status(thm)], [c_53, s6, lemma_12, c_50])).
fof(s7, plain, product(c,inverse(b),multiply(c,inverse(b))), inference(instantiate, [status(thm)], [c_58])).
fof(s8, plain, product(c,inverse(b),a), inference(rewrite, [status(thm)], [lemma_15, s7])).
fof(s9, plain, product(inverse(b),inverse(inverse(b)),identity), inference(instantiate, [status(thm)], [c_57])).
fof(s10, plain, product(a,inverse(inverse(b)),c), inference(mp, [status(thm)], [c_61, s8, lemma_13, s9])).
fof(goal_1, theorem, subgroup_member(c), inference(mp, [status(thm)], [c_53, s10, c_49, lemma_16])).
% SZS output end Proof
