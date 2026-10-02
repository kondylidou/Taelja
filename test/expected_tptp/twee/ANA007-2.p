% SZS output start Proof
cnf(c2, negated_conjecture, class_Ring__and__Field_Oordered__idom(t_b), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA007-2.p', tfree_tcs)).
cnf(c3, axiom, ~ class_Ring__and__Field_Oordered__idom(T_a) | V_c = c_times(c_1, V_c, T_a), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA007-2.p', cls_Ring__and__Field_Omult__cancel__right1_2)).
cnf(c5, axiom, ~ class_Ring__and__Field_Oordered__idom(T) | class_Orderings_Oorder(T), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA007-2.p', clsrel_Ring__and__Field_Oordered__idom_44)).
cnf(c7, axiom, ~ class_Orderings_Oorder(T_a2) | c_lessequals(V_x, V_x, T_a2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/ANA/ANA007-2.p', cls_Orderings_Oorder__class_Oaxioms__1_0)).
fof(lemma_5, lemma, ! [X] : X = c_times(c_1,X,t_b), inference(mp, [status(thm)], [c3, c2])).
fof(s1, plain, class_Orderings_Oorder(t_b), inference(mp, [status(thm)], [c5, c2])).
fof(s2, plain, c_lessequals(c_HOL_Oabs(v_f(v_x(c_1)),t_b),c_HOL_Oabs(v_f(v_x(c_1)),t_b),t_b), inference(mp, [status(thm)], [c7, s1])).
fof(goal_1, theorem, c_lessequals(c_HOL_Oabs(v_f(v_x(c_1)),t_b),c_times(c_1,c_HOL_Oabs(v_f(v_x(c_1)),t_b),t_b),t_b), inference(rewrite, [status(thm)], [lemma_5, s2])).
% SZS output end Proof
