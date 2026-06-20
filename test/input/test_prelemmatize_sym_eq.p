% Regression test for prelemmatize symmetric equation lookup.
%
% h(a) = k(a)
% ⇒ p(a) using axiom 2
% k(a) = h(a) (symmetric form) ⇒ q(a) using axiom 3
% p(a) & q(a) ⇒ r(a)

fof(f1,axiom,
    h(a) = k(a)).

fof(f2,axiom,
    ! [X0] : ((h(X0) = k(X0)) => p(X0))).

fof(f3,axiom,
    ! [X0] : ((k(X0) = h(X0)) => q(X0))).

fof(f4,axiom,
    ! [X0] : ((p(X0) & q(X0)) => r(X0))).

fof(f5,conjecture,
    r(a)).