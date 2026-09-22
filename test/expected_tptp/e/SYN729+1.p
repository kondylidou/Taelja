% SZS output start Proof
fof(c_0_5, assumption, p(esk2_0), introduced(assumption, [], [])).
fof(c_0_11, assumption, ! [Y] : (p(Y) => p(esk1_1(Y))), introduced(assumption, [], [])).
fof(c_0_9, assumption, ! [Y] : (p(Y) => p(h(Y))), introduced(assumption, [], [])).
fof(c_0_7, assumption, ! [Y] : (p(Y) => p(g(Y))), introduced(assumption, [], [])).
fof(c_0_4, assumption, ! [Y] : (p(Y) => l(Y,g(h(esk1_1(Y))))), introduced(assumption, [], [])).
fof(s1, plain, p(esk2_0), inference(instantiate, [status(thm), assumptions([c_0_5])], [c_0_5])).
fof(s2, plain, l(esk2_0,g(h(esk1_1(esk2_0)))), inference(mp, [status(thm), assumptions([c_0_4, c_0_5])], [c_0_4, s1])).
fof(s3, plain, p(esk2_0), inference(instantiate, [status(thm), assumptions([c_0_5])], [c_0_5])).
fof(s4, plain, p(esk1_1(esk2_0)), inference(mp, [status(thm), assumptions([c_0_11, c_0_5])], [c_0_11, s3])).
fof(s5, plain, p(h(esk1_1(esk2_0))), inference(mp, [status(thm), assumptions([c_0_9, c_0_11, c_0_5])], [c_0_9, s4])).
fof(s6, plain, p(g(h(esk1_1(esk2_0)))), inference(mp, [status(thm), assumptions([c_0_7, c_0_9, c_0_11, c_0_5])], [c_0_7, s5])).
fof(discharged, plain, ((p(esk2_0) & ! [Y] : (p(Y) => p(esk1_1(Y))) & ! [Y] : (p(Y) => p(h(Y))) & ! [Y] : (p(Y) => p(g(Y))) & ! [Y] : (p(Y) => l(Y,g(h(esk1_1(Y)))))) => (l(esk2_0,g(h(esk1_1(esk2_0)))) & p(g(h(esk1_1(esk2_0)))))), inference(implies, [status(thm), discharge(implies, [c_0_5, c_0_11, c_0_9, c_0_7, c_0_4])], [s2, s6, c_0_5, c_0_11, c_0_9, c_0_7, c_0_4])).
fof(thm72, theorem, (! [X1]: ? [X2]: (p(X1) => (l(X1, g(h(X2))) & p(X2))) & ! [X3]: (p(X3) => (p(g(X3)) & p(h(X3))))) => ! [X1]: (p(X1) => ? [X2]: (l(X1, X2) & p(X2))), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
