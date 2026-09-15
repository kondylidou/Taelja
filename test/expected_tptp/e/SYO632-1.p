% SZS output start Proof
cnf(clause_0_03, axiom, 'E'(f(X1), s('0')), file('Problems/SYO/SYO632-1.p', clause_0_03)).
cnf(clause_2_02, axiom, 'E'(f('AP'(s(s('0')), X1)), '0'), file('Problems/SYO/SYO632-1.p', clause_2_02)).
fof(c_0_4, plain, ~ epred2_0 <=> ! [X1]: ~ 'E'(f(X1), '0'), introduced(definition, [], [])).
cnf(c_0_7, plain, epred2_0 | ~ 'E'(f(X1), '0'), inference(split_equiv, [status(thm)], [c_0_4])).
fof(goal_1, theorem, ! [X] : 'E'(f('AP'(s(s('0')),X)),'0'), inference(instantiate, [status(thm)], [clause_2_02])).
fof(goal_2, theorem, ! [X] : 'E'(f(X),s('0')), inference(instantiate, [status(thm)], [clause_0_03])).
% SZS output end Proof
