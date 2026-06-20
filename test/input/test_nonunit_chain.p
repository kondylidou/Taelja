% Simple chaining test.
% p(a)
% p(a) => q(a)
% p(a) & q(a) => r(a)
% Therefore r(a).

fof(f1,axiom,
    p(a)).

fof(f2,axiom,
    (p(a) => q(a))).

fof(f3,axiom,
    ((p(a) & q(a)) => r(a))).

fof(f4,conjecture,
    r(a)).