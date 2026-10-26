% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ smoke(X0, X1) | event(X0, X1)), file('Problems/NLP/NLP258-1.p', clause1)).
fof(c_77, plain, ! [X0, X1]: (~ vincent_forename(X0, X1) | forename(X0, X1)), file('Problems/NLP/NLP258-1.p', clause29)).
fof(c_78, plain, ! [X0, X1]: (~ jules_forename(X0, X1) | forename(X0, X1)), file('Problems/NLP/NLP258-1.p', clause30)).
fof(c_100, plain, ! [X0, X1, X2]: (~ man(X0, X1) | ~ accessible_world(X0, X2) | man(X2, X1)), file('Problems/NLP/NLP258-1.p', clause52)).
fof(c_120, plain, actual_world(skc8), file('Problems/NLP/NLP258-1.p', clause72)).
fof(c_121, plain, man(skc8, skc15), file('Problems/NLP/NLP258-1.p', clause73)).
fof(c_123, plain, vincent_forename(skc8, skc14), file('Problems/NLP/NLP258-1.p', clause75)).
fof(c_124, plain, event(skc8, skc13), file('Problems/NLP/NLP258-1.p', clause76)).
fof(c_125, plain, present(skc8, skc13), file('Problems/NLP/NLP258-1.p', clause77)).
fof(c_126, plain, think_believe_consider(skc8, skc13), file('Problems/NLP/NLP258-1.p', clause78)).
fof(c_127, plain, jules_forename(skc8, skc11), file('Problems/NLP/NLP258-1.p', clause79)).
fof(c_129, plain, man(skc8, skc10), file('Problems/NLP/NLP258-1.p', clause81)).
fof(c_130, plain, state(skc8, skc9), file('Problems/NLP/NLP258-1.p', clause82)).
fof(c_131, plain, accessible_world(skc8, skc12), file('Problems/NLP/NLP258-1.p', clause83)).
fof(c_132, plain, proposition(skc8, skc12), file('Problems/NLP/NLP258-1.p', clause84)).
fof(c_133, plain, of(skc8, skc14, skc15), file('Problems/NLP/NLP258-1.p', clause85)).
fof(c_134, plain, agent(skc8, skc13, skc15), file('Problems/NLP/NLP258-1.p', clause86)).
fof(c_135, plain, theme(skc8, skc13, skc12), file('Problems/NLP/NLP258-1.p', clause87)).
fof(c_136, plain, of(skc8, skc11, skc10), file('Problems/NLP/NLP258-1.p', clause88)).
fof(c_137, plain, be(skc8, skc9, skc10, skc10), file('Problems/NLP/NLP258-1.p', clause89)).
fof(c_138, plain, ! [X0, X1]: (~ man(skc12, X0) | smoke(skc12, skf2(X1))), file('Problems/NLP/NLP258-1.p', clause90)).
fof(c_139, plain, ! [X0, X1]: (~ man(skc12, X0) | present(skc12, skf2(X1))), file('Problems/NLP/NLP258-1.p', clause91)).
fof(c_141, plain, ! [X0]: (~ man(skc12, X0) | agent(skc12, skf2(X0), X0)), file('Problems/NLP/NLP258-1.p', clause93)).
fof(c_142, plain, ! [X0, X1, X2, X3, X4, X5, X6, X7, X8, X9, X10]: (~ be(X0, X1, X2, X2) | ~ agent(X0, X3, X4) | ~ agent(X0, X5, X4) | ~ agent(X6, X7, X2) | ~ theme(X0, X3, X8) | ~ theme(X0, X5, X6) | ~ of(X0, X9, X2) | ~ of(X0, X10, X4) | ~ smoke(X6, X7) | ~ event(X0, X3) | ~ event(X0, X5) | ~ event(X6, X7) | ~ proposition(X0, X6) | ~ proposition(X0, X8) | ~ state(X0, X1) | ~ man(X0, X2) | ~ man(X0, X4) | ~ forename(X0, X9) | ~ forename(X0, X10) | ~ vincent_forename(X0, X10) | ~ jules_forename(X0, X9) | ~ accessible_world(X0, X6) | ~ accessible_world(X0, X8) | ~ present(X0, X3) | ~ present(X0, X5) | ~ present(X6, X7) | ~ think_believe_consider(X0, X3) | ~ think_believe_consider(X0, X5) | ~ actual_world(X0) | man(X8, skf4(X8))), file('Problems/NLP/NLP258-1.p', clause94)).
fof(s1, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(lemma_25, lemma, agent(skc12,skf2(skc10),skc10), inference(mp, [status(thm)], [c_141, s1])).
fof(s2, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(lemma_26, lemma, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_138, s2])).
fof(s3, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(s4, plain, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_138, s3])).
fof(lemma_27, lemma, event(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_49, s4])).
fof(lemma_28, lemma, forename(skc8,skc11), inference(mp, [status(thm)], [c_78, c_127])).
fof(lemma_29, lemma, forename(skc8,skc14), inference(mp, [status(thm)], [c_77, c_123])).
fof(s5, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(lemma_30, lemma, present(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_139, s5])).
fof(goal_1, theorem, be(skc8,skc9,skc10,skc10), inference(instantiate, [status(thm)], [c_137])).
fof(s6, plain, man(skc12,skf4(skc12)), inference(mp, [status(thm)], [c_142, c_137, c_134, c_134, lemma_25, c_135, c_135, c_136, c_133, lemma_26, c_124, c_124, lemma_27, c_132, c_132, c_130, c_129, c_121, lemma_28, lemma_29, c_123, c_127, c_131, c_131, c_125, c_125, lemma_30, c_126, c_126, c_120])).
fof(goal_2, theorem, agent(skc12,skf2(skf4(skc12)),skf4(skc12)), inference(mp, [status(thm)], [c_141, s6])).
fof(goal_3, theorem, agent(skc8,skc13,skc15), inference(instantiate, [status(thm)], [c_134])).
fof(goal_4, theorem, agent(skc12,skf2(skc10),skc10), inference(instantiate, [status(thm)], [lemma_25])).
fof(goal_5, theorem, theme(skc8,skc13,skc12), inference(instantiate, [status(thm)], [c_135])).
fof(goal_6, theorem, of(skc8,skc11,skc10), inference(instantiate, [status(thm)], [c_136])).
fof(goal_7, theorem, of(skc8,skc14,skc15), inference(instantiate, [status(thm)], [c_133])).
fof(s7, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(goal_8, theorem, smoke(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [c_138, s7])).
fof(goal_9, theorem, smoke(skc12,skf2(skc10)), inference(instantiate, [status(thm)], [lemma_26])).
fof(goal_10, theorem, event(skc8,skc13), inference(instantiate, [status(thm)], [c_124])).
fof(s8, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(s9, plain, smoke(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [c_138, s8])).
fof(goal_11, theorem, event(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [c_49, s9])).
fof(s10, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(s11, plain, smoke(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_138, s10])).
fof(goal_12, theorem, event(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_49, s11])).
fof(goal_13, theorem, proposition(skc8,skc12), inference(instantiate, [status(thm)], [c_132])).
fof(goal_14, theorem, state(skc8,skc9), inference(instantiate, [status(thm)], [c_130])).
fof(goal_15, theorem, man(skc8,skc10), inference(instantiate, [status(thm)], [c_129])).
fof(goal_16, theorem, man(skc8,skc15), inference(instantiate, [status(thm)], [c_121])).
fof(goal_17, theorem, forename(skc8,skc11), inference(mp, [status(thm)], [c_78, c_127])).
fof(goal_18, theorem, forename(skc8,skc14), inference(mp, [status(thm)], [c_77, c_123])).
fof(goal_19, theorem, vincent_forename(skc8,skc14), inference(instantiate, [status(thm)], [c_123])).
fof(goal_20, theorem, jules_forename(skc8,skc11), inference(instantiate, [status(thm)], [c_127])).
fof(goal_21, theorem, accessible_world(skc8,skc12), inference(instantiate, [status(thm)], [c_131])).
fof(goal_22, theorem, present(skc8,skc13), inference(instantiate, [status(thm)], [c_125])).
fof(s12, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(goal_23, theorem, present(skc12,skf2(skf4(skc12))), inference(mp, [status(thm)], [c_139, s12])).
fof(s13, plain, man(skc12,skc10), inference(mp, [status(thm)], [c_100, c_129, c_131])).
fof(goal_24, theorem, present(skc12,skf2(skc10)), inference(mp, [status(thm)], [c_139, s13])).
fof(goal_25, theorem, think_believe_consider(skc8,skc13), inference(instantiate, [status(thm)], [c_126])).
fof(goal_26, theorem, actual_world(skc8), inference(instantiate, [status(thm)], [c_120])).
% SZS output end Proof
