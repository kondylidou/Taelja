%--------------------------------------------------------------------------
% File     : HEN008-1 : TPTP v9.2.1. Released v1.0.0.
% Domain   : Henkin Models
% Problem  : X <= Y => X/Z <= Y/Z
% Version  : [MOW76] axioms.
% English  :

% Refs     : [MOW76] McCharen et al. (1976), Problems and Experiments for a
% Source   : [ANL]
% Names    : hp8.ver1.in [ANL]

% Status   : Unsatisfiable
% Rating   : 0.00 v9.1.0, 0.08 v9.0.0, 0.12 v8.2.0, 0.00 v7.4.0, 0.11 v7.3.0, 0.22 v7.2.0, 0.25 v7.1.0, 0.29 v7.0.0, 0.00 v6.4.0, 0.14 v6.3.0, 0.00 v6.0.0, 0.22 v5.5.0, 0.19 v5.4.0, 0.13 v5.3.0, 0.17 v5.2.0, 0.25 v5.1.0, 0.14 v5.0.0, 0.00 v4.1.0, 0.11 v4.0.1, 0.00 v4.0.0, 0.17 v3.5.0, 0.00 v3.1.0, 0.11 v2.7.0, 0.00 v2.3.0, 0.17 v2.2.1, 0.33 v2.2.0, 0.29 v2.1.0, 0.20 v2.0.0
% Syntax   : Number of clauses     :   13 (   7 unt;   0 nHn;  10 RR)
%            Number of literals    :   25 (   2 equ;  13 neg)
%            Maximal clause size   :    6 (   1 avg)
%            Maximal term depth    :    2 (   1 avg)
%            Number of predicates  :    3 (   2 usr;   0 prp; 2-3 aty)
%            Number of functors    :    8 (   8 usr;   7 con; 0-2 aty)
%            Number of variables   :   25 (   3 sgn)
% SPC      : CNF_UNS_RFO_SEQ_HRN

% Comments :
%--------------------------------------------------------------------------
%----Include Henkin model axioms
include('Axioms/HEN001-0.ax').
%--------------------------------------------------------------------------
cnf(aLEb,hypothesis,
    less_equal(a,b) ).

cnf(aQc,hypothesis,
    quotient(a,c,aQc) ).

cnf(bQc,hypothesis,
    quotient(b,c,bQc) ).

cnf(prove_aQcLEbQc,negated_conjecture,
    ~ less_equal(aQc,bQc) ).

%--------------------------------------------------------------------------
