% SZS output start Proof
tff(taelja_sort_boolean, type, boolean: $tType).
tff(taelja_sort_register, type, register: $tType).
tff(taelja_sort_number, type, number: $tType).
tff(taelja_sort_state, type, state: $tType).
tff(taelja_sort_statement, type, statement: $tType).
tff(taelja_sort_label, type, label: $tType).
tff(func_def_0, type, p3: state).
tff(pred_def_1, type, follows: (state * state) > $o).
tff(pred_def_2, type, succeeds: (state * state) > $o).
tff(pred_def_3, type, labels: (label * state) > $o).
tff(pred_def_4, type, has: (state * statement) > $o).
tff(func_def_5, type, register_j: register).
tff(func_def_6, type, out: label).
tff(func_def_7, type, loop: label).
tff(func_def_8, type, equal_function: (register * number) > boolean).
tff(func_def_9, type, goto: label > statement).
tff(func_def_10, type, ifthen: (boolean * state) > statement).
tff(taelja_type_p8, type, p8: state).
tff(f1, axiom, ! [X0: state, X1: state]: (follows(X1, X0) => succeeds(X1, X0)), file('Problems/COM/COM001_1.p', direct_success)).
tff(f2, axiom, ! [X0: state, X2: state, X1: state]: ((succeeds(X2, X0) & succeeds(X1, X2)) => succeeds(X1, X0)), file('Problems/COM/COM001_1.p', transitivity_of_success)).
tff(f3, axiom, ! [X1: state, X3: label, X0: state]: ((labels(X3, X1) & has(X0, goto(X3))) => succeeds(X1, X0)), file('Problems/COM/COM001_1.p', goto_success)).
tff(f5, axiom, labels(loop, p3), file('Problems/COM/COM001_1.p', label_state_3)).
tff(f9, axiom, follows(p8, p3), file('Problems/COM/COM001_1.p', transition_3_to_8)).
tff(f10, axiom, has(p8, goto(loop)), file('Problems/COM/COM001_1.p', state_8)).
tff(lemma_7, lemma, succeeds(p3,p8), inference(mp, [status(thm)], [f3, f5, f10])).
tff(s1, plain, succeeds(p8,p3), inference(mp, [status(thm)], [f1, f9])).
tff(f11, theorem, succeeds(p3, p3), inference(mp, [status(thm)], [f2, s1, lemma_7])).
% SZS output end Proof
