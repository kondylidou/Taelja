% tau coordination: Y is shared between the two body atoms and resolved
% away (absent from the head), so theta leaves it free and the first
% match must bind it consistently for the second.
fof(ax1, axiom, p(a,b)).
fof(ax2, axiom, q(b,c)).
fof(ax3, axiom, ! [X,Y,Z] : ((p(X,Y) & q(Y,Z)) => r(X,Z))).
fof(goal, conjecture, r(a,c)).
