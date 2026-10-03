% Regression test for a body atom that becomes t = t.
%
% Under theta axiom 3's body atom X = Y is a = a.  It needs no electron, only
% reflexivity, and the atoms after it must still be paired with their own
% premises, r(a) with axiom 2.
cnf(a1, axiom, p(a)).
cnf(a2, axiom, r(a)).
cnf(a3, axiom, ~p(X) | X != Y | ~r(Y) | q(X)).
cnf(goal, negated_conjecture, ~q(a)).
