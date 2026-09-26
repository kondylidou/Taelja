% SZS output start Proof
cnf(c3, hypothesis, product(inverse(a), inverse(b), d), file('TPTP/Problems/GRP/GRP013-1.p', inverse_a_times_inverse_b_is_d)).
cnf(c4, hypothesis, product(a, b, c), file('TPTP/Problems/GRP/GRP013-1.p', a_times_b_is_c)).
cnf(c5, axiom, ~ product(X, Y, Z) | ~ product(X, Y, W) | Z = W, file('TPTP/Problems/GRP/GRP013-1.p', total_function2)).
cnf(c7, axiom, product(X2, inverse(X2), identity), file('TPTP/Problems/GRP/GRP013-1.p', right_inverse)).
cnf(c8, hypothesis, ~ product(inverse(A), inverse(B), C) | product(A, C, B), file('TPTP/Problems/GRP/GRP013-1.p', inverses_have_property)).
cnf(c10, axiom, product(X2, identity, X2), file('TPTP/Problems/GRP/GRP013-1.p', right_identity)).
cnf(c17, hypothesis, product(A2, A2, identity), file('TPTP/Problems/GRP/GRP013-1.p', squareness)).
fof(s1, plain, ! [X] : product(inverse(X),inverse(inverse(X)),identity), inference(instantiate, [status(thm)], [c7])).
fof(lemma_8, lemma, ! [X] : product(X,identity,inverse(X)), inference(mp, [status(thm)], [c8, s1])).
fof(lemma_9, lemma, ! [X] : inverse(X) = X, inference(mp, [status(thm)], [c5, c10, lemma_8])).
fof(s2, plain, product(a,inverse(b),d), inference(rewrite, [status(thm)], [lemma_9, c3])).
fof(lemma_10, lemma, product(a,b,d), inference(rewrite, [status(thm)], [lemma_9, s2])).
fof(lemma_11, lemma, d = c, inference(mp, [status(thm)], [c5, c4, lemma_10])).
fof(s3, plain, product(c,c,identity), inference(instantiate, [status(thm)], [c17])).
fof(goal_1, theorem, product(c,d,identity), inference(rewrite, [status(thm)], [lemma_11, s3])).
% SZS output end Proof
