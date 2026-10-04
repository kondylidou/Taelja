%--------------------------------------------------------------------------
% File     : GRP410-1 : TPTP v9.2.1. Released v2.6.0.
% Domain   : Group Theory
% Problem  : Axiom for group theory, in product & inverse, part 2
% Version  : [McC93] (equality) axioms.
% English  :

% Refs     : [Kun92] Kunen (1992), Single Axioms for Groups
%          : [McC93] McCune (1993), Single Axioms for Groups and Abelian Gr
% Source   : [TPTP]
% Names    :

% Status   : Unsatisfiable
% Rating   : 0.09 v9.1.0, 0.14 v9.0.0, 0.18 v8.2.0, 0.25 v8.1.0, 0.35 v7.5.0, 0.33 v7.4.0, 0.43 v7.3.0, 0.42 v7.1.0, 0.33 v7.0.0, 0.32 v6.4.0, 0.37 v6.3.0, 0.41 v6.2.0, 0.29 v6.1.0, 0.38 v6.0.0, 0.52 v5.5.0, 0.47 v5.4.0, 0.33 v5.3.0, 0.25 v5.2.0, 0.29 v5.1.0, 0.27 v5.0.0, 0.21 v4.1.0, 0.09 v4.0.1, 0.07 v4.0.0, 0.08 v3.7.0, 0.22 v3.4.0, 0.25 v3.3.0, 0.21 v3.1.0, 0.22 v2.7.0, 0.18 v2.6.0
% Syntax   : Number of clauses     :    2 (   2 unt;   0 nHn;   1 RR)
%            Number of literals    :    2 (   2 equ;   1 neg)
%            Maximal clause size   :    1 (   1 avg)
%            Maximal term depth    :    7 (   2 avg)
%            Number of predicates  :    1 (   0 usr;   0 prp; 2-2 aty)
%            Number of functors    :    4 (   4 usr;   2 con; 0-2 aty)
%            Number of variables   :    3 (   0 sgn)
% SPC      : CNF_UNS_RFO_PEQ_UEQ

% Comments : A UEQ part of GRP051-1
%--------------------------------------------------------------------------
cnf(single_axiom,axiom,
    multiply(multiply(inverse(multiply(A,inverse(multiply(B,C)))),multiply(A,inverse(C))),inverse(multiply(inverse(C),C))) = B ).

cnf(prove_these_axioms_2,negated_conjecture,
    multiply(multiply(inverse(b2),b2),a2) != a2 ).

%--------------------------------------------------------------------------
