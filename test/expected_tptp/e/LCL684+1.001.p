% SZS output start Proof
fof(reflexivity, axiom, ! [X1]: r1(X1, X1), file('Problems/LCL/LCL684+1.001.p', reflexivity)).
fof(c_0_9, assumption, p201(esk1_0), introduced(assumption, [], [])).
fof(c_0_8, assumption, p101(esk1_0), introduced(assumption, [], [])).
fof(c_0_5, assumption, ! [X,Y] : ((r1(esk1_0,X) & r1(X,Y) & p201(Y) & p101(Y)) => $false), introduced(assumption, [], [])).
fof(s1, plain, r1(esk1_0,esk1_0), inference(instantiate, [status(thm)], [reflexivity])).
fof(s2, plain, r1(esk1_0,esk1_0), inference(instantiate, [status(thm)], [reflexivity])).
fof(s3, plain, $false, inference(mp, [status(thm), assumptions([c_0_5, c_0_9, c_0_8])], [c_0_5, s1, s2, c_0_9, c_0_8])).
fof(main, theorem, ~ ? [X1]: ~ (~ ! [X2]: (~ r1(X1, X2) | ! [X1]: (~ r1(X2, X1) | ~ (p201(X1) & p101(X1)))) | ~ (p201(X1) & p101(X1))), inference(implies, [status(thm), discharge(implies, [c_0_9, c_0_8, c_0_5])], [s3, c_0_9, c_0_8, c_0_5])).
% SZS output end Proof
