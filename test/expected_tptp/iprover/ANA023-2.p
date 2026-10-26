% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ class_OrderedGroup_Ocomm__monoid__add(X0) | c_plus(c_0, X1, X0) = X1), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0)).
fof(c_50, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(X0, c_minus(X1, X2, X3), X3) | ~ class_OrderedGroup_Opordered__ab__group__add(X3) | c_lessequals(c_plus(X0, X2, X3), X1, X3)), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_0)).
fof(c_51, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(c_plus(X0, X1, X2), X3, X2) | ~ class_OrderedGroup_Opordered__ab__group__add(X2) | c_lessequals(X0, c_minus(X3, X1, X2), X2)), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_1)).
fof(c_52, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(X0, X1, X2) | ~ c_lessequals(X3, X0, X2) | ~ class_Orderings_Oorder(X2) | c_lessequals(X3, X1, X2)), file('Problems/ANA/ANA023-2.p', cls_Orderings_Oorder__class_Oorder__trans_0)).
fof(c_53, plain, c_lessequals(c_0, c_minus(v_k(v_x), v_g(v_x), t_b), t_b), file('Problems/ANA/ANA023-2.p', cls_conjecture_1)).
fof(c_54, plain, c_lessequals(v_k(v_x), v_f(v_x), t_b), file('Problems/ANA/ANA023-2.p', cls_conjecture_2)).
fof(c_56, plain, ! [X0]: (~ class_Orderings_Olinorder(X0) | class_Orderings_Oorder(X0)), file('Problems/ANA/ANA023-2.p', clsrel_Orderings_Olinorder_4)).
fof(c_57, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Ocomm__monoid__add(X0)), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_23)).
fof(c_58, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_Orderings_Olinorder(X0)), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_33)).
fof(c_59, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Opordered__ab__group__add(X0)), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_54)).
fof(c_60, plain, class_Ring__and__Field_Oordered__idom(t_b), file('Problems/ANA/ANA023-2.p', tfree_tcs)).
fof(s1, plain, class_OrderedGroup_Ocomm__monoid__add(t_b), inference(mp, [status(thm)], [c_57, c_60])).
fof(lemma_12, lemma, ! [X] : c_plus(c_0,X,t_b) = X, inference(mp, [status(thm)], [c_49, s1])).
fof(lemma_13, lemma, class_OrderedGroup_Opordered__ab__group__add(t_b), inference(mp, [status(thm)], [c_59, c_60])).
fof(s2, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_k(v_x),t_b), inference(mp, [status(thm)], [c_50, c_53, lemma_13])).
fof(lemma_14, lemma, c_lessequals(v_g(v_x),v_k(v_x),t_b), inference(rewrite, [status(thm)], [lemma_12, s2])).
fof(s3, plain, class_Orderings_Olinorder(t_b), inference(mp, [status(thm)], [c_58, c_60])).
fof(lemma_15, lemma, class_Orderings_Oorder(t_b), inference(mp, [status(thm)], [c_56, s3])).
fof(s4, plain, c_lessequals(v_g(v_x),v_f(v_x),t_b), inference(mp, [status(thm)], [c_52, c_54, lemma_14, lemma_15])).
fof(s5, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_f(v_x),t_b), inference(rewrite, [status(thm)], [lemma_12, s4])).
fof(goal_1, theorem, c_lessequals(c_0,c_minus(v_f(v_x),v_g(v_x),t_b),t_b), inference(mp, [status(thm)], [c_51, s5, lemma_13])).
% SZS output end Proof
