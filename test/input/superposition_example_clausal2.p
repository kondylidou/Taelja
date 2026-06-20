% Clausal superposition using injectivity:
% f(X)=f(Y)⇒X=Y, g(X)=g(Y)⇒X=Y, g(f(a))=g(f(b)) ⊢ a=b
fof(ax1, axiom, ! [X, Y] : (f(X) = f(Y) => X = Y)).
fof(ax2, axiom, ! [X, Y] : (g(X) = g(Y) => X = Y)).
fof(ax3, axiom, g(f(a)) = g(f(b))).
fof(goal, conjecture, a = b).
