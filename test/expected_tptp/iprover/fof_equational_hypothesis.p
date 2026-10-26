% SZS output start Proof
fof(f1, axiom, g(a) = b, file('fof_equational_hypothesis.p', ax1)).
fof(f2, axiom, ! [X0]: h(X0) = X0, file('fof_equational_hypothesis.p', ax2)).
fof(f6, plain, ? [X0]: (b != g(h(f(X0))) & a = f(X0)) => (b != g(h(f(sK0))) & a = f(sK0)), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(c_52, assumption, f(sK0) = a, introduced(assumption, [], [])).
fof(s1, plain, b = g(a), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, b = g(h(a)), inference(rewrite, [status(thm)], [f2, s1])).
fof(s3, plain, b = g(h(f(sK0))), inference(rewrite, [status(thm), assumptions([c_52])], [c_52, s2])).
fof(discharged, plain, (f(sK0) = a => b = g(h(f(sK0)))), inference(implies, [status(thm), discharge(implies, [c_52])], [s3, c_52])).
fof(f3, theorem, ! [X0]: (a = f(X0) => b = g(h(f(X0)))), inference(generalization, [status(thm)], [discharged, f6])).
% SZS output end Proof
