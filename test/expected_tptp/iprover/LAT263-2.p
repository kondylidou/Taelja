% SZS output start Proof
fof(c_49, plain, c_lessequals(v_S, v_A, tc_set(t_a)), file('Problems/LAT/LAT263-2.p', cls_conjecture_0)).
fof(c_51, plain, c_Tarski_Opotype_Opset(v_cl, t_a, tc_Product__Type_Ounit) = v_A, file('Problems/LAT/LAT263-2.p', cls_Tarski_OA_A_61_61_Apset_Acl_0)).
fof(c_52, plain, ! [X0, X1, X2]: (~ c_lessequals(X0, c_Tarski_Opotype_Opset(X1, X2, tc_Product__Type_Ounit), tc_set(X2)) | ~ c_in(X1, c_Tarski_OCompleteLattice, tc_Tarski_Opotype_Opotype__ext__type(X2, tc_Product__Type_Ounit)) | ~ c_in(X1, c_Tarski_OPartialOrder, tc_Tarski_Opotype_Opotype__ext__type(X2, tc_Product__Type_Ounit)) | c_in(c_Tarski_Olub(X0, X1, X2), c_Tarski_Opotype_Opset(X1, X2, tc_Product__Type_Ounit), X2)), file('Problems/LAT/LAT263-2.p', cls_Tarski_OCL_Olub__in__lattice_0)).
fof(c_53, plain, c_in(c_Tarski_Odual(v_cl, t_a), c_Tarski_OCompleteLattice, tc_Tarski_Opotype_Opotype__ext__type(t_a, tc_Product__Type_Ounit)), file('Problems/LAT/LAT263-2.p', cls_Tarski_Odual_Acl_A_58_ACompleteLattice_0)).
fof(c_54, plain, c_in(c_Tarski_Odual(v_cl, t_a), c_Tarski_OPartialOrder, tc_Tarski_Opotype_Opotype__ext__type(t_a, tc_Product__Type_Ounit)), file('Problems/LAT/LAT263-2.p', cls_Tarski_Odual_Acl_A_58_APartialOrder_0)).
fof(c_55, plain, ! [X0, X1, X2]: c_Tarski_Olub(X0, c_Tarski_Odual(X1, X2), X2) = c_Tarski_Oglb(X0, X1, X2), file('Problems/LAT/LAT263-2.p', cls_Tarski_Oglb__dual__lub_0)).
fof(c_56, plain, ! [X0, X1]: c_Tarski_Opotype_Opset(c_Tarski_Odual(X0, X1), X1, tc_Product__Type_Ounit) = c_Tarski_Opotype_Opset(X0, X1, tc_Product__Type_Ounit), file('Problems/LAT/LAT263-2.p', cls_Tarski_Opset_A_Idual_Acl_J_A_61_61_Apset_Acl_0)).
fof(s1, plain, c_lessequals(v_S,c_Tarski_Opotype_Opset(v_cl,t_a,tc_Product__Type_Ounit),tc_set(t_a)), inference(rewrite, [status(thm)], [c_51, c_49])).
fof(s2, plain, c_lessequals(v_S,c_Tarski_Opotype_Opset(c_Tarski_Odual(v_cl,t_a),t_a,tc_Product__Type_Ounit),tc_set(t_a)), inference(rewrite, [status(thm)], [c_56, s1])).
fof(s3, plain, c_in(c_Tarski_Olub(v_S,c_Tarski_Odual(v_cl,t_a),t_a),c_Tarski_Opotype_Opset(c_Tarski_Odual(v_cl,t_a),t_a,tc_Product__Type_Ounit),t_a), inference(mp, [status(thm)], [c_52, s2, c_53, c_54])).
fof(s4, plain, c_in(c_Tarski_Olub(v_S,c_Tarski_Odual(v_cl,t_a),t_a),c_Tarski_Opotype_Opset(v_cl,t_a,tc_Product__Type_Ounit),t_a), inference(rewrite, [status(thm)], [c_56, s3])).
fof(s5, plain, c_in(c_Tarski_Oglb(v_S,v_cl,t_a),c_Tarski_Opotype_Opset(v_cl,t_a,tc_Product__Type_Ounit),t_a), inference(rewrite, [status(thm)], [c_55, s4])).
fof(goal_1, theorem, c_in(c_Tarski_Oglb(v_S,v_cl,t_a),v_A,t_a), inference(rewrite, [status(thm)], [c_51, s5])).
% SZS output end Proof
