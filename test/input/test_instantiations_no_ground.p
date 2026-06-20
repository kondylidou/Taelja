% Regression test for the instantiations fallthrough.
%
% top
% ⇒ q(X0,X1) for all X0,X1
%
% From q(X,b) derive r1(X)
% From q(X,X) derive r2(X)
%
% For X=a:
%   q(a,b) ⇒ r1(a)
%   q(a,a) ⇒ r2(a)
%
% Therefore s(a).

fof(f1,axiom,
    top).

fof(f2,axiom,
    ! [X0,X1] : (top => q(X0,X1))).

fof(f3,axiom,
    ! [X0] : (q(X0,b) => r1(X0))).

fof(f4,axiom,
    ! [X0] : (q(X0,X0) => r2(X0))).

fof(f5,axiom,
    ! [X0] : ((r1(X0) & r2(X0)) => s(X0))).

fof(f6,conjecture,
    s(a)).