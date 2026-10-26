% SZS output start Proof
fof(f1, axiom, f(a) = b, file('horn_rel_two_step_chain.p', ax1)).
fof(f2, axiom, g(b) = c, file('horn_rel_two_step_chain.p', ax2)).
fof(f3, axiom, p(c), file('horn_rel_two_step_chain.p', ax3)).
fof(s1, plain, p(g(b)), inference(rewrite, [status(thm)], [f2, f3])).
fof(f4, theorem, p(g(f(a))), inference(rewrite, [status(thm)], [f1, s1])).
% SZS output end Proof
