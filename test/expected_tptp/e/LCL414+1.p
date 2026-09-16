% SZS output start Proof
fof(c_0_7, assumption, ! [X,Y] : a_truth(implies(X,implies(Y,X))), introduced(assumption, [], [])).
fof(c_0_4, assumption, ! [X,Y,Z] : a_truth(implies(implies(X,implies(Y,Z)),implies(implies(X,Y),implies(X,Z)))), introduced(assumption, [], [])).
fof(c_0_3, assumption, ! [X,Y] : ((a_truth(implies(X,Y)) & a_truth(X)) => a_truth(Y)), introduced(assumption, [], [])).
fof(s1, plain, ! [X] : a_truth(implies(implies(esk1_0,implies(implies(X,esk1_0),esk1_0)),implies(implies(esk1_0,implies(X,esk1_0)),implies(esk1_0,esk1_0)))), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s2, plain, ! [X] : a_truth(implies(esk1_0,implies(implies(X,esk1_0),esk1_0))), inference(instantiate, [status(thm), assumptions([c_0_7])], [c_0_7])).
fof(s3, plain, ! [X] : a_truth(implies(implies(esk1_0,implies(X,esk1_0)),implies(esk1_0,esk1_0))), inference(mp, [status(thm), assumptions([c_0_3, c_0_4, c_0_7])], [c_0_3, s1, s2])).
fof(s4, plain, ! [X] : a_truth(implies(esk1_0,implies(X,esk1_0))), inference(instantiate, [status(thm), assumptions([c_0_7])], [c_0_7])).
fof(s5, plain, a_truth(implies(esk1_0,esk1_0)), inference(mp, [status(thm), assumptions([c_0_3, c_0_4, c_0_7])], [c_0_3, s3, s4])).
fof(discharged, plain, ((! [X,Y] : a_truth(implies(X,implies(Y,X))) & ! [X,Y,Z] : a_truth(implies(implies(X,implies(Y,Z)),implies(implies(X,Y),implies(X,Z)))) & ! [X,Y] : ((a_truth(implies(X,Y)) & a_truth(X)) => a_truth(Y))) => a_truth(implies(esk1_0,esk1_0))), inference(implies, [status(thm), discharge(implies, [c_0_7, c_0_4, c_0_3])], [s5, c_0_7, c_0_4, c_0_3])).
fof(thm147, theorem, ~ (! [X1, X2]: (~ a_truth(implies(X1, X2)) | ~ a_truth(X1) | a_truth(X2)) & ! [X1, X2]: a_truth(implies(X1, implies(X2, X1))) & ! [X1, X2, X3]: a_truth(implies(implies(X1, implies(X2, X3)), implies(implies(X1, X2), implies(X1, X3)))) & ! [X1, X2]: a_truth(implies(implies(not(X1), not(X2)), implies(X2, X1))) & ? [X4]: ~ a_truth(implies(X4, X4))), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
