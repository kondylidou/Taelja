% SZS output start Proof
cnf(c2, axiom, between(X, Y, extension(X, Y, W, V)), file('TPTP/Problems/GEO/GEO002-4.p', segment_construction1)).
cnf(c3, axiom, equidistant(Y2, extension(X2, Y2, W2, V2), W2, V2), file('TPTP/Problems/GEO/GEO002-4.p', segment_construction2)).
cnf(c4, axiom, ~ equidistant(X2, Y2, Z, Z) | equalish(X2, Y2), file('TPTP/Problems/GEO/GEO002-4.p', identity_for_equidistance)).
cnf(c6, axiom, ~ between(X2, Y2, V2) | ~ between(Y2, Z2, V2) | between(X2, Y2, Z2), file('TPTP/Problems/GEO/GEO002-4.p', transitivity_for_betweeness)).
cnf(c9, axiom, ~ equalish(X2, Y2) | ~ between(W2, Z2, X2) | between(W2, Z2, Y2), file('TPTP/Problems/GEO/GEO002-4.p', between_substitution3)).
cnf(c14, axiom, ~ between(X2, W2, V2) | ~ between(Y2, V2, Z2) | between(Z2, W2, outer_pasch(W2, X2, Y2, Z2, V2)), file('TPTP/Problems/GEO/GEO002-4.p', outer_pasch2)).
cnf(c28, axiom, ~ between(X2, W2, V2) | ~ between(Y2, V2, Z2) | between(X2, outer_pasch(W2, X2, Y2, Z2, V2), Y2), file('TPTP/Problems/GEO/GEO002-4.p', outer_pasch1)).
fof(s1, plain, ! [X,Y] : between(a,a,extension(a,a,X,Y)), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, ! [X,Y] : between(a,a,extension(a,a,X,Y)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_8, lemma, between(a,a,a), inference(mp, [status(thm)], [c6, s1, s2])).
fof(s3, plain, ! [X] : equidistant(a,extension(b,a,X,X),X,X), inference(instantiate, [status(thm)], [c3])).
fof(s4, plain, ! [X] : equalish(a,extension(b,a,X,X)), inference(mp, [status(thm)], [c4, s3])).
fof(lemma_9, lemma, ! [X] : between(a,a,extension(b,a,X,X)), inference(mp, [status(thm)], [c9, s4, lemma_8])).
fof(s5, plain, ! [X] : between(b,a,extension(b,a,X,X)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_10, lemma, between(b,a,a), inference(mp, [status(thm)], [c6, s5, lemma_9])).
fof(s6, plain, ! [X] : equidistant(a,extension(b,a,X,X),X,X), inference(instantiate, [status(thm)], [c3])).
fof(s7, plain, ! [X] : equalish(a,extension(b,a,X,X)), inference(mp, [status(thm)], [c4, s6])).
fof(lemma_11, lemma, ! [X] : between(a,a,extension(b,a,X,X)), inference(mp, [status(thm)], [c9, s7, lemma_8])).
fof(s8, plain, ! [X,Y] : between(b,b,extension(b,b,X,Y)), inference(instantiate, [status(thm)], [c2])).
fof(s9, plain, ! [X,Y] : between(b,b,extension(b,b,X,Y)), inference(instantiate, [status(thm)], [c2])).
fof(lemma_12, lemma, between(b,b,b), inference(mp, [status(thm)], [c6, s8, s9])).
fof(s10, plain, ! [X] : equidistant(b,extension(a,b,X,X),X,X), inference(instantiate, [status(thm)], [c3])).
fof(s11, plain, ! [X] : equalish(b,extension(a,b,X,X)), inference(mp, [status(thm)], [c4, s10])).
fof(lemma_13, lemma, ! [X] : between(b,b,extension(a,b,X,X)), inference(mp, [status(thm)], [c9, s11, lemma_12])).
fof(s12, plain, ! [X] : between(b,a,extension(b,a,X,X)), inference(instantiate, [status(thm)], [c2])).
fof(s13, plain, between(b,a,a), inference(mp, [status(thm)], [c6, s12, lemma_11])).
fof(lemma_14, lemma, between(b,outer_pasch(a,b,b,a,a),b), inference(mp, [status(thm)], [c28, s13, lemma_10])).
fof(s14, plain, ! [X] : between(a,b,extension(a,b,X,X)), inference(instantiate, [status(thm)], [c2])).
fof(s15, plain, between(a,b,b), inference(mp, [status(thm)], [c6, s14, lemma_13])).
fof(lemma_15, lemma, between(a,b,outer_pasch(a,b,b,a,a)), inference(mp, [status(thm)], [c6, s15, lemma_14])).
fof(s16, plain, ! [X] : between(b,a,extension(b,a,X,X)), inference(instantiate, [status(thm)], [c2])).
fof(s17, plain, between(b,a,a), inference(mp, [status(thm)], [c6, s16, lemma_9])).
fof(s18, plain, between(a,a,outer_pasch(a,b,b,a,a)), inference(mp, [status(thm)], [c14, s17, lemma_10])).
fof(goal_1, theorem, between(a,a,b), inference(mp, [status(thm)], [c6, s18, lemma_15])).
% SZS output end Proof
