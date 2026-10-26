% SZS output start Proof
fof(c_52, plain, ! [X0]: X0 = v_ta, file('Problems/SWV/SWV818-1.p', cls_conjecture_1)).
fof(s1, plain, v_s = v_ta, inference(instantiate, [status(thm)], [c_52])).
fof(goal_1, theorem, v_s = v_t, inference(rewrite, [status(thm)], [c_52, s1])).
% SZS output end Proof
