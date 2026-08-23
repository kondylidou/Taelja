% Two-step relational chain: p(c), g(b)=c, f(a)=b ⊢ p(g(f(a)))
% matchViaRw fails (needs two equation steps); Twee finds the chain.
fof(ax1, axiom, f(a) = b).
fof(ax2, axiom, g(b) = c).
fof(ax3, axiom, p(c)).
fof(goal, conjecture, p(g(f(a)))).
