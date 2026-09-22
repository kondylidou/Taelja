% SZS output start Proof
fof(c_0_6, assumption, big_r(esk1_0), introduced(assumption, [], [])).
fof(c_0_4, assumption, ! [Y] : (big_r(Y) => big_q(Y,esk2_1(Y))), introduced(assumption, [], [])).
fof(c_0_3, assumption, ! [Y,Z] : (big_q(Y,Z) => big_q(Y,Y)), introduced(assumption, [], [])).
fof(s1, plain, big_r(esk1_0), inference(instantiate, [status(thm), assumptions([c_0_6])], [c_0_6])).
fof(s2, plain, big_q(esk1_0,esk2_1(esk1_0)), inference(mp, [status(thm), assumptions([c_0_4, c_0_6])], [c_0_4, s1])).
fof(s3, plain, big_q(esk1_0,esk1_0), inference(mp, [status(thm), assumptions([c_0_3, c_0_4, c_0_6])], [c_0_3, s2])).
fof(s4, plain, big_r(esk1_0), inference(instantiate, [status(thm), assumptions([c_0_6])], [c_0_6])).
fof(discharged, plain, ((big_r(esk1_0) & ! [Y] : (big_r(Y) => big_q(Y,esk2_1(Y))) & ! [Y,Z] : (big_q(Y,Z) => big_q(Y,Y))) => (big_q(esk1_0,esk1_0) & big_r(esk1_0))), inference(implies, [status(thm), discharge(implies, [c_0_6, c_0_4, c_0_3])], [s3, s4, c_0_6, c_0_4, c_0_3])).
fof(x2110, theorem, (? [X1]: big_r(X1) & ! [X2]: (big_r(X2) => ? [X3]: big_q(X2, X3)) & ! [X1, X2]: (big_q(X1, X2) => big_q(X1, X1))) => ? [X1, X2]: (big_q(X1, X2) & big_r(X2)), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
