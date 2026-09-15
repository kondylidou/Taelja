% SZS output start Proof
fof(f82, negated_conjecture, man(skc8, skc10), file('Problems/NLP/NLP258-1.p')).
fof(f84, negated_conjecture, accessible_world(skc8, skc12), file('Problems/NLP/NLP258-1.p')).
fof(f52, axiom, ! [X2, X0, X1]: (~ accessible_world(X0, X1) | ~ man(X0, X2) | man(X1, X2)), file('Problems/NLP/NLP258-1.p')).
fof(f74, negated_conjecture, man(skc8, skc15), file('Problems/NLP/NLP258-1.p')).
fof(f92, negated_conjecture, ! [X0, X1]: (~ man(skc12, X0) | present(skc12, skf2(X1))), file('Problems/NLP/NLP258-1.p')).
fof(f91, negated_conjecture, ! [X0, X1]: (~ man(skc12, X0) | smoke(skc12, skf2(X1))), file('Problems/NLP/NLP258-1.p')).
fof(f94, negated_conjecture, ! [X0]: (agent(skc12, skf2(X0), X0) | ~ man(skc12, X0)), file('Problems/NLP/NLP258-1.p')).
fof(f87, negated_conjecture, agent(skc8, skc13, skc15), file('Problems/NLP/NLP258-1.p')).
fof(f77, negated_conjecture, event(skc8, skc13), file('Problems/NLP/NLP258-1.p')).
fof(f78, negated_conjecture, present(skc8, skc13), file('Problems/NLP/NLP258-1.p')).
fof(f79, negated_conjecture, think_believe_consider(skc8, skc13), file('Problems/NLP/NLP258-1.p')).
fof(f88, negated_conjecture, theme(skc8, skc13, skc12), file('Problems/NLP/NLP258-1.p')).
fof(f85, negated_conjecture, proposition(skc8, skc12), file('Problems/NLP/NLP258-1.p')).
fof(f80, negated_conjecture, jules_forename(skc8, skc11), file('Problems/NLP/NLP258-1.p')).
fof(f89, negated_conjecture, of(skc8, skc11, skc10), file('Problems/NLP/NLP258-1.p')).
fof(f76, negated_conjecture, vincent_forename(skc8, skc14), file('Problems/NLP/NLP258-1.p')).
fof(f86, negated_conjecture, of(skc8, skc14, skc15), file('Problems/NLP/NLP258-1.p')).
fof(f73, negated_conjecture, actual_world(skc8), file('Problems/NLP/NLP258-1.p')).
fof(f83, negated_conjecture, state(skc8, skc9), file('Problems/NLP/NLP258-1.p')).
fof(f90, negated_conjecture, be(skc8, skc9, skc10, skc10), file('Problems/NLP/NLP258-1.p')).
fof(f29, axiom, ! [X0, X1]: (~ vincent_forename(X0, X1) | forename(X0, X1)), file('Problems/NLP/NLP258-1.p')).
fof(f30, axiom, ! [X0, X1]: (~ jules_forename(X0, X1) | forename(X0, X1)), file('Problems/NLP/NLP258-1.p')).
fof(f1, axiom, ! [X0, X1]: (~ smoke(X0, X1) | event(X0, X1)), file('Problems/NLP/NLP258-1.p')).
fof(f95, negated_conjecture, ! [X2, X3, X10, X0, X1, X8, X6, X9, X7, X4, X5]: (~ be(X0, X1, X2, X2) | ~ man(X0, X2) | ~ state(X0, X1) | ~ smoke(X3, X4) | ~ present(X3, X4) | ~ agent(X3, X4, X2) | ~ event(X3, X4) | ~ forename(X0, X5) | ~ jules_forename(X0, X5) | ~ of(X0, X5, X2) | ~ accessible_world(X0, X3) | ~ proposition(X0, X3) | ~ proposition(X0, X6) | ~ accessible_world(X0, X6) | ~ think_believe_consider(X0, X7) | ~ present(X0, X7) | ~ event(X0, X7) | ~ theme(X0, X7, X6) | ~ agent(X0, X8, X9) | ~ agent(X0, X7, X9) | ~ man(X0, X9) | ~ of(X0, X10, X9) | ~ vincent_forename(X0, X10) | ~ forename(X0, X10) | ~ theme(X0, X8, X3) | ~ event(X0, X8) | ~ present(X0, X8) | ~ think_believe_consider(X0, X8) | ~ actual_world(X0) | man(X6, skf4(X6))), file('Problems/NLP/NLP258-1.p')).
fof(s1, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(lemma_25, lemma, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [f91, s1])).
fof(s2, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(lemma_26, lemma, present(skc12,skf2(skc10)), inference(mp, [status(thm)], [f92, s2])).
fof(s3, plain, man(skc12,skc10), inference(mp, [status(thm)], [f52, f84, f82])).
fof(lemma_27, lemma, agent(skc12,skf2(skc10),skc10), inference(mp, [status(thm)], [f94, s3])).
fof(s4, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(s5, plain, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [f91, s4])).
fof(lemma_28, lemma, event(skc12,skf2(skc10)), inference(mp, [status(thm)], [f1, s5])).
fof(lemma_29, lemma, forename(skc8,skc11), inference(mp, [status(thm)], [f30, f80])).
fof(lemma_30, lemma, forename(skc8,skc14), inference(mp, [status(thm)], [f29, f76])).
fof(s6, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(s7, plain, smoke(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f91, s6])).
fof(goal_1, theorem, event(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f1, s7])).
fof(s8, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(s9, plain, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [f91, s8])).
fof(goal_2, theorem, event(skc12,skf2(skc10)), inference(mp, [status(thm)], [f1, s9])).
fof(s10, plain, man(skc12,skc10), inference(mp, [status(thm)], [f52, f84, f82])).
fof(goal_3, theorem, agent(skc12,skf2(skc10),skc10), inference(mp, [status(thm)], [f94, s10])).
fof(s11, plain, man(skc12,skf4(skc12)), inference(mp, [status(thm)], [f95, f90, f82, f83, lemma_25, lemma_26, lemma_27, lemma_28, lemma_29, f80, f89, f84, f85, f85, f84, f79, f78, f77, f88, f87, f87, f74, f86, f76, lemma_30, f88, f77, f78, f79, f73])).
fof(goal_4, theorem, agent(skc12,skf2(skf4(skc12)),skf4(skc12)), inference(mp, [status(thm)], [f94, s11])).
fof(goal_5, theorem, man(skc8,skc10), inference(instantiate, [status(thm)], [f82])).
fof(goal_6, theorem, be(skc8,skc9,skc10,skc10), inference(instantiate, [status(thm)], [f90])).
fof(s12, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(goal_7, theorem, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [f91, s12])).
fof(s13, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(goal_8, theorem, present(skc12,skf2(skc10)), inference(mp, [status(thm)], [f92, s13])).
fof(s14, plain, man(skc12,skc10), inference(mp, [status(thm)], [f52, f84, f82])).
fof(goal_9, theorem, agent(skc12,skf2(skc10),skc10), inference(mp, [status(thm)], [f94, s14])).
fof(goal_10, theorem, event(skc12,skf2(skc10)), inference(instantiate, [status(thm)], [lemma_28])).
fof(goal_11, theorem, forename(skc8,skc11), inference(instantiate, [status(thm)], [lemma_29])).
fof(goal_12, theorem, jules_forename(skc8,skc11), inference(instantiate, [status(thm)], [f80])).
fof(goal_13, theorem, of(skc8,skc11,skc10), inference(instantiate, [status(thm)], [f89])).
fof(goal_14, theorem, accessible_world(skc8,skc12), inference(instantiate, [status(thm)], [f84])).
fof(goal_15, theorem, proposition(skc8,skc12), inference(instantiate, [status(thm)], [f85])).
fof(goal_16, theorem, proposition(skc8,skc12), inference(instantiate, [status(thm)], [f85])).
fof(goal_17, theorem, accessible_world(skc8,skc12), inference(instantiate, [status(thm)], [f84])).
fof(s15, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(goal_18, theorem, smoke(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f91, s15])).
fof(s16, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(goal_19, theorem, present(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f92, s16])).
fof(goal_20, theorem, state(skc8,skc9), inference(instantiate, [status(thm)], [f83])).
fof(s17, plain, man(skc12,skc15), inference(mp, [status(thm)], [f52, f84, f74])).
fof(s18, plain, smoke(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f91, s17])).
fof(goal_21, theorem, event(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [f1, s18])).
fof(goal_22, theorem, think_believe_consider(skc8,skc13), inference(instantiate, [status(thm)], [f79])).
fof(goal_23, theorem, present(skc8,skc13), inference(instantiate, [status(thm)], [f78])).
fof(goal_24, theorem, event(skc8,skc13), inference(instantiate, [status(thm)], [f77])).
fof(goal_25, theorem, theme(skc8,skc13,skc12), inference(instantiate, [status(thm)], [f88])).
fof(goal_26, theorem, agent(skc8,skc13,skc15), inference(instantiate, [status(thm)], [f87])).
fof(goal_27, theorem, agent(skc8,skc13,skc15), inference(instantiate, [status(thm)], [f87])).
fof(goal_28, theorem, man(skc8,skc15), inference(instantiate, [status(thm)], [f74])).
fof(goal_29, theorem, of(skc8,skc14,skc15), inference(instantiate, [status(thm)], [f86])).
fof(goal_30, theorem, vincent_forename(skc8,skc14), inference(instantiate, [status(thm)], [f76])).
fof(goal_31, theorem, forename(skc8,skc14), inference(instantiate, [status(thm)], [lemma_30])).
fof(goal_32, theorem, theme(skc8,skc13,skc12), inference(instantiate, [status(thm)], [f88])).
fof(goal_33, theorem, event(skc8,skc13), inference(instantiate, [status(thm)], [f77])).
fof(goal_34, theorem, present(skc8,skc13), inference(instantiate, [status(thm)], [f78])).
fof(goal_35, theorem, think_believe_consider(skc8,skc13), inference(instantiate, [status(thm)], [f79])).
fof(goal_36, theorem, actual_world(skc8), inference(instantiate, [status(thm)], [f73])).
% SZS output end Proof
