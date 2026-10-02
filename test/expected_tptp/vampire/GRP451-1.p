% SZS output start Proof
fof(f1, axiom, ! [X2, X0, X1]: divide(divide(divide(X0, X0), divide(X0, divide(X1, divide(divide(divide(X0, X0), X0), X2)))), X2) = X1, file('Problems/GRP/GRP451-1.p')).
fof(f2, axiom, ! [X2, X0, X1]: multiply(X0, X1) = divide(X0, divide(divide(X2, X2), X1)), file('Problems/GRP/GRP451-1.p')).
fof(f3, axiom, ! [X0, X1]: inverse(X0) = divide(divide(X1, X1), X0), file('Problems/GRP/GRP451-1.p')).
fof(s1, plain, ! [X,Y] : multiply(X,Y) = divide(X,divide(divide(X,X),Y)), inference(instantiate, [status(thm)], [f2])).
fof(lemma_4, lemma, ! [X,Y] : multiply(X,Y) = divide(X,inverse(Y)), inference(rewrite, [status(thm)], [f3, s1])).
fof(s2, plain, ! [X,Y,Z] : divide(X,X) = divide(divide(divide(Y,Y),divide(Y,divide(divide(X,X),divide(divide(divide(Y,Y),Y),Z)))),Z), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, ! [X,Y,Z] : divide(X,X) = divide(inverse(divide(Y,divide(divide(X,X),divide(divide(divide(Y,Y),Y),Z)))),Z), inference(rewrite, [status(thm)], [f3, s2])).
fof(s4, plain, ! [X,Y,Z] : divide(X,X) = divide(inverse(divide(Y,divide(divide(X,X),divide(inverse(Y),Z)))),Z), inference(rewrite, [status(thm)], [f3, s3])).
fof(s5, plain, ! [X,Y,Z] : divide(X,X) = divide(inverse(divide(Y,inverse(divide(inverse(Y),Z)))),Z), inference(rewrite, [status(thm)], [f3, s4])).
fof(lemma_5, lemma, ! [X,Y,Z] : divide(X,X) = divide(inverse(multiply(Y,divide(inverse(Y),Z))),Z), inference(rewrite, [status(thm)], [lemma_4, s5])).
fof(s6, plain, ! [X,Y] : divide(X,X) = divide(inverse(multiply(inverse(Y),divide(inverse(inverse(Y)),inverse(Y)))),inverse(Y)), inference(instantiate, [status(thm)], [lemma_5])).
fof(s7, plain, ! [X,Y] : divide(X,X) = divide(inverse(Y),inverse(Y)), inference(rewrite, [status(thm)], [lemma_5, s6])).
fof(lemma_6, lemma, ! [X,Y] : divide(X,X) = multiply(inverse(Y),Y), inference(rewrite, [status(thm)], [lemma_4, s7])).
fof(s8, plain, ! [X] : multiply(inverse(a1),a1) = divide(X,X), inference(instantiate, [status(thm)], [lemma_6])).
fof(goal_1, theorem, multiply(inverse(a1),a1) = multiply(inverse(b1),b1), inference(rewrite, [status(thm)], [lemma_6, s8])).
% SZS output end Proof
