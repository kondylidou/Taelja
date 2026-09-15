% SZS output start Proof
cnf(indian_tanzania, hypothesis, borders(indian, tanzania), file('Problems/PUZ/PUZ011-1.p', indian_tanzania)).
cnf(tanzania, hypothesis, african(tanzania), file('Problems/PUZ/PUZ011-1.p', tanzania)).
cnf(indian, hypothesis, ocean(indian), file('Problems/PUZ/PUZ011-1.p', indian)).
cnf(iran, hypothesis, asian(iran), file('Problems/PUZ/PUZ011-1.p', iran)).
cnf(indian_iran, hypothesis, borders(indian, iran), file('Problems/PUZ/PUZ011-1.p', indian_iran)).
fof(goal_1, theorem, ocean(indian), inference(instantiate, [status(thm)], [indian])).
fof(goal_2, theorem, borders(indian,tanzania), inference(instantiate, [status(thm)], [indian_tanzania])).
fof(goal_3, theorem, african(tanzania), inference(instantiate, [status(thm)], [tanzania])).
fof(goal_4, theorem, borders(indian,iran), inference(instantiate, [status(thm)], [indian_iran])).
fof(goal_5, theorem, asian(iran), inference(instantiate, [status(thm)], [iran])).
% SZS output end Proof
