% SZS output start Proof
fof(c_49, plain, ! [X0]: le(X0, X0), file('Problems/SYO/SYO611-1.p', sos_01)).
fof(c_52, plain, ! [X0]: eq(f(X0), a0), file('Problems/SYO/SYO611-1.p', sos_04)).
fof(goal_1, theorem, ! [X] : le(s(X),s(X)), inference(instantiate, [status(thm)], [c_49])).
fof(goal_2, theorem, ! [X] : eq(f(X),a0), inference(instantiate, [status(thm)], [c_52])).
fof(goal_3, theorem, ! [X] : eq(f(s(X)),a0), inference(instantiate, [status(thm)], [c_52])).
% SZS output end Proof
