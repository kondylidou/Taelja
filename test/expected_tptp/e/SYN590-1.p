% SZS output start Proof
cnf(p10_26, negated_conjecture, p10(X1, X2) | ~ p3(X3, X1) | ~ p3(X4, X2) | ~ p10(X3, X4), file('Problems/SYN/SYN590-1.p', p10_26)).
cnf(p3_8, negated_conjecture, p3(f4(c16), f6(c15)), file('Problems/SYN/SYN590-1.p', p3_8)).
cnf(p10_19, negated_conjecture, p10(f4(f9(X1)), f4(X1)) | ~ p11(X1), file('Problems/SYN/SYN590-1.p', p10_19)).
cnf(c16_is_p11_3, negated_conjecture, p11(c16), file('Problems/SYN/SYN590-1.p', c16_is_p11_3)).
cnf(p3_18, negated_conjecture, p3(f4(X1), f6(f8(X1))) | ~ p11(X1), file('Problems/SYN/SYN590-1.p', p3_18)).
cnf(p12_11, negated_conjecture, p12(X1, X2) | ~ p10(f6(X1), f6(X2)), file('Problems/SYN/SYN590-1.p', p12_11)).
cnf(p11_9, negated_conjecture, p11(f9(X1)) | ~ p11(X1), file('Problems/SYN/SYN590-1.p', p11_9)).
fof(lemma_8, lemma, p10(f4(f9(c16)),f4(c16)), inference(mp, [status(thm)], [p10_19, c16_is_p11_3])).
fof(goal_1, theorem, p11(f9(c16)), inference(mp, [status(thm)], [p11_9, c16_is_p11_3])).
fof(s1, plain, p11(f9(c16)), inference(mp, [status(thm)], [p11_9, c16_is_p11_3])).
fof(s2, plain, p3(f4(f9(c16)),f6(f8(f9(c16)))), inference(mp, [status(thm)], [p3_18, s1])).
fof(s3, plain, p10(f6(f8(f9(c16))),f6(c15)), inference(mp, [status(thm)], [p10_26, s2, p3_8, lemma_8])).
fof(goal_2, theorem, p12(f8(f9(c16)),c15), inference(mp, [status(thm)], [p12_11, s3])).
fof(s4, plain, p11(f9(c16)), inference(mp, [status(thm)], [p11_9, c16_is_p11_3])).
fof(goal_3, theorem, p3(f4(f9(c16)),f6(f8(f9(c16)))), inference(mp, [status(thm)], [p3_18, s4])).
% SZS output end Proof
