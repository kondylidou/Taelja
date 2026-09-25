% SZS output start Proof
fof(c_0_3, assumption, big_q(esk1_0), introduced(assumption, [], [])).
fof(c_0_4, assumption, ! [X] : (big_q(X) => $false), introduced(assumption, [], [])).
fof(s1, plain, $false, inference(mp, [status(thm), assumptions([c_0_4, c_0_3])], [c_0_4, c_0_3])).
fof(x2130, theorem, ! [X1]: big_p(X1) => (~ ? [X2]: big_q(X2) | ? [X3]: (big_p(X3) => big_q(X3))), inference(implies, [status(thm), discharge(implies, [c_0_3, c_0_4])], [s1, c_0_3, c_0_4])).
% SZS output end Proof
