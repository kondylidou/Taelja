% Exercise 12.2: f(X)=c⇒f(X)=b, f(f(Y))=Y ⊢ b=c
fof(ax1, axiom, ! [X] : (f(X) = c => f(X) = b)).
fof(ax2, axiom, ! [Y] : f(f(Y)) = Y).
fof(goal, conjecture, b = c).
