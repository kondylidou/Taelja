% Derived rewrite rule:
% p(a), q(b), p(X)⇒f(X)=c, q(Y)⇒a=Y ⊢ f(b)=c
fof(ax1, axiom, p(a)).
fof(ax2, axiom, q(b)).
fof(ax3, axiom, ! [X] : (p(X) => f(X) = c)).
fof(ax4, axiom, ! [Y] : (q(Y) => a = Y)).
fof(goal, conjecture, f(b) = c).
