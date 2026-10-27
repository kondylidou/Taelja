% SZS output start Proof
cnf(indian_iran, hypothesis, borders(indian, iran), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ011-1.p', indian_iran)).
cnf(iran, hypothesis, asian(iran), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ011-1.p', iran)).
cnf(indian, hypothesis, ocean(indian), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ011-1.p', indian)).
cnf(tanzania, hypothesis, african(tanzania), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ011-1.p', tanzania)).
cnf(indian_tanzania, hypothesis, borders(indian, tanzania), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ011-1.p', indian_tanzania)).
fof(goal_1, theorem, ocean(indian), inference(instantiate, [status(thm)], [indian])).
fof(goal_2, theorem, borders(indian,tanzania), inference(instantiate, [status(thm)], [indian_tanzania])).
fof(goal_3, theorem, african(tanzania), inference(instantiate, [status(thm)], [tanzania])).
fof(goal_4, theorem, borders(indian,iran), inference(instantiate, [status(thm)], [indian_iran])).
fof(goal_5, theorem, asian(iran), inference(instantiate, [status(thm)], [iran])).
% SZS output end Proof
