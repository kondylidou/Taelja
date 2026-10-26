% SZS output start Proof
fof(f1, axiom, ! [X0]: p(X0), file('resolution_example_horn_reuse_inlined.p', ax1)).
fof(f2, axiom, ! [X0]: q(b, X0), file('resolution_example_horn_reuse_inlined.p', ax2)).
fof(f3, axiom, ! [X1, X2]: ((p(X2) & q(X1, X2)) => q(f(X1), X2)), file('resolution_example_horn_reuse_inlined.p', ax3)).
fof(s1, plain, ! [X,Y] : (q(X,Y) => q(X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_4, lemma, ! [X,Y] : (q(X,Y) => q(f(X),Y)), inference(mp, [status(thm)], [f3, f1, s1])).
fof(s2, plain, q(b,a), inference(instantiate, [status(thm)], [f2])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [lemma_4, s2])).
fof(f4, theorem, q(f(f(b)), a), inference(mp, [status(thm)], [lemma_4, s3])).
% SZS output end Proof
