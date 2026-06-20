% Equality propagation through function symbols.
% From p(a) derive f(a)=g(a).
% From q(a) derive g(a)=h(a).
% By transitivity, f(a)=h(a).
% By congruence of s, s(f(a))=s(h(a)).

fof(f1,axiom,
    p(a)).

fof(f2,axiom,
    q(a)).

fof(f3,axiom,
    ! [X] : (p(X) => f(X) = g(X))).

fof(f4,axiom,
    ! [X] : (q(X) => g(X) = h(X))).

fof(f5,conjecture,
    s(f(a)) = s(h(a))).