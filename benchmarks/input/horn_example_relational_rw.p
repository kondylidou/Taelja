% Relational rewriting: p(a), a=b, p(b)⇒q(b) ⊢ q(b)
fof(ax1, axiom, p(a)).
fof(ax2, axiom, a = b).
fof(ax3, axiom, p(b) => q(b)).
fof(goal, conjecture, q(b)).
