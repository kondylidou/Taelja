% Nonparallel rewriting: a=b, f(X)=X ⊢ h(f(b),a)=h(a,f(b))
fof(ax1, axiom, a = b).
fof(ax2, axiom, ! [X] : f(X) = X).
fof(goal, conjecture, h(f(b), a) = h(a, f(b))).
