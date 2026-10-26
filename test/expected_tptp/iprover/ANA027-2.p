% SZS output start Proof
fof(c_49, plain, c_lessequals(c_0, c_minus(v_f(v_x), v_k(v_x), t_b), t_b), file('Problems/ANA/ANA027-2.p', cls_conjecture_1)).
fof(c_50, plain, c_lessequals(v_g(v_x), v_k(v_x), t_b), file('Problems/ANA/ANA027-2.p', cls_conjecture_2)).
fof(c_52, plain, class_Ring__and__Field_Oordered__idom(t_b), file('Problems/ANA/ANA027-2.p', tfree_tcs)).
fof(c_53, plain, ! [X0, X1]: (~ class_OrderedGroup_Ocomm__monoid__add(X0) | c_plus(c_0, X1, X0) = X1), file('Problems/ANA/ANA027-2.p', cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0)).
fof(c_54, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(X0, c_minus(X1, X2, X3), X3) | ~ class_OrderedGroup_Opordered__ab__group__add(X3) | c_lessequals(c_plus(X0, X2, X3), X1, X3)), file('Problems/ANA/ANA027-2.p', cls_OrderedGroup_Ocompare__rls__9_0)).
fof(c_55, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(c_plus(X0, X1, X2), X3, X2) | ~ class_OrderedGroup_Opordered__ab__group__add(X2) | c_lessequals(X0, c_minus(X3, X1, X2), X2)), file('Problems/ANA/ANA027-2.p', cls_OrderedGroup_Ocompare__rls__9_1)).
fof(c_56, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(X0, X1, X2) | ~ c_lessequals(X3, X0, X2) | ~ class_Orderings_Oorder(X2) | c_lessequals(X3, X1, X2)), file('Problems/ANA/ANA027-2.p', cls_Orderings_Oorder__class_Oorder__trans_0)).
fof(c_57, plain, ! [X0]: (~ class_LOrder_Ojoin__semilorder(X0) | class_Orderings_Oorder(X0)), file('Problems/ANA/ANA027-2.p', clsrel_LOrder_Ojoin__semilorder_1)).
fof(c_58, plain, ! [X0]: (~ class_OrderedGroup_Olordered__ab__group__abs(X0) | class_OrderedGroup_Opordered__ab__group__add(X0)), file('Problems/ANA/ANA027-2.p', clsrel_OrderedGroup_Olordered__ab__group__abs_1)).
fof(c_59, plain, ! [X0]: (~ class_OrderedGroup_Olordered__ab__group__abs(X0) | class_LOrder_Ojoin__semilorder(X0)), file('Problems/ANA/ANA027-2.p', clsrel_OrderedGroup_Olordered__ab__group__abs_15)).
fof(c_60, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Ocomm__monoid__add(X0)), file('Problems/ANA/ANA027-2.p', clsrel_Ring__and__Field_Oordered__idom_23)).
fof(c_61, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Olordered__ab__group__abs(X0)), file('Problems/ANA/ANA027-2.p', clsrel_Ring__and__Field_Oordered__idom_50)).
fof(s1, plain, class_OrderedGroup_Ocomm__monoid__add(t_b), inference(mp, [status(thm)], [c_60, c_52])).
fof(lemma_13, lemma, ! [X] : c_plus(c_0,X,t_b) = X, inference(mp, [status(thm)], [c_53, s1])).
fof(lemma_14, lemma, class_OrderedGroup_Olordered__ab__group__abs(t_b), inference(mp, [status(thm)], [c_61, c_52])).
fof(lemma_15, lemma, class_OrderedGroup_Opordered__ab__group__add(t_b), inference(mp, [status(thm)], [c_58, lemma_14])).
fof(s2, plain, class_LOrder_Ojoin__semilorder(t_b), inference(mp, [status(thm)], [c_59, lemma_14])).
fof(lemma_16, lemma, class_Orderings_Oorder(t_b), inference(mp, [status(thm)], [c_57, s2])).
fof(s3, plain, c_lessequals(c_plus(c_0,v_k(v_x),t_b),v_f(v_x),t_b), inference(mp, [status(thm)], [c_54, c_49, lemma_15])).
fof(s4, plain, c_lessequals(v_k(v_x),v_f(v_x),t_b), inference(rewrite, [status(thm)], [lemma_13, s3])).
fof(s5, plain, c_lessequals(v_g(v_x),v_f(v_x),t_b), inference(mp, [status(thm)], [c_56, s4, c_50, lemma_16])).
fof(s6, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_f(v_x),t_b), inference(rewrite, [status(thm)], [lemma_13, s5])).
fof(goal_1, theorem, c_lessequals(c_0,c_minus(v_f(v_x),v_g(v_x),t_b),t_b), inference(mp, [status(thm)], [c_55, s6, lemma_15])).
% SZS output end Proof
