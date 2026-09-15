% SZS output start Proof
fof(f21, axiom, african(somalia), file('Problems/PUZ/PUZ011-1.p', unknown)).
fof(f12, axiom, borders(indian, somalia), file('Problems/PUZ/PUZ011-1.p', unknown)).
fof(f24, axiom, asian(india), file('Problems/PUZ/PUZ011-1.p', unknown)).
fof(f2, axiom, ocean(indian), file('Problems/PUZ/PUZ011-1.p', unknown)).
fof(f9, axiom, borders(indian, india), file('Problems/PUZ/PUZ011-1.p', unknown)).
fof(goal_1, theorem, borders(indian,india), inference(instantiate, [status(thm)], [f9])).
fof(goal_2, theorem, borders(indian,somalia), inference(instantiate, [status(thm)], [f12])).
fof(goal_3, theorem, african(somalia), inference(instantiate, [status(thm)], [f21])).
fof(goal_4, theorem, ocean(indian), inference(instantiate, [status(thm)], [f2])).
fof(goal_5, theorem, asian(india), inference(instantiate, [status(thm)], [f24])).
% SZS output end Proof
