% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: mult(X1, ld(X1, X0)) = X0, file('GRP658+1.p', f01)).
fof(f3, axiom, ! [X0, X1]: mult(rd(X1, X0), X0) = X1, file('GRP658+1.p', f03)).
fof(f4, axiom, ! [X0, X1]: rd(mult(X1, X0), X0) = X1, file('GRP658+1.p', f04)).
fof(f5, axiom, ! [X2, X0, X1]: mult(mult(X1, mult(X0, X0)), X2) = mult(mult(X1, X0), mult(X0, X2)), file('GRP658+1.p', f05)).
fof(f11, plain, ! [X0]: (? [X1]: (mult(X0, X1) != X1 | mult(X1, X0) != X1) => (sK0(X0) != mult(X0, sK0(X0)) | sK0(X0) != mult(sK0(X0), X0))), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(s1, plain, ! [X,Y,Z] : mult(mult(rd(X,mult(Y,Y)),Y),mult(Y,Z)) = mult(mult(rd(X,mult(Y,Y)),mult(Y,Y)),Z), inference(instantiate, [status(thm)], [f5])).
fof(lemma_5, lemma, ! [X,Y,Z] : mult(mult(rd(X,mult(Y,Y)),Y),mult(Y,Z)) = mult(X,Z), inference(rewrite, [status(thm)], [f3, s1])).
fof(s2, plain, ! [X,Y,Z] : mult(mult(rd(X,mult(Y,Y)),Y),Z) = mult(mult(rd(X,mult(Y,Y)),Y),mult(Y,ld(Y,Z))), inference(instantiate, [status(thm)], [f1])).
fof(lemma_6, lemma, ! [X,Y,Z] : mult(mult(rd(X,mult(Y,Y)),Y),Z) = mult(X,ld(Y,Z)), inference(rewrite, [status(thm)], [lemma_5, s2])).
fof(s3, plain, ! [X,Y] : mult(rd(X,mult(X,X)),X) = rd(mult(mult(rd(X,mult(X,X)),X),Y),Y), inference(instantiate, [status(thm)], [f4])).
fof(s4, plain, ! [X,Y] : mult(rd(X,mult(X,X)),X) = rd(mult(X,ld(X,Y)),Y), inference(rewrite, [status(thm)], [lemma_6, s3])).
fof(lemma_7, lemma, ! [X,Y] : mult(rd(X,mult(X,X)),X) = rd(Y,Y), inference(rewrite, [status(thm)], [f1, s4])).
fof(s5, plain, ! [X] : rd(X,X) = mult(rd(X,mult(X,X)),X), inference(instantiate, [status(thm)], [lemma_7])).
fof(lemma_8, lemma, ! [X,Y] : rd(X,X) = rd(Y,Y), inference(rewrite, [status(thm)], [lemma_7, s5])).
fof(s6, plain, ! [X,Y] : mult(rd(X,X),Y) = mult(rd(Y,Y),Y), inference(instantiate, [status(thm)], [lemma_8])).
fof(lemma_9, lemma, ! [X,Y] : mult(rd(X,X),Y) = Y, inference(rewrite, [status(thm)], [f3, s6])).
fof(s7, plain, ! [X,Y,Z] : mult(rd(rd(X,Y),mult(Z,Z)),Z) = rd(mult(mult(rd(rd(X,Y),mult(Z,Z)),Z),mult(Z,Y)),mult(Z,Y)), inference(instantiate, [status(thm)], [f4])).
fof(s8, plain, ! [X,Y,Z] : mult(rd(rd(X,Y),mult(Z,Z)),Z) = rd(mult(rd(X,Y),Y),mult(Z,Y)), inference(rewrite, [status(thm)], [lemma_5, s7])).
fof(lemma_10, lemma, ! [X,Y,Z] : mult(rd(rd(X,Y),mult(Z,Z)),Z) = rd(X,mult(Z,Y)), inference(rewrite, [status(thm)], [f3, s8])).
fof(s9, plain, ! [X] : ld(X,X) = mult(rd(X,X),ld(X,X)), inference(instantiate, [status(thm)], [lemma_9])).
fof(s10, plain, ! [X] : ld(X,X) = mult(mult(rd(rd(X,X),mult(X,X)),X),X), inference(rewrite, [status(thm)], [lemma_6, s9])).
fof(s11, plain, ! [X] : ld(X,X) = mult(rd(X,mult(X,X)),X), inference(rewrite, [status(thm)], [lemma_10, s10])).
fof(lemma_11, lemma, ! [X,Y] : ld(X,X) = rd(Y,Y), inference(rewrite, [status(thm)], [lemma_7, s11])).
fof(s12, plain, ! [X] : mult(rd(X,X),sK0(rd(X,X))) = sK0(rd(X,X)), inference(instantiate, [status(thm)], [lemma_9])).
fof(s13, plain, ! [X] : mult(sK0(rd(X,X)),rd(X,X)) = mult(sK0(rd(X,X)),ld(sK0(rd(X,X)),sK0(rd(X,X)))), inference(instantiate, [status(thm)], [lemma_11])).
fof(s14, plain, ! [X] : mult(sK0(rd(X,X)),rd(X,X)) = sK0(rd(X,X)), inference(rewrite, [status(thm)], [f1, s13])).
fof(discharged, plain, (! [X] : mult(rd(X,X),sK0(rd(X,X))) = sK0(rd(X,X)) & ! [Y] : mult(sK0(rd(Y,Y)),rd(Y,Y)) = sK0(rd(Y,Y))), inference(conclude, [status(thm)], [s12, s14])).
fof(f6, theorem, ? [X3]: ! [X4]: (mult(X3, X4) = X4 & mult(X4, X3) = X4), inference(generalization, [status(thm)], [discharged, f11])).
% SZS output end Proof
