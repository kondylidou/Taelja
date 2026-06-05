% Clausal superposition with two equational goals:
% a=b, b=c, f(X)=X ⊢ c=a ∧ f(d)=d
fof(ax1, axiom, a = b).
fof(ax2, axiom, b = c).
fof(ax3, axiom, ! [X] : f(X) = X).
fof(goal, conjecture, c = a & f(d) = d).
