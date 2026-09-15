% SZS output start Proof
cnf(cls_conjecture_1, negated_conjecture, X1 = v_ta, file('Problems/SWV/SWV818-1.p', cls_conjecture_1)).
fof(s1, plain, v_s = v_ta, inference(instantiate, [status(thm)], [cls_conjecture_1])).
fof(goal_1, theorem, v_s = v_t, inference(rewrite, [status(thm)], [cls_conjecture_1, s1])).
% SZS output end Proof
