% SZS output start Proof
cnf(c2, axiom, c_in(c_Zorn_OHausdorff__1(V_S, T_a), c_Zorn_Omaxchain(V_S, T_a), tc_set(tc_set(T_a))), file('TPTP/Problems/SET/SET865-2.p', cls_Zorn_OHausdorff_0)).
cnf(c3, axiom, c_lessequals(c_Zorn_Omaxchain(V_S2, T_a2), c_Zorn_Ochain(V_S2, T_a2), tc_set(tc_set(tc_set(T_a2)))), file('TPTP/Problems/SET/SET865-2.p', cls_Zorn_Omaxchain__subset__chain_0)).
cnf(c4, axiom, ~ c_in(V_c, V_A, T_a2) | ~ c_lessequals(V_A, V_B, tc_set(T_a2)) | c_in(V_c, V_B, T_a2), file('TPTP/Problems/SET/SET865-2.p', cls_Set_OsubsetD_0)).
cnf(c7, negated_conjecture, c_in(c_Union(V_U2, t_a), v_S, tc_set(t_a)) | ~ c_in(V_U2, c_Zorn_Ochain(v_S, t_a), tc_set(tc_set(t_a))), file('TPTP/Problems/SET/SET865-2.p', cls_conjecture_0)).
cnf(c9, negated_conjecture, c_in(v_x(V_U2), v_S, tc_set(t_a)) | ~ c_in(V_U2, v_S, tc_set(t_a)), file('TPTP/Problems/SET/SET865-2.p', cls_conjecture_1)).
cnf(c14, negated_conjecture, c_lessequals(V_U2, v_x(V_U2), tc_set(t_a)) | ~ c_in(V_U2, v_S, tc_set(t_a)), file('TPTP/Problems/SET/SET865-2.p', cls_conjecture_2)).
cnf(c16, axiom, ~ c_in(V_u, V_S2, tc_set(T_a2)) | ~ c_in(V_c2, c_Zorn_Omaxchain(V_S2, T_a2), tc_set(tc_set(T_a2))) | ~ c_lessequals(c_Union(V_c2, T_a2), V_u, tc_set(T_a2)) | c_Union(V_c2, T_a2) = V_u, file('TPTP/Problems/SET/SET865-2.p', cls_Zorn_Omaxchain__Zorn_0)).
fof(s1, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Omaxchain(v_S,t_a),tc_set(tc_set(t_a))), inference(instantiate, [status(thm)], [c2])).
fof(s2, plain, c_lessequals(c_Zorn_Omaxchain(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(tc_set(t_a)))), inference(instantiate, [status(thm)], [c3])).
fof(s3, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(t_a))), inference(mp, [status(thm)], [c4, s1, s2])).
fof(s4, plain, c_in(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a),v_S,tc_set(t_a)), inference(mp, [status(thm)], [c7, s3])).
fof(lemma_8, lemma, c_lessequals(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a),v_x(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a)),tc_set(t_a)), inference(mp, [status(thm)], [c14, s4])).
fof(s5, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Omaxchain(v_S,t_a),tc_set(tc_set(t_a))), inference(instantiate, [status(thm)], [c2])).
fof(s6, plain, c_lessequals(c_Zorn_Omaxchain(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(tc_set(t_a)))), inference(instantiate, [status(thm)], [c3])).
fof(s7, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(t_a))), inference(mp, [status(thm)], [c4, s5, s6])).
fof(goal_1, theorem, c_in(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a),v_S,tc_set(t_a)), inference(mp, [status(thm)], [c7, s7])).
fof(s8, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Omaxchain(v_S,t_a),tc_set(tc_set(t_a))), inference(instantiate, [status(thm)], [c2])).
fof(s9, plain, c_lessequals(c_Zorn_Omaxchain(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(tc_set(t_a)))), inference(instantiate, [status(thm)], [c3])).
fof(s10, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Ochain(v_S,t_a),tc_set(tc_set(t_a))), inference(mp, [status(thm)], [c4, s8, s9])).
fof(s11, plain, c_in(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a),v_S,tc_set(t_a)), inference(mp, [status(thm)], [c7, s10])).
fof(s12, plain, c_in(v_x(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a)),v_S,tc_set(t_a)), inference(mp, [status(thm)], [c9, s11])).
fof(s13, plain, c_in(c_Zorn_OHausdorff__1(v_S,t_a),c_Zorn_Omaxchain(v_S,t_a),tc_set(tc_set(t_a))), inference(instantiate, [status(thm)], [c2])).
fof(goal_2, theorem, c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a) = v_x(c_Union(c_Zorn_OHausdorff__1(v_S,t_a),t_a)), inference(mp, [status(thm)], [c16, s12, s13, lemma_8])).
% SZS output end Proof
