% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: unordered_pair(X0, X1) = unordered_pair(X1, X0), file('Problems/SET/SET886+1.p')).
fof(f5, axiom, ! [X0, X1, X2]: (subset(unordered_pair(X0, X1), singleton(X2)) => X0 = X2), file('Problems/SET/SET886+1.p')).
fof(f8, axiom, ! [X0]: unordered_pair(X0, X0) = singleton(X0), file('Problems/SET/SET886+1.p')).
fof(f16, definition, ? [X0, X1, X2]: (unordered_pair(X0, X1) != singleton(X2) & subset(unordered_pair(X0, X1), singleton(X2))) => (unordered_pair(sK2, sK3) != singleton(sK4) & subset(unordered_pair(sK2, sK3), singleton(sK4))), introduced(definition, [new_symbols(definition, [sK2,sK3,sK4])], [])).
fof(f23, assumption, subset(unordered_pair(sK2,sK3),singleton(sK4)), introduced(assumption, [], [])).
fof(lemma_5, lemma, subset(unordered_pair(sK2,sK3),unordered_pair(sK4,sK4)), inference(rewrite, [status(thm), assumptions([f23])], [f8, f23])).
fof(s1, plain, subset(unordered_pair(sK2,sK3),singleton(sK4)), inference(rewrite, [status(thm), assumptions([f23])], [f8, lemma_5])).
fof(lemma_6, lemma, sK2 = sK4, inference(mp, [status(thm), assumptions([f23])], [f5, s1])).
fof(s2, plain, subset(unordered_pair(sK4,sK3),unordered_pair(sK4,sK4)), inference(rewrite, [status(thm), assumptions([f23])], [lemma_6, lemma_5])).
fof(s3, plain, subset(unordered_pair(sK3,sK4),unordered_pair(sK4,sK4)), inference(rewrite, [status(thm), assumptions([f23])], [f1, s2])).
fof(s4, plain, subset(unordered_pair(sK3,sK4),singleton(sK4)), inference(rewrite, [status(thm), assumptions([f23])], [f8, s3])).
fof(lemma_7, lemma, sK3 = sK4, inference(mp, [status(thm), assumptions([f23])], [f5, s4])).
fof(s5, plain, unordered_pair(sK2,sK3) = unordered_pair(sK2,sK4), inference(instantiate, [status(thm), assumptions([f23])], [lemma_7])).
fof(s6, plain, unordered_pair(sK2,sK3) = unordered_pair(sK4,sK2), inference(rewrite, [status(thm), assumptions([f23])], [f1, s5])).
fof(s7, plain, unordered_pair(sK2,sK3) = unordered_pair(sK4,sK4), inference(rewrite, [status(thm), assumptions([f23])], [lemma_6, s6])).
fof(s8, plain, unordered_pair(sK2,sK3) = singleton(sK4), inference(rewrite, [status(thm), assumptions([f23])], [f8, s7])).
fof(discharged, plain, (subset(unordered_pair(sK2,sK3),singleton(sK4)) => unordered_pair(sK2,sK3) = singleton(sK4)), inference(implies, [status(thm), discharge(implies, [f23])], [s8, f23])).
fof(f6, theorem, ! [X0, X1, X2]: (subset(unordered_pair(X0, X1), singleton(X2)) => unordered_pair(X0, X1) = singleton(X2)), inference(generalization, [status(thm)], [discharged, f16])).
% SZS output end Proof
