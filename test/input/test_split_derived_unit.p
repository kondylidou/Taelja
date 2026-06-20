% Regression test for match body literal split.
%
% p(a)
% ⇒ q(a, X1) via axiom 2 (X1 remains free in derived unit)
% q(a, b) ⇒ r(a) via axiom 3
%
% Key property:
% unification must split variables correctly so that:
%   - cX0 (from goal side) goes to σClause
%   - cX1 (from unit side) goes to σUnit
% ensuring q(a,b), not q(a,X)

fof(f1,axiom,
    p(a)).

fof(f2,axiom,
    ! [X0,X1] : (p(X0) => q(X0,X1))).

fof(f3,axiom,
    ! [X0] : (q(X0,b) => r(X0))).

fof(f4,conjecture,
    r(a)).