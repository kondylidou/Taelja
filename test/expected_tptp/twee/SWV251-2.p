% SZS output start Proof
cnf(c2, negated_conjecture, c_in(v_x, c_Message_Oanalz(c_insert(v_X, v_H, tc_Message_Omsg)), tc_Message_Omsg), file('TPTP/Problems/SWV/SWV251-2.p', cls_conjecture_1)).
cnf(c3, axiom, c_lessequals(V_A, V_A, tc_set(T_a)), file('TPTP/Problems/SWV/SWV251-2.p', cls_Set_Osubset__refl_0)).
cnf(c4, axiom, ~ c_lessequals(c_union(V_A2, V_B, T_a2), V_C, tc_set(T_a2)) | c_lessequals(V_B, V_C, tc_set(T_a2)), file('TPTP/Problems/SWV/SWV251-2.p', cls_Set_OUn__subset__iff_1)).
cnf(c6, axiom, ~ c_lessequals(V_G, V_H, tc_set(tc_Message_Omsg)) | c_lessequals(c_Message_Oanalz(V_G), c_Message_Oanalz(V_H), tc_set(tc_Message_Omsg)), file('TPTP/Problems/SWV/SWV251-2.p', cls_Message_Oanalz__mono_0)).
cnf(c7, axiom, c_union(V_A2, c_minus(V_B2, V_A2, tc_set(T_a2)), T_a2) = c_union(V_A2, V_B2, T_a2), file('TPTP/Problems/SWV/SWV251-2.p', cls_Set_OUn__Diff__cancel_0)).
cnf(c9, negated_conjecture, c_in(v_X, c_Message_Osynth(c_Message_Oanalz(v_G)), tc_Message_Omsg), file('TPTP/Problems/SWV/SWV251-2.p', cls_conjecture_0)).
cnf(c10, axiom, ~ c_in(V_x, V_B2, T_a2) | c_minus(c_insert(V_x, V_A2, T_a2), V_B2, tc_set(T_a2)) = c_minus(V_A2, V_B2, tc_set(T_a2)), file('TPTP/Problems/SWV/SWV251-2.p', cls_Set_Oinsert__Diff1_0)).
cnf(c15, axiom, ~ c_in(V_c, V_A2, T_a2) | ~ c_lessequals(V_A2, V_B2, tc_set(T_a2)) | c_in(V_c, V_B2, T_a2), file('TPTP/Problems/SWV/SWV251-2.p', cls_Set_OsubsetD_0)).
fof(lemma_9, lemma, ! [X] : c_minus(c_insert(v_X,X,tc_Message_Omsg),c_Message_Osynth(c_Message_Oanalz(v_G)),tc_set(tc_Message_Omsg)) = c_minus(X,c_Message_Osynth(c_Message_Oanalz(v_G)),tc_set(tc_Message_Omsg)), inference(mp, [status(thm)], [c10, c9])).
fof(s1, plain, c_lessequals(c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_insert(v_X,v_H,tc_Message_Omsg),tc_Message_Omsg),c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_insert(v_X,v_H,tc_Message_Omsg),tc_Message_Omsg),tc_set(tc_Message_Omsg)), inference(instantiate, [status(thm)], [c3])).
fof(s2, plain, c_lessequals(c_insert(v_X,v_H,tc_Message_Omsg),c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_insert(v_X,v_H,tc_Message_Omsg),tc_Message_Omsg),tc_set(tc_Message_Omsg)), inference(mp, [status(thm)], [c4, s1])).
fof(s3, plain, c_lessequals(c_insert(v_X,v_H,tc_Message_Omsg),c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_minus(c_insert(v_X,v_H,tc_Message_Omsg),c_Message_Osynth(c_Message_Oanalz(v_G)),tc_set(tc_Message_Omsg)),tc_Message_Omsg),tc_set(tc_Message_Omsg)), inference(rewrite, [status(thm)], [c7, s2])).
fof(s4, plain, c_lessequals(c_insert(v_X,v_H,tc_Message_Omsg),c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_minus(v_H,c_Message_Osynth(c_Message_Oanalz(v_G)),tc_set(tc_Message_Omsg)),tc_Message_Omsg),tc_set(tc_Message_Omsg)), inference(rewrite, [status(thm)], [lemma_9, s3])).
fof(s5, plain, c_lessequals(c_Message_Oanalz(c_insert(v_X,v_H,tc_Message_Omsg)),c_Message_Oanalz(c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),c_minus(v_H,c_Message_Osynth(c_Message_Oanalz(v_G)),tc_set(tc_Message_Omsg)),tc_Message_Omsg)),tc_set(tc_Message_Omsg)), inference(mp, [status(thm)], [c6, s4])).
fof(lemma_10, lemma, c_lessequals(c_Message_Oanalz(c_insert(v_X,v_H,tc_Message_Omsg)),c_Message_Oanalz(c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),v_H,tc_Message_Omsg)),tc_set(tc_Message_Omsg)), inference(rewrite, [status(thm)], [c7, s5])).
fof(goal_1, theorem, c_in(v_x,c_Message_Oanalz(c_union(c_Message_Osynth(c_Message_Oanalz(v_G)),v_H,tc_Message_Omsg)),tc_Message_Omsg), inference(mp, [status(thm)], [c15, c2, lemma_10])).
% SZS output end Proof
