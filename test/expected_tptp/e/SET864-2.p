% SZS output start Proof
cnf(cls_conjecture_2, negated_conjecture, c_in(c_Union(v_c, t_a), v_S, tc_set(t_a)), file('Problems/SET/SET864-2.p', cls_conjecture_2)).
cnf(cls_conjecture_3, negated_conjecture, c_in(v_x(X1), v_S, tc_set(t_a)) | ~ c_in(X1, v_S, tc_set(t_a)), file('Problems/SET/SET864-2.p', cls_conjecture_3)).
cnf(cls_conjecture_4, negated_conjecture, c_lessequals(X1, v_x(X1), tc_set(t_a)) | ~ c_in(X1, v_S, tc_set(t_a)), file('Problems/SET/SET864-2.p', cls_conjecture_4)).
cnf(cls_conjecture_0, negated_conjecture, c_in(v_c, c_Zorn_Omaxchain(v_S, t_a), tc_set(tc_set(t_a))), file('Problems/SET/SET864-2.p', cls_conjecture_0)).
cnf(cls_Zorn_Omaxchain__Zorn_0, axiom, c_Union(X4, X3) = X1 | ~ c_in(X1, X2, tc_set(X3)) | ~ c_in(X4, c_Zorn_Omaxchain(X2, X3), tc_set(tc_set(X3))) | ~ c_lessequals(c_Union(X4, X3), X1, tc_set(X3)), file('Problems/SET/SET864-2.p', cls_Zorn_Omaxchain__Zorn_0)).
fof(lemma_6, lemma, c_in(v_x(c_Union(v_c,t_a)),v_S,tc_set(t_a)), inference(mp, [status(thm)], [cls_conjecture_3, cls_conjecture_2])).
fof(lemma_7, lemma, c_lessequals(c_Union(v_c,t_a),v_x(c_Union(v_c,t_a)),tc_set(t_a)), inference(mp, [status(thm)], [cls_conjecture_4, cls_conjecture_2])).
fof(goal_1, theorem, c_in(c_Union(v_c,t_a),v_S,tc_set(t_a)), inference(instantiate, [status(thm)], [cls_conjecture_2])).
fof(goal_2, theorem, c_Union(v_c,t_a) = v_x(c_Union(v_c,t_a)), inference(mp, [status(thm)], [cls_Zorn_Omaxchain__Zorn_0, lemma_6, cls_conjecture_0, lemma_7])).
% SZS output end Proof
