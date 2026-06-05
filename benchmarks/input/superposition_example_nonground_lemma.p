% Nonground lemma: f(X)=X, g(X)=f(X), g(X)=X⇒p(g(X)) ⊢ p(g(a))
fof(ax1, axiom, ! [X] : f(X) = X).
fof(ax2, axiom, ! [X] : g(X) = f(X)).
fof(ax3, axiom, ! [X] : (g(X) = X => p(g(X)))).
fof(goal, conjecture, p(g(a))).
