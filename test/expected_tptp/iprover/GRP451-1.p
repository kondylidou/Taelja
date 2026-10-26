% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2]: divide(divide(divide(X0, X0), divide(X0, divide(X1, divide(divide(divide(X0, X0), X0), X2)))), X2) = X1, file('Problems/GRP/GRP451-1.p', single_axiom)).
fof(c_50, plain, ! [X0, X1, X2]: divide(X0, divide(divide(X1, X1), X2)) = multiply(X0, X2), file('Problems/GRP/GRP451-1.p', multiply)).
fof(c_51, plain, ! [X0, X1]: divide(divide(X0, X0), X1) = inverse(X1), file('Problems/GRP/GRP451-1.p', inverse)).
fof(s1, plain, ! [X,Y] : divide(X,inverse(Y)) = divide(X,divide(divide(X,X),Y)), inference(instantiate, [status(thm)], [c_51])).
fof(lemma_4, lemma, ! [X,Y] : divide(X,inverse(Y)) = multiply(X,Y), inference(rewrite, [status(thm)], [c_50, s1])).
fof(s2, plain, ! [X,Y,Z] : divide(inverse(divide(X,divide(Y,divide(inverse(X),Z)))),Z) = divide(inverse(divide(X,divide(Y,divide(divide(divide(X,X),X),Z)))),Z), inference(instantiate, [status(thm)], [c_51])).
fof(s3, plain, ! [X,Y,Z] : divide(inverse(divide(X,divide(Y,divide(inverse(X),Z)))),Z) = divide(divide(divide(X,X),divide(X,divide(Y,divide(divide(divide(X,X),X),Z)))),Z), inference(rewrite, [status(thm)], [c_51, s2])).
fof(lemma_5, lemma, ! [X,Y,Z] : divide(inverse(divide(X,divide(Y,divide(inverse(X),Z)))),Z) = Y, inference(rewrite, [status(thm)], [c_49, s3])).
fof(lemma_6, lemma, divide(inverse(a1),inverse(a1)) = multiply(inverse(a1),a1), inference(instantiate, [status(thm)], [lemma_4])).
fof(s4, plain, ! [X] : divide(multiply(inverse(a1),a1),X) = divide(divide(inverse(a1),inverse(a1)),X), inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, ! [X] : divide(multiply(inverse(a1),a1),X) = inverse(X), inference(rewrite, [status(thm)], [c_51, s4])).
fof(lemma_8, lemma, divide(inverse(b1),inverse(b1)) = multiply(inverse(b1),b1), inference(instantiate, [status(thm)], [lemma_4])).
fof(s5, plain, ! [X] : divide(multiply(inverse(b1),b1),X) = divide(divide(inverse(b1),inverse(b1)),X), inference(instantiate, [status(thm)], [lemma_8])).
fof(lemma_9, lemma, ! [X] : divide(multiply(inverse(b1),b1),X) = inverse(X), inference(rewrite, [status(thm)], [c_51, s5])).
fof(s6, plain, multiply(inverse(a1),a1) = divide(inverse(divide(a1,divide(multiply(inverse(a1),a1),divide(inverse(a1),a1)))),a1), inference(instantiate, [status(thm)], [lemma_5])).
fof(s7, plain, multiply(inverse(a1),a1) = divide(inverse(divide(a1,inverse(divide(inverse(a1),a1)))),a1), inference(rewrite, [status(thm)], [lemma_7, s6])).
fof(s8, plain, multiply(inverse(a1),a1) = divide(inverse(divide(a1,divide(multiply(inverse(b1),b1),divide(inverse(a1),a1)))),a1), inference(rewrite, [status(thm)], [lemma_9, s7])).
fof(goal_1, theorem, multiply(inverse(a1),a1) = multiply(inverse(b1),b1), inference(rewrite, [status(thm)], [lemma_5, s8])).
% SZS output end Proof
