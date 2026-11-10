% This problem is due to Koen Claessen (who might have got it from David Plaisted).
%
% The problem defines a predicate p on 8-bit binary numbers.
% The problem axioms are:
%   p(00000000)
%   ~p(11111111)
%   p(X) => p(X+1), expressed as a family of clauses depending on the
%     least significant bits of X
%
% There is an obvious refutation of length ~256 by just counting up from zero;
% this only generates unit clauses. But by resolving the p(X) => p(X+1) clauses
% with each other you can get a shorter proof (exercise for the reader). This
% shorter proof needs non-unit lemmas.
%
% counting_binary.long_proof.s contains the long "counting up" proof.
% counting_binary.short_proofs.s contains a shorter proof.

cnf(start, axiom, p(zero, zero, zero, zero, zero, zero, zero, zero)).
cnf(end, negated_conjecture, ~p(one, one, one, one, one, one, one, one)).

% p(X) => p(X+1)
cnf(counting1, axiom, ~p(X1, X2, X3, X4, X5, X6, X7, zero)        | p(X1, X2, X3, X4, X5, X6, X7, one)).
cnf(counting2, axiom, ~p(X1, X2, X3, X4, X5, X6, zero, one)       | p(X1, X2, X3, X4, X5, X6, one, zero)).
cnf(counting3, axiom, ~p(X1, X2, X3, X4, X5, zero, one, one)      | p(X1, X2, X3, X4, X5, one, zero, zero)).
cnf(counting4, axiom, ~p(X1, X2, X3, X4, zero, one, one, one)     | p(X1, X2, X3, X4, one, zero, zero, zero)).
cnf(counting5, axiom, ~p(X1, X2, X3, zero, one, one, one, one)    | p(X1, X2, X3, one, zero, zero, zero, zero)).
cnf(counting6, axiom, ~p(X1, X2, zero, one, one, one, one, one)   | p(X1, X2, one, zero, zero, zero, zero, zero)).
cnf(counting7, axiom, ~p(X1, zero, one, one, one, one, one, one)  | p(X1, one, zero, zero, zero, zero, zero, zero)).
cnf(counting8, axiom, ~p(zero, one, one, one, one, one, one, one) | p(one, zero, zero, zero, zero, zero, zero, zero)).
