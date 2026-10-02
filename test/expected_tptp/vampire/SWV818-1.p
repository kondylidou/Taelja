% SZS output start Proof
fof(f5, negated_conjecture, ! [X0]: X0 = v_ta, file('Problems/SWV/SWV818-1.p')).
fof(lemma_2, lemma, ! [X,Y] : X = Y, inference(rewrite, [status(thm)], [f5, f5])).
fof(goal_1, theorem, v_s = v_t, inference(instantiate, [status(thm)], [lemma_2])).
% SZS output end Proof
