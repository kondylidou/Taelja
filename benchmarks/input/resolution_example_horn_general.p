% General Horn with derived premises:
% s(a), s(X)⇒p(X), t(b), t(Y)⇒q(Y), p(X)∧q(Y)⇒r(X,Y) ⊢ r(a,b)
fof(ax1, axiom, s(a)).
fof(ax2, axiom, ! [X] : (s(X) => p(X))).
fof(ax3, axiom, t(b)).
fof(ax4, axiom, ! [Y] : (t(Y) => q(Y))).
fof(ax5, axiom, ! [X, Y] : ((p(X) & q(Y)) => r(X, Y))).
fof(goal, conjecture, r(a, b)).
