% SZS output start Proof
fof(f5, negated_conjecture, ! [X0]: X0 = v_ta, file('Problems/SWV/SWV818-1.p')).
fof(s1, plain, v_s = v_ta, inference(instantiate, [status(thm)], [f5])).
fof(goal_1, theorem, v_s = v_t, inference(rewrite, [status(thm)], [f5, s1])).
% SZS output end Proof
