% SZS output start Proof
cnf(tfree_tcs, negated_conjecture, class_Ring__and__Field_Oordered__idom(t_b), file('Problems/ANA/ANA023-2.p', tfree_tcs)).
cnf(clsrel_Ring__and__Field_Oordered__idom_54, axiom, class_OrderedGroup_Opordered__ab__group__add(X1) | ~ class_Ring__and__Field_Oordered__idom(X1), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_54)).
cnf(clsrel_Ring__and__Field_Oordered__idom_23, axiom, class_OrderedGroup_Ocomm__monoid__add(X1) | ~ class_Ring__and__Field_Oordered__idom(X1), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_23)).
cnf(clsrel_Ring__and__Field_Oordered__idom_33, axiom, class_Orderings_Olinorder(X1) | ~ class_Ring__and__Field_Oordered__idom(X1), file('Problems/ANA/ANA023-2.p', clsrel_Ring__and__Field_Oordered__idom_33)).
cnf(clsrel_Orderings_Olinorder_4, axiom, class_Orderings_Oorder(X1) | ~ class_Orderings_Olinorder(X1), file('Problems/ANA/ANA023-2.p', clsrel_Orderings_Olinorder_4)).
cnf(cls_conjecture_2, negated_conjecture, c_lessequals(v_k(v_x), v_f(v_x), t_b), file('Problems/ANA/ANA023-2.p', cls_conjecture_2)).
cnf(cls_conjecture_1, negated_conjecture, c_lessequals(c_0, c_minus(v_k(v_x), v_g(v_x), t_b), t_b), file('Problems/ANA/ANA023-2.p', cls_conjecture_1)).
cnf(cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0, axiom, c_plus(c_0, X2, X1) = X2 | ~ class_OrderedGroup_Ocomm__monoid__add(X1), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0)).
cnf(cls_OrderedGroup_Ocompare__rls__9_0, axiom, c_lessequals(c_plus(X2, X4, X1), X3, X1) | ~ class_OrderedGroup_Opordered__ab__group__add(X1) | ~ c_lessequals(X2, c_minus(X3, X4, X1), X1), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_0)).
cnf(cls_Orderings_Oorder__class_Oorder__trans_0, axiom, c_lessequals(X4, X3, X1) | ~ class_Orderings_Oorder(X1) | ~ c_lessequals(X2, X3, X1) | ~ c_lessequals(X4, X2, X1), file('Problems/ANA/ANA023-2.p', cls_Orderings_Oorder__class_Oorder__trans_0)).
cnf(cls_OrderedGroup_Ocompare__rls__9_1, axiom, c_lessequals(X2, c_minus(X4, X3, X1), X1) | ~ class_OrderedGroup_Opordered__ab__group__add(X1) | ~ c_lessequals(c_plus(X2, X3, X1), X4, X1), file('Problems/ANA/ANA023-2.p', cls_OrderedGroup_Ocompare__rls__9_1)).
fof(lemma_12, lemma, class_OrderedGroup_Opordered__ab__group__add(t_b), inference(mp, [status(thm)], [clsrel_Ring__and__Field_Oordered__idom_54, tfree_tcs])).
fof(lemma_13, lemma, class_OrderedGroup_Ocomm__monoid__add(t_b), inference(mp, [status(thm)], [clsrel_Ring__and__Field_Oordered__idom_23, tfree_tcs])).
fof(lemma_14, lemma, ! [X] : c_plus(c_0,X,t_b) = X, inference(mp, [status(thm)], [cls_OrderedGroup_Ocomm__monoid__add__class_Oaxioms_0, lemma_13])).
fof(s1, plain, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_k(v_x),t_b), inference(mp, [status(thm)], [cls_OrderedGroup_Ocompare__rls__9_0, lemma_12, cls_conjecture_1])).
fof(lemma_15, lemma, c_lessequals(v_g(v_x),v_k(v_x),t_b), inference(rewrite, [status(thm)], [lemma_14, s1])).
fof(s2, plain, class_Orderings_Olinorder(t_b), inference(mp, [status(thm)], [clsrel_Ring__and__Field_Oordered__idom_33, tfree_tcs])).
fof(s3, plain, class_Orderings_Oorder(t_b), inference(mp, [status(thm)], [clsrel_Orderings_Olinorder_4, s2])).
fof(s4, plain, c_lessequals(v_g(v_x),v_f(v_x),t_b), inference(mp, [status(thm)], [cls_Orderings_Oorder__class_Oorder__trans_0, s3, cls_conjecture_2, lemma_15])).
fof(lemma_16, lemma, c_lessequals(c_plus(c_0,v_g(v_x),t_b),v_f(v_x),t_b), inference(rewrite, [status(thm)], [lemma_14, s4])).
fof(goal_1, theorem, c_lessequals(c_0,c_minus(v_f(v_x),v_g(v_x),t_b),t_b), inference(mp, [status(thm)], [cls_OrderedGroup_Ocompare__rls__9_1, lemma_12, lemma_16])).
% SZS output end Proof
