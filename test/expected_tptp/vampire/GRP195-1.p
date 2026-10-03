% SZS output start Proof
fof(f1, axiom, ! [X2, X0, X1]: multiply(multiply(X0, X1), X2) = multiply(X0, multiply(X1, X2)), file('Problems/GRP/GRP195-1.p')).
fof(f2, axiom, ! [X0, X1]: multiply(X0, multiply(X1, X1)) = multiply(X1, multiply(X1, X0)), file('Problems/GRP/GRP195-1.p')).
fof(s1, plain, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Y,Z))) = multiply(X,multiply(multiply(Y,Y),Z)), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Y,Z))) = multiply(multiply(X,multiply(Y,Y)),Z), inference(rewrite, [status(thm)], [f1, s1])).
fof(s3, plain, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Y,Z))) = multiply(multiply(Y,multiply(Y,X)),Z), inference(rewrite, [status(thm)], [f2, s2])).
fof(s4, plain, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Y,Z))) = multiply(Y,multiply(multiply(Y,X),Z)), inference(rewrite, [status(thm)], [f1, s3])).
fof(lemma_3, lemma, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Y,Z))) = multiply(Y,multiply(Y,multiply(X,Z))), inference(rewrite, [status(thm)], [f1, s4])).
fof(s5, plain, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Z,Z))) = multiply(multiply(X,Y),multiply(Z,Z)), inference(instantiate, [status(thm)], [f1])).
fof(lemma_4, lemma, ! [X,Y,Z] : multiply(X,multiply(Y,multiply(Z,Z))) = multiply(Z,multiply(Z,multiply(X,Y))), inference(rewrite, [status(thm)], [f2, s5])).
fof(s6, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(b,multiply(a,multiply(b,multiply(multiply(a,b),multiply(a,b)))))), inference(instantiate, [status(thm)], [f1])).
fof(s7, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(b,multiply(a,multiply(multiply(a,b),multiply(multiply(a,b),b))))), inference(rewrite, [status(thm)], [f2, s6])).
fof(s8, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(b,multiply(a,multiply(multiply(a,b),multiply(a,multiply(b,b)))))), inference(rewrite, [status(thm)], [f1, s7])).
fof(s9, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(b,multiply(a,multiply(a,multiply(b,multiply(a,multiply(b,b))))))), inference(rewrite, [status(thm)], [f1, s8])).
fof(s10, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(b,multiply(multiply(a,a),multiply(b,multiply(a,multiply(b,b)))))), inference(rewrite, [status(thm)], [f1, s9])).
fof(s11, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(multiply(b,multiply(a,a)),multiply(b,multiply(a,multiply(b,b))))), inference(rewrite, [status(thm)], [f1, s10])).
fof(s12, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(multiply(a,multiply(b,multiply(a,a))),multiply(b,multiply(a,multiply(b,b)))), inference(rewrite, [status(thm)], [f1, s11])).
fof(s13, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(multiply(a,multiply(a,multiply(a,b))),multiply(b,multiply(a,multiply(b,b)))), inference(rewrite, [status(thm)], [lemma_4, s12])).
fof(s14, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(multiply(a,multiply(a,b)),multiply(b,multiply(a,multiply(b,b))))), inference(rewrite, [status(thm)], [f1, s13])).
fof(s15, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(a,multiply(multiply(a,b),multiply(b,multiply(a,multiply(b,b)))))), inference(rewrite, [status(thm)], [f1, s14])).
fof(s16, plain, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(a,multiply(a,multiply(b,multiply(b,multiply(a,multiply(b,b))))))), inference(rewrite, [status(thm)], [f1, s15])).
fof(goal_1, theorem, multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,multiply(b,multiply(a,b))))))) = multiply(a,multiply(a,multiply(a,multiply(a,multiply(b,multiply(b,multiply(b,b))))))), inference(rewrite, [status(thm)], [lemma_3, s16])).
% SZS output end Proof
