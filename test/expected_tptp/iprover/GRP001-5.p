% SZS output start Proof
fof(c_49, plain, ! [X0]: product(identity, X0, X0), file('Problems/GRP/GRP001-5.p', left_identity)).
fof(c_50, plain, ! [X0]: product(X0, identity, X0), file('Problems/GRP/GRP001-5.p', right_identity)).
fof(c_51, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X1, X3, X4) | ~ product(X2, X3, X5) | product(X0, X4, X5)), file('Problems/GRP/GRP001-5.p', associativity1)).
fof(c_52, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X0, X3, X4) | ~ product(X1, X5, X3) | product(X2, X5, X4)), file('Problems/GRP/GRP001-5.p', associativity2)).
fof(c_53, plain, ! [X0]: product(X0, X0, identity), file('Problems/GRP/GRP001-5.p', square_element)).
fof(c_54, plain, product(a, b, c), file('Problems/GRP/GRP001-5.p', a_times_b_is_c)).
fof(s1, plain, ! [X,Y,Z] : ((product(a,X,Y) & product(b,Z,X)) => product(a,X,Y)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y,Z] : ((product(a,X,Y) & product(b,Z,X)) => product(b,Z,X)), inference(assumption, [status(thm)], [])).
fof(lemma_7, lemma, ! [X,Y,Z] : ((product(a,X,Y) & product(b,Z,X)) => product(c,Z,Y)), inference(mp, [status(thm)], [c_52, c_54, s1, s2])).
fof(s3, plain, product(a,identity,a), inference(instantiate, [status(thm)], [c_50])).
fof(s4, plain, product(b,b,identity), inference(instantiate, [status(thm)], [c_53])).
fof(lemma_8, lemma, product(c,b,a), inference(mp, [status(thm)], [lemma_7, s3, s4])).
fof(s5, plain, ! [X,Y,Z,A] : ((product(X,Y,Z) & product(identity,Y,A)) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s6, plain, ! [X,Y,Z,A] : ((product(X,Y,Z) & product(identity,Y,A)) => product(identity,Y,A)), inference(assumption, [status(thm)], [])).
fof(lemma_9, lemma, ! [X,Y,Z,A] : ((product(X,Y,Z) & product(identity,Y,A)) => product(X,Z,A)), inference(mp, [status(thm)], [c_51, c_53, s5, s6])).
fof(s7, plain, product(identity,b,b), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_10, lemma, product(a,c,b), inference(mp, [status(thm)], [lemma_9, c_54, s7])).
fof(s8, plain, product(identity,b,b), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_11, lemma, product(c,a,b), inference(mp, [status(thm)], [lemma_9, lemma_8, s8])).
fof(lemma_12, lemma, product(b,a,c), inference(mp, [status(thm)], [c_52, lemma_10, c_54, lemma_11])).
fof(goal_1, theorem, product(b,a,c), inference(instantiate, [status(thm)], [lemma_12])).
% SZS output end Proof
