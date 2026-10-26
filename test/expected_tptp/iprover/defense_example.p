% SZS output start Proof
fof(f1, axiom, brings_home(james) = catch(james), file('defense_example.p', brings_home_catch)).
fof(f2, axiom, catch(james) = mouse, file('defense_example.p', catches_mouse)).
fof(f3, axiom, cat(james), file('defense_example.p', james_is_cat)).
fof(f4, axiom, ! [X0]: ((cat(X0) & mouse = brings_home(X0)) => happy(X0)), file('defense_example.p', happy)).
fof(s1, plain, mouse = catch(james), inference(instantiate, [status(thm)], [f2])).
fof(lemma_5, lemma, mouse = brings_home(james), inference(rewrite, [status(thm)], [f1, s1])).
fof(f5, theorem, happy(james), inference(mp, [status(thm)], [f4, f3, lemma_5])).
% SZS output end Proof
