% SZS output start Proof
fof(f6, axiom, ! [X0]: (relation(X0) => relation_image(X0, relation_dom(X0)) = relation_rng(X0)), file('Problems/SEU/SEU303+1.p')).
fof(f7, axiom, ! [X0, X1]: ((relation(X1) & function(X1)) => (finite(X0) => finite(relation_image(X1, X0)))), file('Problems/SEU/SEU303+1.p')).
fof(f19, definition, ? [X0]: (~ finite(relation_rng(X0)) & finite(relation_dom(X0)) & relation(X0) & function(X0)) => (~ finite(relation_rng(sK1)) & finite(relation_dom(sK1)) & relation(sK1) & function(sK1)), introduced(definition, [new_symbols(definition, [sK1])], [])).
fof(f26, assumption, function(sK1), introduced(assumption, [], [])).
fof(f27, assumption, relation(sK1), introduced(assumption, [], [])).
fof(f28, assumption, finite(relation_dom(sK1)), introduced(assumption, [], [])).
fof(lemma_6, lemma, relation_image(sK1,relation_dom(sK1)) = relation_rng(sK1), inference(mp, [status(thm), assumptions([f27])], [f6, f27])).
fof(s1, plain, finite(relation_image(sK1,relation_dom(sK1))), inference(mp, [status(thm), assumptions([f27, f26, f28])], [f7, f27, f26, f28])).
fof(s2, plain, finite(relation_rng(sK1)), inference(rewrite, [status(thm), assumptions([f27, f26, f28])], [lemma_6, s1])).
fof(f8, theorem, ! [X0]: ((relation(X0) & function(X0)) => (finite(relation_dom(X0)) => finite(relation_rng(X0)))), inference(implies, [status(thm), discharge(implies, [f26, f27, f28])], [s2, f26, f27, f28])).
% SZS output end Proof
