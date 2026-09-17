% SZS output start Proof
fof(f4, definition, ! [X0]: (? [X1]: (~ big_f(X1) & big_f(X0)) => (~ big_f(sK0(X0)) & big_f(X0))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f6, assumption, ! [X] : big_f(X), introduced(assumption, [], [])).
fof(s1, plain, ! [X] : big_f(sK0(X)), inference(instantiate, [status(thm), assumptions([f6])], [f6])).
fof(discharged, plain, (! [X] : big_f(X) => ! [X0_1] : big_f(sK0(X0_1))), inference(implies, [status(thm), discharge(implies, [f6])], [s1, f6])).
fof(f1, theorem, ? [X0]: ! [X1]: (big_f(X0) => big_f(X1)), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
