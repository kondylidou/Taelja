% SZS output start Proof
fof(f2, axiom, ! [X0]: sum(X0, additive_identity, X0), file('Problems/RNG/RNG038-1.p')).
fof(f6, axiom, ! [X0]: sum(X0, additive_inverse(X0), additive_identity), file('Problems/RNG/RNG038-1.p')).
fof(f8, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ sum(X1, X3, X4) | ~ sum(X0, X1, X2) | ~ sum(X0, X4, X5) | sum(X2, X3, X5)), file('Problems/RNG/RNG038-1.p')).
fof(f14, axiom, ! [X2, X3, X0, X1, X6, X4, X5]: (~ product(X5, X1, X6) | ~ product(X3, X1, X4) | ~ sum(X0, X3, X5) | ~ product(X0, X1, X2) | sum(X2, X4, X6)), file('Problems/RNG/RNG038-1.p')).
fof(f16, axiom, ! [X2, X3, X0, X1]: (~ sum(X0, X1, X3) | ~ sum(X0, X1, X2) | X2 = X3), file('Problems/RNG/RNG038-1.p')).
fof(f18, axiom, ! [X0, X1]: (X0 != additive_identity | product(X0, h(X0, X1), X1)), file('Problems/RNG/RNG038-1.p')).
fof(s1, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [f18])).
fof(s2, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [f18])).
fof(s3, plain, sum(additive_identity,additive_identity,additive_identity), inference(instantiate, [status(thm)], [f2])).
fof(s4, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [f18])).
fof(lemma_7, lemma, sum(b,b,b), inference(mp, [status(thm)], [f14, s1, s2, s3, s4])).
fof(s5, plain, sum(b,additive_inverse(b),additive_identity), inference(instantiate, [status(thm)], [f6])).
fof(s6, plain, sum(b,additive_identity,b), inference(instantiate, [status(thm)], [f2])).
fof(lemma_8, lemma, sum(b,additive_inverse(b),b), inference(mp, [status(thm)], [f8, s5, lemma_7, s6])).
fof(s7, plain, sum(b,additive_inverse(b),additive_identity), inference(instantiate, [status(thm)], [f6])).
fof(goal_1, theorem, b = additive_identity, inference(mp, [status(thm)], [f16, s7, lemma_8])).
% SZS output end Proof
