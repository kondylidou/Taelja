%--------------------------------------------------------------------------
% File     : GRP035-3 : TPTP v9.2.1. Released v1.0.0.
% Domain   : Group Theory (Subgroups)
% Problem  : In subgroups, product is closed
% Version  : [Wos65] axioms.
% English  :

% Refs     : [Wos65] Wos (1965), Unpublished Note
%          : [MOW76] McCharen et al. (1976), Problems and Experiments for a
%          : [WM76]  Wilson & Minker (1976), Resolution, Refinements, and S
% Source   : [SPRFN]
% Names    : Problem 15 [Wos65]
%          : wos15 [WM76]

% Status   : Unsatisfiable
% Rating   : 0.00 v6.0.0, 0.22 v5.5.0, 0.31 v5.4.0, 0.27 v5.3.0, 0.33 v5.2.0, 0.25 v5.1.0, 0.29 v5.0.0, 0.14 v4.1.0, 0.11 v4.0.1, 0.17 v3.7.0, 0.00 v2.2.1, 0.11 v2.2.0, 0.14 v2.1.0, 0.00 v2.0.0
% Syntax   : Number of clauses     :   13 (   9 unt;   0 nHn;   8 RR)
%            Number of literals    :   24 (   1 equ;  12 neg)
%            Maximal clause size   :    4 (   1 avg)
%            Maximal term depth    :    2 (   1 avg)
%            Number of predicates  :    3 (   2 usr;   0 prp; 1-3 aty)
%            Number of functors    :    6 (   6 usr;   4 con; 0-2 aty)
%            Number of variables   :   25 (   0 sgn)
% SPC      : CNF_UNS_RFO_SEQ_HRN

% Comments : Proves one of the [MOW76] axioms.
%--------------------------------------------------------------------------
%----Include group theory axioms
include('Axioms/GRP003-0.ax').
%----Include sub-group theory axioms
include('Axioms/GRP003-2.ax').
%--------------------------------------------------------------------------
cnf(a_is_in_subgroup,hypothesis,
    subgroup_member(a) ).

cnf(b_is_in_subgroup,hypothesis,
    subgroup_member(b) ).

cnf(a_times_b_is_c,hypothesis,
    product(a,b,c) ).

cnf(prove_c_is_in_subgroup,negated_conjecture,
    ~ subgroup_member(c) ).

%--------------------------------------------------------------------------
