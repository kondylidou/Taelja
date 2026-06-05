% Horn clause with two unit premises:
% p(a), q(b), p(X)∧q(Y)⇒r(X,Y) ⊢ r(a,b)
fof(ax1, axiom, p(a)).
fof(ax2, axiom, q(b)).
fof(ax3, axiom, ! [X, Y] : ((p(X) & q(Y)) => r(X, Y))).
fof(goal, conjecture, r(a, b)).
