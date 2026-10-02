% SZS output start Proof
tff(decl_sort1, type, state: $tType).
tff(decl_sort2, type, label: $tType).
tff(decl_sort3, type, statement: $tType).
tff(decl_23, type, p3: state).
tff(decl_26, type, p8: state).
tff(decl_30, type, loop: label).
tff(decl_32, type, goto: label > statement).
tff(decl_34, type, follows: (state * state) > $o).
tff(decl_35, type, succeeds: (state * state) > $o).
tff(decl_36, type, labels: (label * state) > $o).
tff(decl_37, type, has: (state * statement) > $o).
tff(direct_success, axiom, ! [X1: state, X2: state]: (follows(X2, X1) => succeeds(X2, X1)), file('Problems/COM/COM001_1.p', direct_success)).
tff(goto_success, axiom, ! [X2: state, X4: label, X1: state]: ((has(X1, goto(X4)) & labels(X4, X2)) => succeeds(X2, X1)), file('Problems/COM/COM001_1.p', goto_success)).
tff(transitivity_of_success, axiom, ! [X1: state, X3: state, X2: state]: ((succeeds(X2, X3) & succeeds(X3, X1)) => succeeds(X2, X1)), file('Problems/COM/COM001_1.p', transitivity_of_success)).
tff(transition_3_to_8, hypothesis, follows(p8, p3), file('Problems/COM/COM001_1.p', transition_3_to_8)).
tff(state_8, hypothesis, has(p8, goto(loop)), file('Problems/COM/COM001_1.p', state_8)).
tff(label_state_3, hypothesis, labels(loop, p3), file('Problems/COM/COM001_1.p', label_state_3)).
tff(lemma_7, lemma, succeeds(p8,p3), inference(mp, [status(thm)], [direct_success, transition_3_to_8])).
tff(s1, plain, succeeds(p3,p8), inference(mp, [status(thm)], [goto_success, state_8, label_state_3])).
tff(prove_there_is_a_loop_through_p3, theorem, succeeds(p3, p3), inference(mp, [status(thm)], [transitivity_of_success, s1, lemma_7])).
% SZS output end Proof
