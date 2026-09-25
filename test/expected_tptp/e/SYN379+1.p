% SZS output start Proof
fof(c_0_4, assumption, ! [X,Y,Z] : big_q(X,Y,Z), introduced(assumption, [], [])).
fof(c_0_3, assumption, ! [X,Y] : (big_q(X,X,Y) => $false), introduced(assumption, [], [])).
fof(s1, plain, ! [X,Y] : big_q(X,X,Y), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c_0_3, c_0_4])], [c_0_3, s1])).
fof(x2131, theorem, ! [X1]: big_p(X1) => ? [X2]: (! [X1, X3]: big_q(X1, X2, X3) => ~ ! [X3]: (big_p(X3) & ~ big_q(X2, X2, X3))), inference(implies, [status(thm), discharge(implies, [c_0_4, c_0_3])], [s2, c_0_4, c_0_3])).
% SZS output end Proof
