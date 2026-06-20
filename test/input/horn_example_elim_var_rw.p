% Horn-style elimination + equality chaining test.
%
% q(a, X0)
% q(X0, X1) => f(X0) = g(X1)
% g(X0) = c
% Therefore: f(a) = c

fof(f1,axiom,
    ! [X0] : q(a, X0)).

fof(f2,axiom,
    ! [X0,X1] :
        (q(X0,X1) => f(X0) = g(X1))).

fof(f3,axiom,
    ! [X0] :
        g(X0) = c).

fof(f4,conjecture,
    f(a) = c).