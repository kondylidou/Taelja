% SZS output start Proof
fof(f1, axiom, brings_home(james) = catch(james), file('test/input/defense_example.p')).
fof(f2, axiom, catch(james) = mouse, file('test/input/defense_example.p')).
fof(f3, axiom, cat(james), file('test/input/defense_example.p')).
fof(f4, axiom, ! [X0]: ((brings_home(X0) = mouse & cat(X0)) => happy(X0)), file('test/input/defense_example.p')).
fof(lemma_5, lemma, brings_home(james) = mouse, inference(rewrite, [status(thm)], [f2, f1])).
fof(f5, theorem, happy(james), inference(mp, [status(thm)], [f4, lemma_5, f3])).
% SZS output end Proof
