% SZS output start Proof
fof(f1, axiom, a = b, file('horn_example_eq_rw_chain.p', ax1)).
fof(f2, axiom, f(b) = c, file('horn_example_eq_rw_chain.p', ax2)).
fof(f3, axiom, ! [X0]: (c = f(X0) => c = g(X0)), file('horn_example_eq_rw_chain.p', ax3)).
fof(f4, axiom, c = g(a) => c = h(a), file('horn_example_eq_rw_chain.p', ax4)).
fof(s1, plain, c = f(b), inference(instantiate, [status(thm)], [f2])).
fof(lemma_5, lemma, c = f(a), inference(rewrite, [status(thm)], [f1, s1])).
fof(s2, plain, c = g(a), inference(mp, [status(thm)], [f3, lemma_5])).
fof(f5, theorem, c = h(a), inference(mp, [status(thm)], [f4, s2])).
% SZS output end Proof
