% SZS output start Proof
cnf(c2, axiom, c_minus(V_A, V_A, tc_set(T_a)) = c_emptyset, file('TPTP/Problems/LCL/LCL431-2.p', cls_Set_ODiff__cancel_0)).
cnf(c3, negated_conjecture, c_PropLog_Osat(c_emptyset, v_p, t_a), file('TPTP/Problems/LCL/LCL431-2.p', cls_conjecture_0)).
cnf(c4, axiom, ~ c_PropLog_Osat(c_emptyset, V_p, T_a2) | c_in(V_p, c_PropLog_Othms(c_minus(c_PropLog_Ohyps(V_p, V_U, T_a2), c_PropLog_Ohyps(V_p, V_t0, T_a2), tc_set(tc_PropLog_Opl(T_a2))), T_a2), tc_PropLog_Opl(T_a2)), file('TPTP/Problems/LCL/LCL431-2.p', cls_PropLog_Ocompleteness__0__lemma__dest_0)).
fof(s1, plain, c_in(v_p,c_PropLog_Othms(c_minus(c_PropLog_Ohyps(v_p,v_p,t_a),c_PropLog_Ohyps(v_p,v_p,t_a),tc_set(tc_PropLog_Opl(t_a))),t_a),tc_PropLog_Opl(t_a)), inference(mp, [status(thm)], [c4, c3])).
fof(goal_1, theorem, c_in(v_p,c_PropLog_Othms(c_emptyset,t_a),tc_PropLog_Opl(t_a)), inference(rewrite, [status(thm)], [c2, s1])).
% SZS output end Proof
