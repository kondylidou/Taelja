% SZS output start Proof
fof(f1, axiom, ? [X0]: (r(X0) & p(X0)), file('fof_skolem_definition.p', ax1)).
fof(f2, axiom, ! [X0]: ((r(X0) & p(X0)) => q(X0)), file('fof_skolem_definition.p', ax2)).
fof(f8, plain, ? [X0]: (r(X0) & p(X0)) => (r(sK0) & p(sK0)), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(axiom_1, plain, p(sK0), inference(clausify, [status(thm)], [f1, f8])).
fof(axiom_2, plain, r(sK0), inference(clausify, [status(thm)], [f1, f8])).
fof(s1, plain, q(sK0), inference(mp, [status(thm)], [f2, axiom_2, axiom_1])).
fof(f3, theorem, ? [X0]: q(X0), inference(conclude, [status(thm)], [s1])).
% SZS output end Proof
