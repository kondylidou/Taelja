% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(right_inverse, axiom, product(X1, inverse(X1), identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(closure_of_product_and_inverse, axiom, subgroup_member(X3) | ~ subgroup_member(X1) | ~ subgroup_member(X2) | ~ product(X1, inverse(X2), X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-2.ax', closure_of_product_and_inverse)).
cnf(a_times_b_is_c, hypothesis, product(a, b, c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP035-3.p', a_times_b_is_c)).
cnf(a_is_in_subgroup, hypothesis, subgroup_member(a), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP035-3.p', a_is_in_subgroup)).
cnf(b_is_in_subgroup, hypothesis, subgroup_member(b), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP035-3.p', b_is_in_subgroup)).
fof(s1, plain, product(b,identity,b), inference(instantiate, [status(thm)], [right_identity])).
fof(s2, plain, product(b,identity,multiply(b,identity)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_11, lemma, b = multiply(b,identity), inference(mp, [status(thm)], [total_function2, s1, s2])).
fof(s3, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s4, plain, product(inverse(b),inverse(inverse(b)),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s5, plain, product(b,identity,multiply(b,identity)), inference(instantiate, [status(thm)], [total_function1])).
fof(s6, plain, product(identity,inverse(inverse(b)),multiply(b,identity)), inference(mp, [status(thm)], [associativity2, s3, s4, s5])).
fof(lemma_12, lemma, product(identity,inverse(inverse(b)),b), inference(rewrite, [status(thm)], [lemma_11, s6])).
fof(s7, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s8, plain, subgroup_member(identity), inference(mp, [status(thm)], [closure_of_product_and_inverse, b_is_in_subgroup, b_is_in_subgroup, s7])).
fof(s9, plain, product(identity,inverse(b),inverse(b)), inference(instantiate, [status(thm)], [left_identity])).
fof(lemma_13, lemma, subgroup_member(inverse(b)), inference(mp, [status(thm)], [closure_of_product_and_inverse, s8, b_is_in_subgroup, s9])).
fof(s10, plain, product(identity,inverse(inverse(b)),inverse(inverse(b))), inference(instantiate, [status(thm)], [left_identity])).
fof(lemma_14, lemma, inverse(inverse(b)) = b, inference(mp, [status(thm)], [total_function2, s10, lemma_12])).
fof(s11, plain, product(a,b,multiply(a,b)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_15, lemma, c = multiply(a,b), inference(mp, [status(thm)], [total_function2, a_times_b_is_c, s11])).
fof(s12, plain, product(a,inverse(inverse(b)),multiply(a,inverse(inverse(b)))), inference(instantiate, [status(thm)], [total_function1])).
fof(s13, plain, subgroup_member(multiply(a,inverse(inverse(b)))), inference(mp, [status(thm)], [closure_of_product_and_inverse, a_is_in_subgroup, lemma_13, s12])).
fof(s14, plain, subgroup_member(multiply(a,b)), inference(rewrite, [status(thm)], [lemma_14, s13])).
fof(goal_1, theorem, subgroup_member(c), inference(rewrite, [status(thm)], [lemma_15, s14])).
% SZS output end Proof
