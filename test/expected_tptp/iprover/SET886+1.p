% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: unordered_pair(X0, X1) = unordered_pair(X1, X0), file('Problems/SET/SET886+1.p', commutativity_k2_tarski)).
fof(f5, axiom, ! [X0, X1, X2]: (subset(unordered_pair(X0, X1), singleton(X2)) => X0 = X2), file('Problems/SET/SET886+1.p', t26_zfmisc_1)).
fof(f8, axiom, ! [X0]: unordered_pair(X0, X0) = singleton(X0), file('Problems/SET/SET886+1.p', t69_enumset1)).
fof(f16, plain, ? [X0, X1, X2]: (unordered_pair(X0, X1) != singleton(X2) & subset(unordered_pair(X0, X1), singleton(X2))) => (unordered_pair(sK2, sK3) != singleton(sK4) & subset(unordered_pair(sK2, sK3), singleton(sK4))), introduced(choice_axiom, [new_symbols(definition, [sK2,sK3,sK4])], [])).
fof(c_55, assumption, subset(unordered_pair(sK2,sK3),singleton(sK4)), introduced(assumption, [], [])).
fof(lemma_5, lemma, sK2 = sK4, inference(mp, [status(thm), assumptions([c_55])], [f5, c_55])).
fof(s1, plain, subset(unordered_pair(sK2,sK3),singleton(sK2)), inference(rewrite, [status(thm), assumptions([c_55])], [lemma_5, c_55])).
fof(s2, plain, subset(unordered_pair(sK3,sK2),singleton(sK2)), inference(rewrite, [status(thm), assumptions([c_55])], [f1, s1])).
fof(lemma_6, lemma, sK3 = sK2, inference(mp, [status(thm), assumptions([c_55])], [f5, s2])).
fof(s3, plain, unordered_pair(sK2,sK2) = singleton(sK2), inference(instantiate, [status(thm)], [f8])).
fof(s4, plain, unordered_pair(sK2,sK3) = singleton(sK2), inference(rewrite, [status(thm), assumptions([c_55])], [lemma_6, s3])).
fof(s5, plain, unordered_pair(sK2,sK3) = singleton(sK4), inference(rewrite, [status(thm), assumptions([c_55])], [lemma_5, s4])).
fof(discharged, plain, (subset(unordered_pair(sK2,sK3),singleton(sK4)) => unordered_pair(sK2,sK3) = singleton(sK4)), inference(implies, [status(thm), discharge(implies, [c_55])], [s5, c_55])).
fof(f6, theorem, ! [X0, X1, X2]: (subset(unordered_pair(X0, X1), singleton(X2)) => unordered_pair(X0, X1) = singleton(X2)), inference(generalization, [status(thm)], [discharged, f16])).
% SZS output end Proof
