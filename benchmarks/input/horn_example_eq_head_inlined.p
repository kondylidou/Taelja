% Equational head via Horn clause:
% p(X)∧q(X)⇒X=zero, p(f(X)), q(f(X)), f(X)=g(X) ⊢ g(a)=zero
fof(ax1, axiom, ! [X] : ((p(X) & q(X)) => X = zero)).
fof(ax2, axiom, ! [X] : p(f(X))).
fof(ax3, axiom, ! [X] : q(f(X))).
fof(ax4, axiom, ! [X] : f(X) = g(X)).
fof(goal, conjecture, g(a) = zero).
