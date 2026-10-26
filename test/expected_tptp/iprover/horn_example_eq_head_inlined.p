% SZS output start Proof
fof(f1, axiom, ! [X0]: ((q(X0) & p(X0)) => zero = X0), file('horn_example_eq_head_inlined.p', ax1)).
fof(f2, axiom, ! [X0]: p(f(X0)), file('horn_example_eq_head_inlined.p', ax2)).
fof(f3, axiom, ! [X0]: q(f(X0)), file('horn_example_eq_head_inlined.p', ax3)).
fof(f4, axiom, ! [X0]: f(X0) = g(X0), file('horn_example_eq_head_inlined.p', ax4)).
fof(s1, plain, q(f(a)), inference(instantiate, [status(thm)], [f3])).
fof(s2, plain, p(f(a)), inference(instantiate, [status(thm)], [f2])).
fof(s3, plain, zero = f(a), inference(mp, [status(thm)], [f1, s1, s2])).
fof(f5, theorem, zero = g(a), inference(rewrite, [status(thm)], [f4, s3])).
% SZS output end Proof
