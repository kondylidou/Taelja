% SZS output start Proof
fof(c_50, plain, ! [X0]: 'E'(f('AP'(s(s('0')), X0)), '0'), file('Problems/SYO/SYO632-1.p', clause_2_02)).
fof(c_51, plain, ! [X0]: 'E'(f(X0), s('0')), file('Problems/SYO/SYO632-1.p', clause_0_03)).
fof(goal_1, theorem, ! [X] : 'E'(f(X),s('0')), inference(instantiate, [status(thm)], [c_51])).
fof(goal_2, theorem, ! [X] : 'E'(f('AP'(s(s('0')),X)),'0'), inference(instantiate, [status(thm)], [c_50])).
% SZS output end Proof
