% SZS output start Proof
fof(f1, axiom, ! [X0]: product(identity, X0, X0), file('Problems/GRP/GRP001-5.p')).
fof(f2, axiom, ! [X0]: product(X0, identity, X0), file('Problems/GRP/GRP001-5.p')).
fof(f3, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ product(X2, X3, X5) | ~ product(X1, X3, X4) | ~ product(X0, X1, X2) | product(X0, X4, X5)), file('Problems/GRP/GRP001-5.p')).
fof(f4, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ product(X1, X3, X4) | ~ product(X0, X1, X2) | ~ product(X0, X4, X5) | product(X2, X3, X5)), file('Problems/GRP/GRP001-5.p')).
fof(f5, axiom, ! [X0]: product(X0, X0, identity), file('Problems/GRP/GRP001-5.p')).
fof(f6, axiom, product(a, b, c), file('Problems/GRP/GRP001-5.p')).
fof(s1, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_7, lemma, ! [X,Y,Z] : (product(X,Y,Z) => product(Z,Y,X)), inference(mp, [status(thm)], [f4, f5, s1, f2])).
fof(lemma_8, lemma, product(c,b,a), inference(mp, [status(thm)], [lemma_7, f6])).
fof(s2, plain, product(identity,b,b), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, product(c,c,identity), inference(instantiate, [status(thm)], [f5])).
fof(s4, plain, product(c,a,b), inference(mp, [status(thm)], [f3, s2, lemma_8, s3])).
fof(goal_1, theorem, product(b,a,c), inference(mp, [status(thm)], [lemma_7, s4])).
% SZS output end Proof
