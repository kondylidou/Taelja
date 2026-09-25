% SZS output start Proof
fof(c_0_5, assumption, r1(esk1_0,esk4_0), introduced(assumption, [], [])).
fof(c_0_4, assumption, ! [X] : (r1(esk1_0,X) => p2(X)), introduced(assumption, [], [])).
fof(c_0_3, assumption, (p2(esk4_0) => $false), introduced(assumption, [], [])).
fof(s1, plain, p2(esk4_0), inference(mp, [status(thm), assumptions([c_0_4, c_0_5])], [c_0_4, c_0_5])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c_0_3, c_0_4, c_0_5])], [c_0_3, s1])).
fof(main, theorem, ~ ? [X1]: ~ (~ ! [X2]: (~ r1(X1, X2) | p6(X2)) | ~ ! [X2]: (~ r1(X1, X2) | p2(X2)) | ~ ! [X2]: (~ r1(X1, X2) | p4(X2)) | ~ ! [X2]: (~ r1(X1, X2) | p2(X2)) | ! [X2]: (~ r1(X1, X2) | p5(X2)) | ! [X2]: (~ r1(X1, X2) | p3(X2)) | ! [X2]: (~ r1(X1, X2) | p2(X2)) | ! [X2]: (~ r1(X1, X2) | p1(X2))), inference(implies, [status(thm), discharge(implies, [c_0_5, c_0_4, c_0_3])], [s2, c_0_5, c_0_4, c_0_3])).
% SZS output end Proof
