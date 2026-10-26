% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: mult(X1, ld(X1, X0)) = X0, file('GRP656+1.p', f01)).
fof(f2, axiom, ! [X0, X1]: ld(X1, mult(X1, X0)) = X0, file('GRP656+1.p', f02)).
fof(f3, axiom, ! [X0, X1]: mult(rd(X1, X0), X0) = X1, file('GRP656+1.p', f03)).
fof(f4, axiom, ! [X0, X1]: rd(mult(X1, X0), X0) = X1, file('GRP656+1.p', f04)).
fof(f5, axiom, ! [X2, X0, X1]: mult(mult(X1, X0), mult(X2, X1)) = mult(mult(X1, mult(X0, X2)), X1), file('GRP656+1.p', f05)).
fof(f11, plain, ! [X0]: (? [X1]: (mult(X0, X1) != X1 | mult(X1, X0) != X1) => (sK0(X0) != mult(X0, sK0(X0)) | sK0(X0) != mult(sK0(X0), X0))), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(s1, plain, ! [X,Y,Z] : mult(mult(X,rd(Y,rd(Z,X))),Z) = mult(mult(X,rd(Y,rd(Z,X))),mult(rd(Z,X),X)), inference(instantiate, [status(thm)], [f3])).
fof(s2, plain, ! [X,Y,Z] : mult(mult(X,rd(Y,rd(Z,X))),Z) = mult(mult(X,mult(rd(Y,rd(Z,X)),rd(Z,X))),X), inference(rewrite, [status(thm)], [f5, s1])).
fof(lemma_6, lemma, ! [X,Y,Z] : mult(mult(X,rd(Y,rd(Z,X))),Z) = mult(mult(X,Y),X), inference(rewrite, [status(thm)], [f3, s2])).
fof(s3, plain, ! [X,Y,Z] : mult(mult(X,Y),mult(ld(Y,Z),X)) = mult(mult(X,mult(Y,ld(Y,Z))),X), inference(instantiate, [status(thm)], [f5])).
fof(lemma_7, lemma, ! [X,Y,Z] : mult(mult(X,Y),mult(ld(Y,Z),X)) = mult(mult(X,Z),X), inference(rewrite, [status(thm)], [f1, s3])).
fof(s4, plain, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = rd(mult(mult(X,rd(Y,rd(X,X))),X),X), inference(instantiate, [status(thm)], [f4])).
fof(s5, plain, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = rd(mult(mult(X,Y),X),X), inference(rewrite, [status(thm)], [lemma_6, s4])).
fof(s6, plain, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = rd(mult(mult(X,X),mult(ld(X,Y),X)),X), inference(rewrite, [status(thm)], [lemma_7, s5])).
fof(s7, plain, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = rd(mult(mult(X,mult(X,ld(X,Y))),X),X), inference(rewrite, [status(thm)], [f5, s6])).
fof(s8, plain, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = mult(X,mult(X,ld(X,Y))), inference(rewrite, [status(thm)], [f4, s7])).
fof(lemma_8, lemma, ! [X,Y] : mult(X,rd(Y,rd(X,X))) = mult(X,Y), inference(rewrite, [status(thm)], [f1, s8])).
fof(s9, plain, ! [X,Y] : rd(X,rd(Y,Y)) = ld(Y,mult(Y,rd(X,rd(Y,Y)))), inference(instantiate, [status(thm)], [f2])).
fof(s10, plain, ! [X,Y] : rd(X,rd(Y,Y)) = ld(Y,mult(Y,X)), inference(rewrite, [status(thm)], [lemma_8, s9])).
fof(lemma_9, lemma, ! [X,Y] : rd(X,rd(Y,Y)) = X, inference(rewrite, [status(thm)], [f2, s10])).
fof(s11, plain, ! [X,Y] : ld(X,X) = ld(rd(X,rd(Y,Y)),X), inference(instantiate, [status(thm)], [lemma_9])).
fof(s12, plain, ! [X,Y] : ld(X,X) = ld(rd(X,rd(Y,Y)),mult(rd(X,rd(Y,Y)),rd(Y,Y))), inference(rewrite, [status(thm)], [f3, s11])).
fof(lemma_10, lemma, ! [X,Y] : ld(X,X) = rd(Y,Y), inference(rewrite, [status(thm)], [f2, s12])).
fof(s13, plain, ! [X,Y] : mult(rd(X,X),sK0(rd(X,X))) = mult(ld(Y,Y),sK0(rd(X,X))), inference(instantiate, [status(thm)], [lemma_10])).
fof(s14, plain, ! [X] : mult(rd(X,X),sK0(rd(X,X))) = mult(rd(sK0(rd(X,X)),sK0(rd(X,X))),sK0(rd(X,X))), inference(rewrite, [status(thm)], [lemma_10, s13])).
fof(s15, plain, ! [X] : mult(rd(X,X),sK0(rd(X,X))) = sK0(rd(X,X)), inference(rewrite, [status(thm)], [f3, s14])).
fof(s16, plain, ! [X] : mult(sK0(rd(X,X)),rd(X,X)) = mult(rd(sK0(rd(X,X)),rd(X,X)),rd(X,X)), inference(instantiate, [status(thm)], [lemma_9])).
fof(s17, plain, ! [X] : mult(sK0(rd(X,X)),rd(X,X)) = sK0(rd(X,X)), inference(rewrite, [status(thm)], [f3, s16])).
fof(discharged, plain, (! [X] : mult(rd(X,X),sK0(rd(X,X))) = sK0(rd(X,X)) & ! [Y] : mult(sK0(rd(Y,Y)),rd(Y,Y)) = sK0(rd(Y,Y))), inference(conclude, [status(thm)], [s15, s17])).
fof(f6, theorem, ? [X3]: ! [X4]: (mult(X3, X4) = X4 & mult(X4, X3) = X4), inference(generalization, [status(thm)], [discharged, f11])).
% SZS output end Proof
