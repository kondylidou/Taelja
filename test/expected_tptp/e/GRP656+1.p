% SZS output start Proof
fof(skolem_definition, definition, ! [X4]: (? [X5]: ~ mult(X5, X4) = X5 => ~ mult(esk1_1(X4), X4) = esk1_1(X4)), introduced(definition, [new_symbols(definition, [esk1_1])], [])).
fof(skolem_definition_2, definition, ! [X4]: (? [X5]: ~ mult(X4, X5) = X5 => ~ mult(X4, esk2_1(X4)) = esk2_1(X4)), introduced(definition, [new_symbols(definition, [esk2_1])], [])).
fof(f04, axiom, ! [X1, X2]: rd(mult(X2, X1), X1) = X2, file('Problems/GRP/GRP656+1.p', f04)).
fof(f05, axiom, ! [X3, X1, X2]: mult(mult(X2, X1), mult(X3, X2)) = mult(mult(X2, mult(X1, X3)), X2), file('Problems/GRP/GRP656+1.p', f05)).
fof(f03, axiom, ! [X1, X2]: mult(rd(X2, X1), X1) = X2, file('Problems/GRP/GRP656+1.p', f03)).
fof(f02, axiom, ! [X1, X2]: ld(X2, mult(X2, X1)) = X1, file('Problems/GRP/GRP656+1.p', f02)).
fof(s1, plain, ! [X,Y] : mult(X,mult(Y,rd(X,X))) = rd(mult(mult(X,mult(Y,rd(X,X))),X),X), inference(instantiate, [status(thm)], [f04])).
fof(s2, plain, ! [X,Y] : mult(X,mult(Y,rd(X,X))) = rd(mult(mult(X,Y),mult(rd(X,X),X)),X), inference(rewrite, [status(thm)], [f05, s1])).
fof(s3, plain, ! [X,Y] : mult(X,mult(Y,rd(X,X))) = rd(mult(mult(X,Y),X),X), inference(rewrite, [status(thm)], [f03, s2])).
fof(lemma_5, lemma, ! [X,Y] : mult(X,mult(Y,rd(X,X))) = mult(X,Y), inference(rewrite, [status(thm)], [f04, s3])).
fof(s4, plain, ! [X,Y] : mult(X,rd(Y,Y)) = ld(Y,mult(Y,mult(X,rd(Y,Y)))), inference(instantiate, [status(thm)], [f02])).
fof(s5, plain, ! [X,Y] : mult(X,rd(Y,Y)) = ld(Y,mult(Y,X)), inference(rewrite, [status(thm)], [lemma_5, s4])).
fof(lemma_6, lemma, ! [X,Y] : mult(X,rd(Y,Y)) = X, inference(rewrite, [status(thm)], [f02, s5])).
fof(s6, plain, ! [X,Y] : ld(X,X) = ld(X,mult(X,rd(Y,Y))), inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, ! [X,Y] : ld(X,X) = rd(Y,Y), inference(rewrite, [status(thm)], [f02, s6])).
fof(s7, plain, ! [X] : mult(esk1_1(rd(X,X)),rd(X,X)) = esk1_1(rd(X,X)), inference(instantiate, [status(thm)], [lemma_6])).
fof(s8, plain, ! [X] : mult(rd(X,X),esk2_1(rd(X,X))) = mult(ld(X,X),esk2_1(rd(X,X))), inference(instantiate, [status(thm)], [lemma_7])).
fof(s9, plain, ! [X] : mult(rd(X,X),esk2_1(rd(X,X))) = mult(rd(esk2_1(rd(X,X)),esk2_1(rd(X,X))),esk2_1(rd(X,X))), inference(rewrite, [status(thm)], [lemma_7, s8])).
fof(s10, plain, ! [X] : mult(rd(X,X),esk2_1(rd(X,X))) = esk2_1(rd(X,X)), inference(rewrite, [status(thm)], [f03, s9])).
fof(discharged, plain, (! [Y] : mult(esk1_1(rd(Y,Y)),rd(Y,Y)) = esk1_1(rd(Y,Y)) & ! [X] : mult(rd(X,X),esk2_1(rd(X,X))) = esk2_1(rd(X,X))), inference(conclude, [status(thm)], [s7, s10])).
fof(goals, theorem, ? [X4]: ! [X5]: (mult(X5, X4) = X5 & mult(X4, X5) = X5), inference(generalization, [status(thm)], [discharged, skolem_definition, skolem_definition_2])).
% SZS output end Proof
