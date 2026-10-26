% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2, X3]: (~ c_lessequals(X0, X1, X2) | ~ class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(X2) | c_lessequals(c_plus(X0, X3, X2), c_plus(X1, X3, X2), X2)), file('Problems/ANA/ANA009-2.p', cls_OrderedGroup_Oadd__le__cancel__right_1)).
fof(c_50, plain, ! [X0, X1]: (~ class_OrderedGroup_Oab__group__add(X0) | c_plus(X1, c_uminus(X1, X0), X0) = c_0), file('Problems/ANA/ANA009-2.p', cls_OrderedGroup_Oright__minus_0)).
fof(c_51, plain, ! [X0]: c_lessequals(v_lb(X0), v_f(X0), t_b), file('Problems/ANA/ANA009-2.p', cls_conjecture_0)).
fof(c_53, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(X0)), file('Problems/ANA/ANA009-2.p', clsrel_Ring__and__Field_Oordered__idom_37)).
fof(c_54, plain, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Oab__group__add(X0)), file('Problems/ANA/ANA009-2.p', clsrel_Ring__and__Field_Oordered__idom_4)).
fof(c_55, plain, class_Ring__and__Field_Oordered__idom(t_b), file('Problems/ANA/ANA009-2.p', tfree_tcs)).
fof(lemma_7, lemma, class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(t_b), inference(mp, [status(thm)], [c_53, c_55])).
fof(s1, plain, class_OrderedGroup_Oab__group__add(t_b), inference(mp, [status(thm)], [c_54, c_55])).
fof(lemma_8, lemma, ! [X] : c_plus(X,c_uminus(X,t_b),t_b) = c_0, inference(mp, [status(thm)], [c_50, s1])).
fof(s2, plain, c_lessequals(v_lb(v_x),v_f(v_x),t_b), inference(instantiate, [status(thm)], [c_51])).
fof(s3, plain, c_lessequals(c_plus(v_lb(v_x),c_uminus(v_lb(v_x),t_b),t_b),c_plus(v_f(v_x),c_uminus(v_lb(v_x),t_b),t_b),t_b), inference(mp, [status(thm)], [c_49, s2, lemma_7])).
fof(goal_1, theorem, c_lessequals(c_0,c_plus(v_f(v_x),c_uminus(v_lb(v_x),t_b),t_b),t_b), inference(rewrite, [status(thm)], [lemma_8, s3])).
% SZS output end Proof
