% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (r(X0, X1) => s(X0)), file('skolem_hyp.p')).
fof(f2, axiom, ! [X0]: (s(X0) => t(X0)), file('skolem_hyp.p')).
fof(f8, definition, ? [X0]: (~ t(X0) & ? [X1]: r(X0, X1)) => (~ t(sK0) & ? [X1]: r(sK0, X1)), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f9, definition, ? [X1]: r(sK0, X1) => r(sK0, sK1), introduced(definition, [new_symbols(definition, [sK1])], [])).
fof(f13, assumption, r(sK0,sK1), introduced(assumption, [], [])).
fof(s1, plain, r(sK0,sK1), inference(instantiate, [status(thm), assumptions([f13])], [f13])).
fof(s2, plain, s(sK0), inference(mp, [status(thm), assumptions([f13])], [f1, s1])).
fof(s3, plain, t(sK0), inference(mp, [status(thm), assumptions([f13])], [f2, s2])).
fof(discharged, plain, (r(sK0,sK1) => t(sK0)), inference(implies, [status(thm), discharge(implies, [f13])], [s3, f13])).
fof(f3, theorem, ! [X0]: (? [X1]: r(X0, X1) => t(X0)), inference(generalization, [status(thm)], [discharged, f8, f9])).
% SZS output end Proof
