% SZS output start Proof
fof(c_51, plain, p11(c16), file('Problems/SYN/SYN590-1.p', c16_is_p11_3)).
fof(c_56, plain, p3(f4(c16), f6(c15)), file('Problems/SYN/SYN590-1.p', p3_8)).
fof(c_57, plain, ! [X0]: (~ p11(X0) | p11(f9(X0))), file('Problems/SYN/SYN590-1.p', p11_9)).
fof(c_59, plain, ! [X0, X1]: (~ p10(f6(X0), f6(X1)) | p12(X0, X1)), file('Problems/SYN/SYN590-1.p', p12_11)).
fof(c_66, plain, ! [X0]: (~ p11(X0) | p3(f4(X0), f6(f8(X0)))), file('Problems/SYN/SYN590-1.p', p3_18)).
fof(c_67, plain, ! [X0]: (~ p11(X0) | p10(f4(f9(X0)), f4(X0))), file('Problems/SYN/SYN590-1.p', p10_19)).
fof(c_74, plain, ! [X0, X1, X2, X3]: (~ p3(X0, X1) | ~ p3(X2, X3) | ~ p10(X0, X2) | p10(X1, X3)), file('Problems/SYN/SYN590-1.p', p10_26)).
fof(lemma_8, lemma, p11(f9(c16)), inference(mp, [status(thm)], [c_57, c_51])).
fof(lemma_9, lemma, p3(f4(f9(c16)),f6(f8(f9(c16)))), inference(mp, [status(thm)], [c_66, lemma_8])).
fof(lemma_10, lemma, p10(f4(f9(c16)),f4(c16)), inference(mp, [status(thm)], [c_67, c_51])).
fof(goal_1, theorem, p3(f4(f9(c16)),f6(f8(f9(c16)))), inference(instantiate, [status(thm)], [lemma_9])).
fof(s1, plain, p10(f6(f8(f9(c16))),f6(c15)), inference(mp, [status(thm)], [c_74, lemma_9, c_56, lemma_10])).
fof(goal_2, theorem, p12(f8(f9(c16)),c15), inference(mp, [status(thm)], [c_59, s1])).
fof(goal_3, theorem, p11(f9(c16)), inference(instantiate, [status(thm)], [lemma_8])).
% SZS output end Proof
