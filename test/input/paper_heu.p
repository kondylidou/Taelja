% Nonground-chain lemma used only once: f(X)=X, g(X)=f(X), g(a)=a⇒p(g(a)) ⊢ p(g(a))
fof(ax1, axiom, ! [X] : f(X) = X).
fof(ax2, axiom, ! [X] : g(X) = f(X)).
fof(ax3, axiom, (g(a) = a => p(g(a)))).
fof(goal, conjecture, p(g(a))).