%------------------------------------------------------------------------------
% File     : PUZ056-2.005 : TPTP v9.2.1. Released v3.5.0.
% Domain   : Puzzles
% Problem  : Towers of Hanoi k=05
% Version  : Especial.
% English  : Each instance encodes Tower of Hanoi with n discs as a
%            reachability problem.

% Refs     : [NV07]  Navarro (2007), Email to Geoff Sutcliffe
% Source   : [NV07]
% Names    : hanoi-k05 [NV07a]

% Status   : Unsatisfiable
% Rating   : 0.00 v3.5.0
% Syntax   : Number of clauses     :   16 (  11 unt;   0 nHn;  15 RR)
%            Number of literals    :   41 (   0 equ;  29 neg)
%            Maximal clause size   :   10 (   2 avg)
%            Maximal term depth    :    1 (   1 avg)
%            Number of predicates  :    2 (   2 usr;   0 prp; 2-5 aty)
%            Number of functors    :    3 (   3 usr;   3 con; 0-0 aty)
%            Number of variables   :   30 (   2 sgn)
% SPC      : CNF_UNS_EPR_NEQ_HRN

% Comments : k >= 13 not solved by any prover in less than 1 hr. (2007)
%------------------------------------------------------------------------------
cnf(rule1,axiom,
    ( ~ p(I,T1,T2,T3,T4)
    | p(J,T1,T2,T3,T4) ) ).

cnf(rule2,axiom,
    ( ~ p(T0,I,T2,T3,T4)
    | ~ neq(T0,I)
    | ~ neq(T0,J)
    | p(T0,J,T2,T3,T4) ) ).

cnf(rule3,axiom,
    ( ~ p(T0,T1,I,T3,T4)
    | ~ neq(T0,I)
    | ~ neq(T0,J)
    | ~ neq(T1,I)
    | ~ neq(T1,J)
    | p(T0,T1,J,T3,T4) ) ).

cnf(rule4,axiom,
    ( ~ p(T0,T1,T2,I,T4)
    | ~ neq(T0,I)
    | ~ neq(T0,J)
    | ~ neq(T1,I)
    | ~ neq(T1,J)
    | ~ neq(T2,I)
    | ~ neq(T2,J)
    | p(T0,T1,T2,J,T4) ) ).

cnf(rule5,axiom,
    ( ~ p(T0,T1,T2,T3,I)
    | ~ neq(T0,I)
    | ~ neq(T0,J)
    | ~ neq(T1,I)
    | ~ neq(T1,J)
    | ~ neq(T2,I)
    | ~ neq(T2,J)
    | ~ neq(T3,I)
    | ~ neq(T3,J)
    | p(T0,T1,T2,T3,J) ) ).

cnf(neq1,axiom,
    ~ neq(s0,s0) ).

cnf(neq2,axiom,
    neq(s0,s1) ).

cnf(neq3,axiom,
    neq(s0,s2) ).

cnf(neq4,axiom,
    neq(s1,s0) ).

cnf(neq5,axiom,
    ~ neq(s1,s1) ).

cnf(neq6,axiom,
    neq(s1,s2) ).

cnf(neq7,axiom,
    neq(s2,s0) ).

cnf(neq8,axiom,
    neq(s2,s1) ).

cnf(neq9,axiom,
    ~ neq(s2,s2) ).

cnf(init,axiom,
    p(s0,s0,s0,s0,s0) ).

cnf(goal,negated_conjecture,
    ~ p(s2,s2,s2,s2,s2) ).

%------------------------------------------------------------------------------
