% Reused clause extended with one more step:
% p(Z), q(b,Z), q(X,Y)∧p(Y)⇒q(f(X),Y), q(f(b),Y)⇒r(Y) ⊢ r(a)
fof(ax1, axiom, ! [Z] : p(Z)).
fof(ax2, axiom, ! [Z] : q(b, Z)).
fof(ax3, axiom, ! [X, Y] : ((q(X, Y) & p(Y)) => q(f(X), Y))).
fof(ax4, axiom, ! [Y] : (q(f(b), Y) => r(Y))).
fof(goal, conjecture, r(a)).
