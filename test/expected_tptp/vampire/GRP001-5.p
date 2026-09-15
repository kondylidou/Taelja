% SZS output start Proof
fof(f6, axiom, product(a, b, c), file('Problems/GRP/GRP001-5.p', unknown)).
fof(f2, axiom, ! [X0]: product(X0, identity, X0), file('Problems/GRP/GRP001-5.p', unknown)).
fof(f5, axiom, ! [X0]: product(X0, X0, identity), file('Problems/GRP/GRP001-5.p', unknown)).
fof(f4, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ product(X1, X3, X4) | ~ product(X0, X1, X2) | ~ product(X0, X4, X5) | product(X2, X3, X5)), file('Problems/GRP/GRP001-5.p', unknown)).
fof(f1, axiom, ! [X0]: product(identity, X0, X0), file('Problems/GRP/GRP001-5.p', unknown)).
fof(f3, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ product(X2, X3, X5) | ~ product(X1, X3, X4) | ~ product(X0, X1, X2) | product(X0, X4, X5)), file('Problems/GRP/GRP001-5.p', unknown)).
fof(s1, plain, product(b,b,identity), inference(instantiate, [status(thm)], [f5])).
fof(s2, plain, product(a,identity,a), inference(instantiate, [status(thm)], [f2])).
fof(lemma_7, lemma, product(c,b,a), inference(mp, [status(thm)], [f4, s1, f6, s2])).
fof(s3, plain, product(identity,b,b), inference(instantiate, [status(thm)], [f1])).
fof(s4, plain, product(c,c,identity), inference(instantiate, [status(thm)], [f5])).
fof(lemma_8, lemma, product(c,a,b), inference(mp, [status(thm)], [f3, s3, lemma_7, s4])).
fof(s5, plain, product(a,a,identity), inference(instantiate, [status(thm)], [f5])).
fof(s6, plain, product(c,identity,c), inference(instantiate, [status(thm)], [f2])).
fof(goal_1, theorem, product(b,a,c), inference(mp, [status(thm)], [f4, s5, lemma_8, s6])).
% SZS output end Proof
