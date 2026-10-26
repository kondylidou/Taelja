% SZS output start Proof
fof(c_49, plain, product(a, b, identity), file('Problems/GRP/GRP009-1.p', a_is_an_inverse_of_b)).
fof(c_50, plain, product(c, b, identity), file('Problems/GRP/GRP009-1.p', c_is_an_inverse_of_b)).
fof(c_52, plain, ! [X0]: product(identity, X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
fof(c_53, plain, ! [X0]: product(X0, identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
fof(c_55, plain, ! [X0]: product(X0, inverse(X0), identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
fof(c_57, plain, ! [X0, X1, X2, X3]: (~ product(X0, X1, X2) | ~ product(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
fof(c_58, plain, ! [X0, X1, X2, X3, X4, X5]: (~ product(X0, X1, X2) | ~ product(X1, X3, X4) | ~ product(X2, X3, X5) | product(X0, X4, X5)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity1)).
fof(s1, plain, ! [X,Y] : (product(X,identity,Y) => product(X,identity,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_8, lemma, ! [X,Y] : (product(X,identity,Y) => X = Y), inference(mp, [status(thm)], [c_57, c_53, s1])).
fof(s2, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [c_55])).
fof(s3, plain, product(identity,inverse(b),inverse(b)), inference(instantiate, [status(thm)], [c_52])).
fof(s4, plain, product(a,identity,inverse(b)), inference(mp, [status(thm)], [c_58, c_49, s2, s3])).
fof(lemma_9, lemma, a = inverse(b), inference(mp, [status(thm)], [lemma_8, s4])).
fof(s5, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [c_55])).
fof(lemma_10, lemma, product(b,a,identity), inference(rewrite, [status(thm)], [lemma_9, s5])).
fof(s6, plain, product(identity,a,a), inference(instantiate, [status(thm)], [c_52])).
fof(s7, plain, product(c,identity,a), inference(mp, [status(thm)], [c_58, c_50, lemma_10, s6])).
fof(goal_1, theorem, a = c, inference(mp, [status(thm)], [lemma_8, s7])).
% SZS output end Proof
