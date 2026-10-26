% SZS output start Proof
fof(c_50, plain, ! [X0, X1, X2]: (compose(a, X0) != X1 | compose(a, X2) != X1 | X0 = X2), file('Problems/CAT/CAT002-4.p', cancellation_for_compose1)).
fof(c_51, plain, ! [X0, X1, X2]: (compose(b, X0) != X1 | compose(b, X2) != X1 | X0 = X2), file('Problems/CAT/CAT002-4.p', cancellation_for_compose2)).
fof(c_53, plain, compose(compose(a, b), h) = compose(compose(a, b), g), file('Problems/CAT/CAT002-4.p', ab_h_equals_ab_g)).
fof(c_63, plain, ! [X0, X1, X2]: compose(compose(X0, X1), X2) = compose(X0, compose(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/CAT004-0.ax', associativity_of_compose)).
fof(s1, plain, compose(a,compose(b,h)) = compose(compose(a,b),h), inference(instantiate, [status(thm)], [c_63])).
fof(s2, plain, compose(a,compose(b,h)) = compose(compose(a,b),g), inference(rewrite, [status(thm)], [c_53, s1])).
fof(lemma_5, lemma, compose(a,compose(b,h)) = compose(a,compose(b,g)), inference(rewrite, [status(thm)], [c_63, s2])).
fof(s3, plain, compose(b,h) = compose(b,g), inference(mp, [status(thm)], [c_50, lemma_5])).
fof(goal_1, theorem, h = g, inference(mp, [status(thm)], [c_51, s3])).
% SZS output end Proof
