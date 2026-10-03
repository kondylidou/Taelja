% SZS output start Proof
cnf(clause_2_02, axiom, 'E'(f('AP'(s(s('0')), X1)), '0'), file('Problems/SYO/SYO632-1.p', clause_2_02)).
cnf(clause_0_03, axiom, 'E'(f(X1), s('0')), file('Problems/SYO/SYO632-1.p', clause_0_03)).
fof(goal_1, theorem, ! [X] : 'E'(f('AP'(s(s('0')),X)),'0'), inference(instantiate, [status(thm)], [clause_2_02])).
fof(goal_2, theorem, ! [X] : 'E'(f(X),s('0')), inference(instantiate, [status(thm)], [clause_0_03])).
% SZS output end Proof
