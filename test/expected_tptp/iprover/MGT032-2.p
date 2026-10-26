% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2, X3]: (~ greater(growth_rate(X0, X1), growth_rate(X2, X1)) | ~ subpopulations(X2, X0, X3, X1) | ~ environment(X3) | selection_favors(X0, X2, X1)), file('Problems/MGT/MGT032-2.p', mp1_high_growth_rates_1)).
fof(c_50, plain, ! [X0]: (~ environment(X0) | ~ stable(X0) | in_environment(X0, sk1(X0))), file('Problems/MGT/MGT032-2.p', l1_2)).
fof(c_51, plain, ! [X0, X1]: (~ subpopulations(first_movers, efficient_producers, X0, X1) | ~ greater_or_equal(X1, sk1(X0)) | ~ environment(X0) | ~ stable(X0) | greater(growth_rate(efficient_producers, X1), growth_rate(first_movers, X1))), file('Problems/MGT/MGT032-2.p', l1_3)).
fof(c_52, plain, environment(sk2), file('Problems/MGT/MGT032-2.p', prove_t1_4)).
fof(c_53, plain, stable(sk2), file('Problems/MGT/MGT032-2.p', prove_t1_5)).
fof(c_54, plain, ! [X0]: (~ in_environment(sk2, X0) | subpopulations(first_movers, efficient_producers, sk2, sk3(X0))), file('Problems/MGT/MGT032-2.p', prove_t1_6)).
fof(c_55, plain, ! [X0]: (~ in_environment(sk2, X0) | greater_or_equal(sk3(X0), X0)), file('Problems/MGT/MGT032-2.p', prove_t1_7)).
fof(s1, plain, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [c_50, c_52, c_53])).
fof(lemma_8, lemma, greater_or_equal(sk3(sk1(sk2)),sk1(sk2)), inference(mp, [status(thm)], [c_55, s1])).
fof(s2, plain, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [c_50, c_52, c_53])).
fof(lemma_9, lemma, subpopulations(first_movers,efficient_producers,sk2,sk3(sk1(sk2))), inference(mp, [status(thm)], [c_54, s2])).
fof(s3, plain, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [c_50, c_52, c_53])).
fof(s4, plain, subpopulations(first_movers,efficient_producers,sk2,sk3(sk1(sk2))), inference(mp, [status(thm)], [c_54, s3])).
fof(s5, plain, greater(growth_rate(efficient_producers,sk3(sk1(sk2))),growth_rate(first_movers,sk3(sk1(sk2)))), inference(mp, [status(thm)], [c_51, s4, lemma_8, c_52, c_53])).
fof(goal_1, theorem, selection_favors(efficient_producers,first_movers,sk3(sk1(sk2))), inference(mp, [status(thm)], [c_49, s5, lemma_9, c_52])).
fof(goal_2, theorem, in_environment(sk2,sk1(sk2)), inference(mp, [status(thm)], [c_50, c_52, c_53])).
% SZS output end Proof
