% SZS output start Proof
fof(f1, axiom, value(truth, truth), file('Problems/MSC/MSC005-1.p')).
fof(f2, axiom, value(falsity, falsity), file('Problems/MSC/MSC005-1.p')).
fof(f3, axiom, ! [X0, X1]: (value(xor(X0, X1), falsity) | ~ value(X1, truth) | ~ value(X0, truth)), file('Problems/MSC/MSC005-1.p')).
fof(f4, axiom, ! [X0, X1]: (value(xor(X0, X1), truth) | ~ value(X1, falsity) | ~ value(X0, truth)), file('Problems/MSC/MSC005-1.p')).
fof(f6, axiom, ! [X0, X1]: (value(xor(X0, X1), falsity) | ~ value(X1, falsity) | ~ value(X0, falsity)), file('Problems/MSC/MSC005-1.p')).
fof(lemma_6, lemma, value(xor(truth,falsity),truth), inference(mp, [status(thm)], [f4, f2, f1])).
fof(lemma_7, lemma, value(xor(xor(truth,falsity),falsity),truth), inference(mp, [status(thm)], [f4, f2, lemma_6])).
fof(lemma_8, lemma, value(xor(xor(xor(truth,falsity),falsity),truth),falsity), inference(mp, [status(thm)], [f3, f1, lemma_7])).
fof(goal_1, theorem, value(xor(xor(xor(xor(truth,falsity),falsity),truth),falsity),falsity), inference(mp, [status(thm)], [f6, f2, lemma_8])).
% SZS output end Proof
