% SZS output start Proof
fof(f1, axiom, p(a), file('resolution_example_eq_positive_rewrite.p', ax1)).
fof(f2, axiom, a = b, file('resolution_example_eq_positive_rewrite.p', ax2)).
fof(f3, axiom, p(b) => q(b), file('resolution_example_eq_positive_rewrite.p', ax3)).
fof(s1, plain, p(b), inference(rewrite, [status(thm)], [f2, f1])).
fof(f4, theorem, q(b), inference(mp, [status(thm)], [f3, s1])).
% SZS output end Proof
