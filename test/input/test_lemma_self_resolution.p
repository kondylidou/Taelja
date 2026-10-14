% Uwe Waldmann's example: clause 14 is used twice, once against itself, so
% it becomes a Horn clause lemma.
cnf(a1, axiom, ~p(X,Y) | ~r(X) | q(X,Y)).
cnf(a2, axiom, ~q(X,f(Z)) | ~t(Z) | s(X,f(Z))).
cnf(a3, axiom, ~r(X) | u(X)).
cnf(a4, axiom, ~s(X,Y) | ~u(X) | p(f(X),f(b))).
cnf(a5, axiom, r(a)).
cnf(a6, axiom, r(f(X))).
cnf(a7, axiom, t(a)).
cnf(a8, axiom, t(b)).
cnf(a9, axiom, p(a,f(a))).
cnf(a10, negated_conjecture, ~p(f(f(a)),f(b))).
