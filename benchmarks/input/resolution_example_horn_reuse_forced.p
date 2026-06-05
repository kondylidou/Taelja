% Forced lemmatization: second premise cannot be inlined
% s(Z), s(X)=>q(b,X), s(X)=>p(X), q(X,Y)/\p(Y)=>r(X,Y) ⊢ r(b,a)
fof(ax1, axiom, ! [Z] : s(Z)).
fof(ax2, axiom, ! [X] : (s(X) => q(b, X))).
fof(ax3, axiom, ! [X] : (s(X) => p(X))).
fof(ax4, axiom, ! [X, Y] : ((q(X, Y) & p(Y)) => r(X, Y))).
fof(goal, conjecture, r(b, a)).
