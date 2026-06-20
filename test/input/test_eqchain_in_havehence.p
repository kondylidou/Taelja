% Equality chaining:
% f(X) = g(X)
% g(X) = h(X)
% therefore f(X) = h(X)
% and whenever f(X) = h(X), p(X)
% prove p(a)

fof(f1,axiom,
    ! [X] : (f(X) = g(X))).

fof(f2,axiom,
    ! [X] : (g(X) = h(X))).

fof(f3,axiom,
    ! [X] : ((f(X) = h(X)) => p(X))).

fof(f4,conjecture,
    p(a)).