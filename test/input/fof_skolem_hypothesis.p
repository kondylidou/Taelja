fof(ax1, axiom, ! [X,Y] : (r(X,Y) => s(X))).
fof(ax2, axiom, ! [X] : (s(X) => t(X))).
fof(goal, conjecture, ! [X] : ((? [Y] : r(X,Y)) => t(X))).
