%--------------------------------------------------------------------------
% File     : GRP195-1 : TPTP v9.2.1. Released v2.2.0.
% Domain   : Group Theory (Semigroups)
% Problem  : In semigroups, xyy=yyx -> (uv)^4 = u^4v^4.
% Version  : [MP96] (equality) axioms.
% English  : In semigroups, xyy=yyx -> uvuvuvuuv=uuuuvvvv.

% Refs     : [McC98] McCune (1998), Email to G. Sutcliffe
%          : [MP96]  McCune & Padmanabhan (1996), Automated Deduction in Eq
% Source   : [McC98]
% Names    : CS-2 [MP96]

% Status   : Unsatisfiable
% Rating   : 0.04 v9.1.0, 0.09 v9.0.0, 0.05 v8.2.0, 0.08 v8.1.0, 0.10 v7.5.0, 0.12 v7.4.0, 0.13 v7.3.0, 0.05 v7.1.0, 0.00 v7.0.0, 0.11 v6.4.0, 0.16 v6.3.0, 0.18 v6.2.0, 0.21 v6.1.0, 0.12 v6.0.0, 0.29 v5.5.0, 0.21 v5.4.0, 0.07 v5.3.0, 0.08 v5.2.0, 0.14 v5.1.0, 0.00 v5.0.0, 0.07 v4.1.0, 0.09 v4.0.1, 0.07 v4.0.0, 0.08 v3.7.0, 0.11 v3.4.0, 0.12 v3.3.0, 0.00 v2.7.0, 0.09 v2.6.0, 0.17 v2.5.0, 0.00 v2.4.0, 0.00 v2.2.1
% Syntax   : Number of clauses     :    3 (   3 unt;   0 nHn;   1 RR)
%            Number of literals    :    3 (   3 equ;   1 neg)
%            Maximal clause size   :    1 (   1 avg)
%            Maximal term depth    :    8 (   2 avg)
%            Number of predicates  :    1 (   0 usr;   0 prp; 2-2 aty)
%            Number of functors    :    3 (   3 usr;   2 con; 0-2 aty)
%            Number of variables   :    5 (   0 sgn)
% SPC      : CNF_UNS_RFO_PEQ_UEQ

% Comments : The problem was originally posed for cancellative semigroups,
%            but Otter discovered that cancellation is not necessary.
%--------------------------------------------------------------------------
%----Include semigroups axioms
include('Axioms/GRP008-0.ax').
%--------------------------------------------------------------------------
%----Hypothesis:
cnf(condition,hypothesis,
    multiply(X,multiply(Y,Y)) = multiply(Y,multiply(Y,X)) ).

%----Denial of conclusion:
cnf(prove_this,negated_conjecture,
    multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) != multiply(a,multiply(a,multiply(a,multiply(a,multiply(b,multiply(b,multiply(b,b))))))) ).

%--------------------------------------------------------------------------
