% DAG-shaped proof (shared intermediate):
% p(a), p(X)⇒q(X,Y), q(X,b)⇒r1(X), q(X,c)⇒r2(X), r1(X)∧r2(X)⇒r0(X) ⊢ r0(a)
fof(ax1, axiom, p(a)).
fof(ax2, axiom, ! [X, Y] : (p(X) => q(X, Y))).
fof(ax3, axiom, ! [X] : (q(X, b) => r1(X))).
fof(ax4, axiom, ! [X] : (q(X, c) => r2(X))).
fof(ax5, axiom, ! [X] : ((r1(X) & r2(X)) => r0(X))).
fof(goal, conjecture, r0(a)).
