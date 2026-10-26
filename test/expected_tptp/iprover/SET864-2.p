% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2, X3]: (~ c_in(X0, c_Zorn_Omaxchain(X1, X2), tc_set(tc_set(X2))) | ~ c_lessequals(c_Union(X0, X2), X3, tc_set(X2)) | ~ c_in(X3, X1, tc_set(X2)) | c_Union(X0, X2) = X3), file('Problems/SET/SET864-2.p', cls_Zorn_Omaxchain__Zorn_0)).
fof(c_50, plain, c_in(v_c, c_Zorn_Omaxchain(v_S, t_a), tc_set(tc_set(t_a))), file('Problems/SET/SET864-2.p', cls_conjecture_0)).
fof(c_51, plain, c_in(c_Union(v_c, t_a), v_S, tc_set(t_a)), file('Problems/SET/SET864-2.p', cls_conjecture_2)).
fof(c_52, plain, ! [X0]: (~ c_in(X0, v_S, tc_set(t_a)) | c_in(v_x(X0), v_S, tc_set(t_a))), file('Problems/SET/SET864-2.p', cls_conjecture_3)).
fof(c_53, plain, ! [X0]: (~ c_in(X0, v_S, tc_set(t_a)) | c_lessequals(X0, v_x(X0), tc_set(t_a))), file('Problems/SET/SET864-2.p', cls_conjecture_4)).
fof(lemma_6, lemma, c_lessequals(c_Union(v_c,t_a),v_x(c_Union(v_c,t_a)),tc_set(t_a)), inference(mp, [status(thm)], [c_53, c_51])).
fof(lemma_7, lemma, c_in(v_x(c_Union(v_c,t_a)),v_S,tc_set(t_a)), inference(mp, [status(thm)], [c_52, c_51])).
fof(goal_1, theorem, v_x(c_Union(v_c,t_a)) = c_Union(v_c,t_a), inference(mp, [status(thm)], [c_49, c_50, lemma_6, lemma_7])).
fof(goal_2, theorem, c_in(c_Union(v_c,t_a),v_S,tc_set(t_a)), inference(instantiate, [status(thm)], [c_51])).
% SZS output end Proof
