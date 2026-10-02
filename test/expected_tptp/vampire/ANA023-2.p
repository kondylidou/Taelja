% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: (~ class_OrderedGroup_Ocomm__monoid__add(X0) | c_plus(c_0, X1, X0) = X1), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0)).
fof(f2, axiom, ! [X2, X3, X0, X1]: (~ c_lessequals(X1, c_minus(X2, X3, X0), X0) | ~ class_OrderedGroup_Opordered__ab__group__add(X0) | c_lessequals(c_plus(X1, X3, X0), X2, X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_0)).
fof(f3, axiom, ! [X2, X3, X0, X1]: (~ c_lessequals(c_plus(X1, X2, X0), X3, X0) | ~ class_OrderedGroup_Opordered__ab__group__add(X0) | c_lessequals(X1, c_minus(X3, X2, X0), X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_1)).
fof(f4, axiom, ! [X2, X3, X0, X1]: (~ c_lessequals(X3, X1, X0) | ~ c_lessequals(X1, X2, X0) | ~ class_Orderings_Oorder(X0) | c_lessequals(X3, X2, X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_Orderings_Oorder__class_Oorder__trans_0)).
fof(f5, negated_conjecture, c_lessequals(c_0, c_minus(v_k(v_x), v_g(v_x), t_b), t_b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_conjecture_1)).
fof(f6, negated_conjecture, c_lessequals(v_k(v_x), v_f(v_x), t_b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', cls_conjecture_2)).
fof(f8, axiom, ! [X0]: (~ class_Orderings_Olinorder(X0) | class_Orderings_Oorder(X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', clsrel_Orderings_Olinorder_4)).
fof(f9, axiom, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Ocomm__monoid__add(X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_23)).
fof(f10, axiom, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_Orderings_Olinorder(X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_33)).
fof(f11, axiom, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Opordered__ab__group__add(X0)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_54)).
fof(f12, negated_conjecture, class_Ring__and__Field_Oordered__idom(t_b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA023-2.p', tfree_tcs)).
fof(s1, plain, class_OrderedGroup_Ocomm__monoid__add(t_b), inference(mp, [status(thm)], [f9, f12])).
fof(lemma_12, lemma, ! [X] : c_plus(c_0,X,t_b) = X, inference(mp, [status(thm)], [f1, s1])).
fof(lemma_13, lemma, class_OrderedGroup_Opordered__ab__group__add(t_b), inference(mp, [status(thm)], [f11, f12])).
fof(s2, plain, class_Orderings_Olinorder(t_b), inference(mp, [status(thm)], [f10, f12])).
fof(lemma_14, lemma, class_Orderings_Oorder(t_b), inference(mp, [status(thm)], [f8, s2])).
fof(s3, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_k(v_x),t_b), inference(mp, [status(thm)], [f2, f5, lemma_13])).
fof(s4, plain, c_lessequals(v_g(v_x),v_k(v_x),t_b), inference(rewrite, [status(thm)], [lemma_12, s3])).
fof(s5, plain, c_lessequals(v_g(v_x),v_f(v_x),t_b), inference(mp, [status(thm)], [f4, s4, f6, lemma_14])).
fof(s6, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_f(v_x),t_b), inference(rewrite, [status(thm)], [lemma_12, s5])).
fof(goal_1, theorem, c_lessequals(c_0,c_minus(v_f(v_x),v_g(v_x),t_b),t_b), inference(mp, [status(thm)], [f3, s6, lemma_13])).
% SZS output end Proof
