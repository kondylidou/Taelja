% Example demonstrating both a heuristic lemma (equality chain) and a forced lemma (second body literal).
% f(x)=x, g(x)=f(x), g(x)=x=>q(x), s(a), s(x)/\q(x)=>p(x) |- p(a)
fof(ax1, axiom, ! [X] : f(X) = X).
fof(ax2, axiom, ! [X] : g(X) = f(X)).
fof(ax3, axiom, ! [X] : (g(X) = X => q(X))).
fof(ax4, axiom, s(a)).
fof(ax5, axiom, ! [X] : ((s(X) & q(X)) => p(X))).
fof(goal, conjecture, p(a)).
