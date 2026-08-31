% tau in a mixed proof (paper Example 3): the nucleus variable X occurs only
% in the body and is resolved away, so theta leaves it free; matching the
% first body atom q(X) against q(a) forces tau = {X -> a}, under which the
% second body atom becomes g(a) = a, proved by a rewriting-chain lemma.
fof(ax1, axiom, q(a)).
fof(ax2, axiom, ! [X] : f(X) = X).
fof(ax3, axiom, ! [X] : g(X) = f(X)).
fof(ax4, axiom, ! [X] : ((q(X) & g(X) = X) => p(g(a)))).
fof(goal, conjecture, p(g(a))).
