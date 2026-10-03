%--------------------------------------------------------------------------
% File     : GEO002-4 : TPTP v9.2.1. Released v1.1.0.
% Domain   : Geometry
% Problem  : For all points x and y, x is between x and y
% Version  : [MOW76] axioms : Reduced > Incomplete.
% English  :

% Refs     : [MOW76] McCharen et al. (1976), Problems and Experiments for a
%          : [Wos88] Wos (1988), Automated Reasoning - 33 Basic Research Pr
% Source   : [ANL]
% Names    : Simple Theorem on Betweenness [Wos88]

% Status   : Unsatisfiable
% Rating   : 0.00 v6.1.0, 0.14 v6.0.0, 0.11 v5.5.0, 0.19 v5.4.0, 0.22 v5.3.0, 0.25 v5.2.0, 0.08 v5.1.0, 0.19 v5.0.0, 0.20 v4.0.1, 0.14 v3.4.0, 0.00 v2.6.0, 0.29 v2.5.0, 0.00 v2.4.0, 0.00 v2.3.0, 0.14 v2.2.1, 0.44 v2.2.0, 0.33 v2.1.0, 0.29 v2.0.0
% Syntax   : Number of clauses     :    8 (   3 unt;   0 nHn;   6 RR)
%            Number of literals    :   17 (   0 equ;  10 neg)
%            Maximal clause size   :    3 (   2 avg)
%            Maximal term depth    :    2 (   1 avg)
%            Number of predicates  :    3 (   3 usr;   0 prp; 2-4 aty)
%            Number of functors    :    4 (   4 usr;   2 con; 0-5 aty)
%            Number of variables   :   29 (   3 sgn)
% SPC      : CNF_UNS_RFO_NEQ_HRN

% Comments :
%--------------------------------------------------------------------------
%----Include Tarski geometry axioms
% include('Axioms/GEO001-0.ax').
%--------------------------------------------------------------------------
cnf(transitivity_for_betweeness,axiom,
    ( ~ between(X,Y,V)
    | ~ between(Y,Z,V)
    | between(X,Y,Z) ) ).

cnf(identity_for_equidistance,axiom,
    ( ~ equidistant(X,Y,Z,Z)
    | equalish(X,Y) ) ).

cnf(outer_pasch1,axiom,
    ( ~ between(X,W,V)
    | ~ between(Y,V,Z)
    | between(X,outer_pasch(W,X,Y,Z,V),Y) ) ).

cnf(outer_pasch2,axiom,
    ( ~ between(X,W,V)
    | ~ between(Y,V,Z)
    | between(Z,W,outer_pasch(W,X,Y,Z,V)) ) ).

cnf(segment_construction1,axiom,
    between(X,Y,extension(X,Y,W,V)) ).

cnf(segment_construction2,axiom,
    equidistant(Y,extension(X,Y,W,V),W,V) ).

%----Equality substitution axioms
cnf(between_substitution3,axiom,
    ( ~ equalish(X,Y)
    | ~ between(W,Z,X)
    | between(W,Z,Y) ) ).

cnf(prove_a_between_a_and_b,negated_conjecture,
    ~ between(a,a,b) ).

%--------------------------------------------------------------------------
