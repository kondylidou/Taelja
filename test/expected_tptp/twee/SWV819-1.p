% SZS output start Proof
cnf(c2, negated_conjecture, V_s = v_ta, file('TPTP/Problems/SWV/SWV819-1.p', cls_conjecture_1)).
fof(s1, plain, v_s = v_ta, inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, v_s = v_t, inference(rewrite, [status(thm)], [c2, s1])).
% SZS output end Proof
