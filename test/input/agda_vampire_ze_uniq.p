% The example of Sinkarovs and Rawson, When Agda met Vampire, Section 3.1:
% a vector space with zero, addition and negation, and the uniqueness of zero.
fof(neutl, axiom, ! [U] : plus(ze, U) = U).
fof(negl, axiom, ! [U] : plus(neg(U), U) = ze).
fof(assoc, axiom, ! [U, V, W] : plus(plus(U, V), W) = plus(U, plus(V, W))).
fof(ze_uniq, conjecture, ! [U, V] : (plus(U, V) = V => U = ze)).
