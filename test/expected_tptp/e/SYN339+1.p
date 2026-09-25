% SZS output start Proof
fof(c_0_4, assumption, ! [X,Y] : big_f(X,esk1_1(X),Y), introduced(assumption, [], [])).
fof(c_0_3, assumption, ! [X,Y] : (big_f(esk1_1(X),Y,Y) => $false), introduced(assumption, [], [])).
fof(s1, plain, ! [X] : big_f(esk1_1(X),esk1_1(esk1_1(X)),esk1_1(esk1_1(X))), inference(instantiate, [status(thm), assumptions([c_0_4])], [c_0_4])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c_0_3, c_0_4])], [c_0_3, s1])).
fof(church_46_15_4, theorem, ? [X1]: ! [X2]: ? [X3]: (big_f(X1, X2, X3) => big_f(X2, X3, X3)), inference(implies, [status(thm), discharge(implies, [c_0_4, c_0_3])], [s2, c_0_4, c_0_3])).
% SZS output end Proof
