% Simple modus ponens test.
% p(a)
% p(a) => q(a)
% Therefore q(a).

fof(f1,axiom,
    p(a)).

fof(f2,axiom,
    (p(a) => q(a))).

fof(f3,conjecture,
    q(a)).