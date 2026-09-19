% SZS output start Proof
fof(skolem_definition, definition, ? [A]: ~ ((relation(A) & function(A)) => (finite(relation_dom(A)) => finite(relation_rng(A)))) => ~ ((relation(a) & function(a)) => (finite(relation_dom(a)) => finite(relation_rng(a)))), introduced(definition, [new_symbols(definition, [a])], [])).
fof(c10, axiom, ! [A2]: (relation(A2) => relation_image(A2, relation_dom(A2)) = relation_rng(A2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SEU/SEU303+1.p', t146_relat_1)).
fof(c23, axiom, ! [B, A2]: ((relation(A2) & function(A2) & finite(B)) => finite(relation_image(A2, B))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SEU/SEU303+1.p', fc13_finset_1)).
fof(c9, assumption, relation(a), introduced(assumption, [], [])).
fof(c18, assumption, function(a), introduced(assumption, [], [])).
fof(c22, assumption, finite(relation_dom(a)), introduced(assumption, [], [])).
fof(lemma_6, lemma, relation_image(a,relation_dom(a)) = relation_rng(a), inference(mp, [status(thm), assumptions([c9])], [c10, c9])).
fof(s1, plain, finite(relation_image(a,relation_dom(a))), inference(mp, [status(thm), assumptions([c9, c18, c22])], [c23, c9, c18, c22])).
fof(s2, plain, finite(relation_rng(a)), inference(rewrite, [status(thm), assumptions([c9, c18, c22])], [lemma_6, s1])).
fof(discharged, plain, ((relation(a) & function(a) & finite(relation_dom(a))) => finite(relation_rng(a))), inference(implies, [status(thm), discharge(implies, [c9, c18, c22])], [s2, c9, c18, c22])).
fof(c1, theorem, ! [A]: ((relation(A) & function(A)) => (finite(relation_dom(A)) => finite(relation_rng(A)))), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
