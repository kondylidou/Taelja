% Reused clause (lemma reuse):
% p(Z), q(b,Z), q(X,Y)∧p(Y)⇒q(f(X),Y) ⊢ q(f(f(b)),a)
fof(ax1, axiom, ! [Z] : p(Z)).
fof(ax2, axiom, ! [Z] : q(b, Z)).
fof(ax3, axiom, ! [X, Y] : ((q(X, Y) & p(Y)) => q(f(X), Y))).
fof(goal, conjecture, q(f(f(b)), a)).
