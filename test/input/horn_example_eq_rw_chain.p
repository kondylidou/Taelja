% Equational rewriting chain:
% a=b, f(b)=c, f(X)=c⇒g(X)=c, g(a)=c⇒h(a)=c ⊢ h(a)=c
fof(ax1, axiom, a = b).
fof(ax2, axiom, f(b) = c).
fof(ax3, axiom, ! [X] : (f(X) = c => g(X) = c)).
fof(ax4, axiom, g(a) = c => h(a) = c).
fof(goal, conjecture, h(a) = c).
