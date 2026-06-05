% Units-only with relational head:
% p(f(X)), f(X)=X ⊢ p(a)
fof(ax1, axiom, ! [X] : p(f(X))).
fof(ax2, axiom, ! [X] : f(X) = X).
fof(goal, conjecture, p(a)).
