% SZS output start Proof
fof(c_0_4, assumption, ! [X] : p(X), introduced(assumption, [], [])).
fof(c_0_3, assumption, (p(esk2_0) => $false), introduced(assumption, [], [])).
fof(s1, plain, p(esk2_0), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c_0_3, c_0_4])], [c_0_3, s1])).
fof(prove_this, theorem, (! [X1]: p(X1) & ? [X2]: q(X2)) => ? [X3]: ! [X2]: (p(X2) | r(X3)), inference(implies, [status(thm), discharge(implies, [c_0_4, c_0_3])], [s2, c_0_4, c_0_3])).
% SZS output end Proof
