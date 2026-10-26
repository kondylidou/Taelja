% SZS output start Proof
fof(f1, axiom, ! [X0]: p(X0), file('resolution_example_horn_reuse_n1.p', ax1)).
fof(f2, axiom, ! [X0]: q(b, X0), file('resolution_example_horn_reuse_n1.p', ax2)).
fof(f3, axiom, ! [X1, X2]: ((p(X2) & q(X1, X2)) => q(f(X1), X2)), file('resolution_example_horn_reuse_n1.p', ax3)).
fof(f4, axiom, ! [X2]: (q(f(b), X2) => r(X2)), file('resolution_example_horn_reuse_n1.p', ax4)).
fof(s1, plain, p(a), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, q(b,a), inference(instantiate, [status(thm)], [f2])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [f3, s1, s2])).
fof(f5, theorem, r(a), inference(mp, [status(thm)], [f4, s3])).
% SZS output end Proof
