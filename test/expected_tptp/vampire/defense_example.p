% SZS output start Proof
fof(f1, axiom, cat(james), file('test/input/defense_example.p')).
fof(f2, axiom, catches(james, mouse), file('test/input/defense_example.p')).
fof(f3, axiom, ! [X0]: (catches(james, X0) => brings(james, X0)), file('test/input/defense_example.p')).
fof(f4, axiom, ! [X0]: ((brings(X0, mouse) & cat(X0)) => happy(X0)), file('test/input/defense_example.p')).
fof(s1, plain, brings(james,mouse), inference(mp, [status(thm)], [f3, f2])).
fof(f5, theorem, happy(james), inference(mp, [status(thm)], [f4, s1, f1])).
% SZS output end Proof
