% SZS output start Proof
cnf(c6, hypothesis, asian(india), file('TPTP/Problems/PUZ/PUZ011-1.p', india)).
cnf(c5, hypothesis, borders(indian, india), file('TPTP/Problems/PUZ/PUZ011-1.p', indian_india)).
cnf(c4, hypothesis, african(somalia), file('TPTP/Problems/PUZ/PUZ011-1.p', somalia)).
cnf(c3, hypothesis, borders(indian, somalia), file('TPTP/Problems/PUZ/PUZ011-1.p', indian_somalia)).
cnf(c2, hypothesis, ocean(indian), file('TPTP/Problems/PUZ/PUZ011-1.p', indian)).
fof(goal_1, theorem, ocean(indian), inference(instantiate, [status(thm)], [c2])).
fof(goal_2, theorem, borders(indian,somalia), inference(instantiate, [status(thm)], [c3])).
fof(goal_3, theorem, african(somalia), inference(instantiate, [status(thm)], [c4])).
fof(goal_4, theorem, borders(indian,india), inference(instantiate, [status(thm)], [c5])).
fof(goal_5, theorem, asian(india), inference(instantiate, [status(thm)], [c6])).
% SZS output end Proof
