% SZS output start Proof
fof(f1, axiom, ! [X2, X3, X0, X1]: (c_lessequals(c_plus(X1, X3, X0), c_plus(X2, X3, X0), X0) | ~ c_lessequals(X1, X2, X0) | ~ class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(X0)), file('Problems/ANA/ANA009-2.p')).
fof(f2, axiom, ! [X0, X1]: (~ class_OrderedGroup_Oab__group__add(X0) | c_plus(X1, c_uminus(X1, X0), X0) = c_0), file('Problems/ANA/ANA009-2.p')).
fof(f3, negated_conjecture, ! [X0]: c_lessequals(v_lb(X0), v_f(X0), t_b), file('Problems/ANA/ANA009-2.p')).
fof(f5, axiom, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(X0)), file('Problems/ANA/ANA009-2.p')).
fof(f6, axiom, ! [X0]: (~ class_Ring__and__Field_Oordered__idom(X0) | class_OrderedGroup_Oab__group__add(X0)), file('Problems/ANA/ANA009-2.p')).
fof(f7, negated_conjecture, class_Ring__and__Field_Oordered__idom(t_b), file('Problems/ANA/ANA009-2.p')).
fof(lemma_7, lemma, class_OrderedGroup_Opordered__ab__semigroup__add__imp__le(t_b), inference(mp, [status(thm)], [f5, f7])).
fof(s1, plain, class_OrderedGroup_Oab__group__add(t_b), inference(mp, [status(thm)], [f6, f7])).
fof(lemma_8, lemma, ! [X] : c_plus(X,c_uminus(X,t_b),t_b) = c_0, inference(mp, [status(thm)], [f2, s1])).
fof(s2, plain, c_lessequals(v_lb(v_x),v_f(v_x),t_b), inference(instantiate, [status(thm)], [f3])).
fof(lemma_9, lemma, ! [X] : c_lessequals(c_plus(v_lb(v_x),X,t_b),c_plus(v_f(v_x),X,t_b),t_b), inference(mp, [status(thm)], [f1, s2, lemma_7])).
fof(s3, plain, c_lessequals(c_plus(v_lb(v_x),c_uminus(v_lb(v_x),t_b),t_b),c_plus(v_f(v_x),c_uminus(v_lb(v_x),t_b),t_b),t_b), inference(instantiate, [status(thm)], [lemma_9])).
fof(goal_1, theorem, c_lessequals(c_0,c_plus(v_f(v_x),c_uminus(v_lb(v_x),t_b),t_b),t_b), inference(rewrite, [status(thm)], [lemma_8, s3])).
% SZS output end Proof
