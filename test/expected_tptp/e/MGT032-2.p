% SZS output start Proof
cnf(l1_3, hypothesis, greater(growth_rate(efficient_producers, X2), growth_rate(first_movers, X2)) | ~ environment(X1) | ~ stable(X1) | ~ subpopulations(first_movers, efficient_producers, X1, X2) | ~ greater_or_equal(X2, sk1(X1)), file('Problems/MGT/MGT032-2.p', l1_3)).
cnf(prove_t1_7, negated_conjecture, greater_or_equal(sk3(X1), X1) | ~ in_environment(sk2, X1), file('Problems/MGT/MGT032-2.p', prove_t1_7)).
cnf(mp1_high_growth_rates_1, axiom, selection_favors(X3, X2, X4) | ~ environment(X1) | ~ subpopulations(X2, X3, X1, X4) | ~ greater(growth_rate(X3, X4), growth_rate(X2, X4)), file('Problems/MGT/MGT032-2.p', mp1_high_growth_rates_1)).
cnf(prove_t1_6, negated_conjecture, subpopulations(first_movers, efficient_producers, sk2, sk3(X1)) | ~ in_environment(sk2, X1), file('Problems/MGT/MGT032-2.p', prove_t1_6)).
cnf(prove_t1_4, negated_conjecture, environment(sk2), file('Problems/MGT/MGT032-2.p', prove_t1_4)).
cnf(prove_t1_5, negated_conjecture, stable(sk2), file('Problems/MGT/MGT032-2.p', prove_t1_5)).
cnf(l1_2, hypothesis, in_environment(X1, sk1(X1)) | ~ environment(X1) | ~ stable(X1), file('Problems/MGT/MGT032-2.p', l1_2)).
fof(s1, plain, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [l1_2, prove_t1_4, prove_t1_5])).
fof(lemma_8, lemma, subpopulations(first_movers,efficient_producers,sk2,sk3(sk1(sk2))), inference(mp, [status(thm)], [prove_t1_6, s1])).
fof(s2, plain, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [l1_2, prove_t1_4, prove_t1_5])).
fof(lemma_9, lemma, greater_or_equal(sk3(sk1(sk2)),sk1(sk2)), inference(mp, [status(thm)], [prove_t1_7, s2])).
fof(lemma_10, lemma, greater(growth_rate(efficient_producers,sk3(sk1(sk2))),growth_rate(first_movers,sk3(sk1(sk2)))), inference(mp, [status(thm)], [l1_3, prove_t1_4, prove_t1_5, lemma_8, lemma_9])).
fof(goal_1, theorem, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [l1_2, prove_t1_4, prove_t1_5])).
fof(goal_2, theorem, selection_favors(efficient_producers,first_movers,sk3(sk1(sk2))), inference(mp, [status(thm)], [mp1_high_growth_rates_1, prove_t1_4, lemma_8, lemma_10])).
% SZS output end Proof
