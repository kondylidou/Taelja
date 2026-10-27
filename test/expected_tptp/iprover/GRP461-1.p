% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2]: divide(X0, divide(divide(divide(identity, X1), X2), divide(divide(divide(X0, X0), X0), X2))) = X1, file('Problems/GRP/GRP461-1.p', single_axiom)).
fof(c_50, plain, ! [X0, X1]: divide(X0, divide(identity, X1)) = multiply(X0, X1), file('Problems/GRP/GRP461-1.p', multiply)).
fof(c_51, plain, ! [X0]: divide(identity, X0) = inverse(X0), file('Problems/GRP/GRP461-1.p', inverse)).
fof(c_52, plain, ! [X0]: divide(X0, X0) = identity, file('Problems/GRP/GRP461-1.p', identity)).
fof(s1, plain, ! [X,Y,Z] : divide(X,divide(divide(inverse(Y),Z),divide(inverse(X),Z))) = divide(X,divide(divide(divide(identity,Y),Z),divide(inverse(X),Z))), inference(instantiate, [status(thm)], [c_51])).
fof(s2, plain, ! [X,Y,Z] : divide(X,divide(divide(inverse(Y),Z),divide(inverse(X),Z))) = divide(X,divide(divide(divide(identity,Y),Z),divide(divide(identity,X),Z))), inference(rewrite, [status(thm)], [c_51, s1])).
fof(s3, plain, ! [X,Y,Z] : divide(X,divide(divide(inverse(Y),Z),divide(inverse(X),Z))) = divide(X,divide(divide(divide(identity,Y),Z),divide(divide(divide(X,X),X),Z))), inference(rewrite, [status(thm)], [c_52, s2])).
fof(lemma_5, lemma, ! [X,Y,Z] : divide(X,divide(divide(inverse(Y),Z),divide(inverse(X),Z))) = Y, inference(rewrite, [status(thm)], [c_49, s3])).
fof(s4, plain, ! [X] : divide(X,identity) = divide(X,divide(divide(inverse(X),X),divide(inverse(X),X))), inference(instantiate, [status(thm)], [c_52])).
fof(lemma_6, lemma, ! [X] : divide(X,identity) = X, inference(rewrite, [status(thm)], [lemma_5, s4])).
fof(s5, plain, ! [X,Y] : divide(X,inverse(Y)) = divide(X,divide(identity,Y)), inference(instantiate, [status(thm)], [c_51])).
fof(lemma_7, lemma, ! [X,Y] : divide(X,inverse(Y)) = multiply(X,Y), inference(rewrite, [status(thm)], [c_50, s5])).
fof(s6, plain, inverse(identity) = divide(identity,identity), inference(instantiate, [status(thm)], [c_51])).
fof(lemma_8, lemma, inverse(identity) = identity, inference(rewrite, [status(thm)], [c_52, s6])).
fof(s7, plain, ! [X] : multiply(X,identity) = divide(X,inverse(identity)), inference(instantiate, [status(thm)], [lemma_7])).
fof(s8, plain, ! [X] : multiply(X,identity) = divide(X,identity), inference(rewrite, [status(thm)], [lemma_8, s7])).
fof(lemma_9, lemma, ! [X] : multiply(X,identity) = X, inference(rewrite, [status(thm)], [lemma_6, s8])).
fof(s9, plain, multiply(identity,a2) = divide(identity,inverse(a2)), inference(instantiate, [status(thm)], [lemma_7])).
fof(s10, plain, multiply(identity,a2) = inverse(inverse(a2)), inference(rewrite, [status(thm)], [c_51, s9])).
fof(s11, plain, multiply(identity,a2) = inverse(multiply(inverse(a2),identity)), inference(rewrite, [status(thm)], [lemma_9, s10])).
fof(s12, plain, multiply(identity,a2) = divide(identity,multiply(inverse(a2),identity)), inference(rewrite, [status(thm)], [c_51, s11])).
fof(s13, plain, multiply(identity,a2) = divide(identity,divide(inverse(a2),inverse(identity))), inference(rewrite, [status(thm)], [lemma_7, s12])).
fof(s14, plain, multiply(identity,a2) = divide(identity,divide(divide(inverse(a2),inverse(identity)),identity)), inference(rewrite, [status(thm)], [lemma_6, s13])).
fof(s15, plain, multiply(identity,a2) = divide(identity,divide(divide(inverse(a2),inverse(identity)),divide(inverse(identity),inverse(identity)))), inference(rewrite, [status(thm)], [c_52, s14])).
fof(goal_1, theorem, multiply(identity,a2) = a2, inference(rewrite, [status(thm)], [lemma_5, s15])).
% SZS output end Proof
