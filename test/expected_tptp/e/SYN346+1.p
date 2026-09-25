% SZS output start Proof
fof(c_0_4, assumption, ! [X,Y] : big_f(X,esk3_2(X,Y)), introduced(assumption, [], [])).
fof(c_0_3, assumption, ! [X,Y] : ((big_f(esk1_0,esk3_2(X,Y)) & big_f(Y,esk3_2(X,Y))) => $false), introduced(assumption, [], [])).
fof(s1, plain, big_f(esk1_0,esk3_2(esk1_0,esk1_0)), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s2, plain, big_f(esk1_0,esk3_2(esk1_0,esk1_0)), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s3, plain, $false, inference(mp, [status(thm), assumptions([c_0_3, c_0_4])], [c_0_3, s1, s2])).
fof(church_46_17_2, theorem, ! [X1, X2]: ? [X3, X4]: ! [X5, X6]: (big_f(X2, X5) => (big_f(X3, X6) => ((big_f(X3, X5) & big_f(X4, X5)) | (big_f(X2, X6) & big_f(X4, X6))))), inference(implies, [status(thm), discharge(implies, [c_0_4, c_0_3])], [s3, c_0_4, c_0_3])).
% SZS output end Proof
