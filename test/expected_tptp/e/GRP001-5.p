% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', associativity2)).
cnf(associativity1, axiom, product(X1, X5, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X3, X4, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', associativity1)).
cnf(square_element, hypothesis, product(X1, X1, identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', square_element)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', left_identity)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', right_identity)).
cnf(a_times_b_is_c, hypothesis, product(a, b, c), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/GRP/GRP001-5.p', a_times_b_is_c)).
fof(s1, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_7, lemma, ! [X,Y,Z] : (product(X,Y,Z) => product(Z,Y,X)), inference(mp, [status(thm)], [associativity2, s1, square_element, right_identity])).
fof(lemma_8, lemma, product(c,b,a), inference(mp, [status(thm)], [lemma_7, a_times_b_is_c])).
fof(s2, plain, product(c,c,identity), inference(instantiate, [status(thm)], [square_element])).
fof(s3, plain, product(identity,b,b), inference(instantiate, [status(thm)], [left_identity])).
fof(s4, plain, product(c,a,b), inference(mp, [status(thm)], [associativity1, s2, lemma_8, s3])).
fof(goal_1, theorem, product(b,a,c), inference(mp, [status(thm)], [lemma_7, s4])).
% SZS output end Proof
