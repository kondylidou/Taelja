% Uwe Waldmann's example of a shared non-unit clause. The derived clause
% q(x,z) -> q(f(x),y) is used three times in the refutation.
cnf(ax1, axiom, ~p(X) | q(X,Y)).
cnf(ax2, axiom, ~q(X,Z) | p(f(X))).
cnf(ax3, axiom, q(a,a)).
cnf(goal, negated_conjecture, ~q(f(f(f(a))),f(f(f(a))))).
