% SZS output start Proof
cnf(sos_04, axiom, eq(f(X1), a0), file('Problems/SYO/SYO611-1.p', sos_04)).
cnf(sos_01, axiom, le(X1, X1), file('Problems/SYO/SYO611-1.p', sos_01)).
fof(goal_1, theorem, ! [X] : eq(f(X),a0), inference(instantiate, [status(thm)], [sos_04])).
fof(goal_2, theorem, ! [X] : eq(f(s(X)),a0), inference(instantiate, [status(thm)], [sos_04])).
fof(goal_3, theorem, ! [X] : le(s(X),s(X)), inference(instantiate, [status(thm)], [sos_01])).
% SZS output end Proof
