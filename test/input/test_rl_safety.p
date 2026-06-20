% Test: equation with LHS variable absent from RHS.
% f(X0) = c  (X0 only on LHS, so only left-to-right rewriting is meaningful)
% Goal: f(a) = c

fof(f1,axiom,
    ! [X0] : (f(X0) = c)).

fof(f2,conjecture,
    f(a) = c).