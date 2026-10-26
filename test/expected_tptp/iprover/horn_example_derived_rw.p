% SZS output start Proof
fof(f1, axiom, p(a), file('horn_example_derived_rw.p', ax1)).
fof(f2, axiom, q(b), file('horn_example_derived_rw.p', ax2)).
fof(f3, axiom, ! [X0]: (p(X0) => f(X0) = c), file('horn_example_derived_rw.p', ax3)).
fof(f4, axiom, ! [X1]: (q(X1) => a = X1), file('horn_example_derived_rw.p', ax4)).
fof(lemma_5, lemma, f(a) = c, inference(mp, [status(thm)], [f3, f1])).
fof(lemma_6, lemma, a = b, inference(mp, [status(thm)], [f4, f2])).
fof(s1, plain, c = f(a), inference(instantiate, [status(thm)], [lemma_5])).
fof(f5, theorem, c = f(b), inference(rewrite, [status(thm)], [lemma_6, s1])).
% SZS output end Proof
