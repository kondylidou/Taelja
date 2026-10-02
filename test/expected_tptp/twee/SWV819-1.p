% SZS output start Proof
cnf(c2, negated_conjecture, V_s = v_ta, file('TPTP/Problems/SWV/SWV819-1.p', cls_conjecture_1)).
fof(lemma_2, lemma, ! [X,Y] : X = Y, inference(rewrite, [status(thm)], [c2, c2])).
fof(goal_1, theorem, v_s = v_t, inference(instantiate, [status(thm)], [lemma_2])).
% SZS output end Proof
