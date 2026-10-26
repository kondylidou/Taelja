% SZS output start Proof
fof(c_50, plain, ocean(indian), file('Problems/PUZ/PUZ011-1.p', indian)).
fof(c_57, plain, borders(indian, india), file('Problems/PUZ/PUZ011-1.p', indian_india)).
fof(c_60, plain, borders(indian, somalia), file('Problems/PUZ/PUZ011-1.p', indian_somalia)).
fof(c_69, plain, african(somalia), file('Problems/PUZ/PUZ011-1.p', somalia)).
fof(c_72, plain, asian(india), file('Problems/PUZ/PUZ011-1.p', india)).
fof(goal_1, theorem, borders(indian,somalia), inference(instantiate, [status(thm)], [c_60])).
fof(goal_2, theorem, borders(indian,india), inference(instantiate, [status(thm)], [c_57])).
fof(goal_3, theorem, ocean(indian), inference(instantiate, [status(thm)], [c_50])).
fof(goal_4, theorem, african(somalia), inference(instantiate, [status(thm)], [c_69])).
fof(goal_5, theorem, asian(india), inference(instantiate, [status(thm)], [c_72])).
% SZS output end Proof
