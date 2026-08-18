% CNF version of thesis_example_both_lemmas.p
% f(x)=x, g(x)=f(x), g(x)=x=>q(x), s(a), s(x)/\q(x)=>p(x) |- p(a)
cnf(ax1, axiom, f(X) = X).
cnf(ax2, axiom, g(X) = f(X)).
cnf(ax3, axiom, q(X) | g(X) != X).
cnf(ax4, axiom, s(a)).
cnf(ax5, axiom, p(X) | ~s(X) | ~q(X)).
cnf(goal, negated_conjecture, ~p(a)).
