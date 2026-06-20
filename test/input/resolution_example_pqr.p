% Simple resolution chain: p(a), p(X)⇒q(X), q(X)⇒r(X) ⊢ r(a)
fof(ax1, axiom, p(a)).
fof(ax2, axiom, ! [X] : (p(X) => q(X))).
fof(ax3, axiom, ! [X] : (q(X) => r(X))).
fof(goal, conjecture, r(a)).
