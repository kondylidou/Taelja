% SZS output start Proof
fof(c12, assumption, ! [X] : big_p(X), introduced(assumption, [], [])).
fof(c8, assumption, ! [Y] : big_r(Y,w(Y)), introduced(assumption, [], [])).
fof(c4, assumption, ! [X] : ((big_r(z,X) & big_p(X)) => $false), introduced(assumption, [], [])).
fof(s1, plain, big_r(z,w(z)), inference(instantiate, [status(thm), assumptions([c8])], [c8])).
fof(s2, plain, big_p(w(z)), inference(instantiate, [status(thm), assumptions([c12])], [c12])).
fof(s3, plain, $false, inference(mp, [status(thm), assumptions([c4, c8, c12])], [c4, s1, s2])).
fof(c1, theorem, (! [Y]: ? [W]: big_r(Y, W) & ? [Z]: ! [X]: (big_p(X) => ~ big_r(Z, X))) => ? [X2]: ~ big_p(X2), inference(implies, [status(thm), discharge(implies, [c12, c8, c4])], [s3, c12, c8, c4])).
% SZS output end Proof
