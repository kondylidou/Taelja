% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: mult(X1, ld(X1, X0)) = X0, file('Problems/GRP/GRP656+1.p')).
fof(f2, axiom, ! [X0, X1]: ld(X1, mult(X1, X0)) = X0, file('Problems/GRP/GRP656+1.p')).
fof(f3, axiom, ! [X0, X1]: mult(rd(X1, X0), X0) = X1, file('Problems/GRP/GRP656+1.p')).
fof(f4, axiom, ! [X0, X1]: rd(mult(X1, X0), X0) = X1, file('Problems/GRP/GRP656+1.p')).
fof(f5, axiom, ! [X0, X1, X2]: mult(mult(X2, X1), mult(X0, X2)) = mult(mult(X2, mult(X1, X0)), X2), file('Problems/GRP/GRP656+1.p')).
fof(f9, definition, ! [X0]: (? [X1]: (mult(X1, X0) != X1 | mult(X0, X1) != X1) => (sK0(X0) != mult(sK0(X0), X0) | sK0(X0) != mult(X0, sK0(X0)))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(s1, plain, ! [X,Y,Z] : mult(mult(X,Y),mult(ld(Y,Z),X)) = mult(mult(X,mult(Y,ld(Y,Z))),X), inference(instantiate, [status(thm)], [f5])).
fof(lemma_6, lemma, ! [X,Y,Z] : mult(mult(X,Y),mult(ld(Y,Z),X)) = mult(mult(X,Z),X), inference(rewrite, [status(thm)], [f1, s1])).
fof(s2, plain, ! [X,Y,Z] : mult(mult(X,Y),X) = mult(mult(X,mult(rd(Y,Z),Z)),X), inference(instantiate, [status(thm)], [f3])).
fof(lemma_7, lemma, ! [X,Y,Z] : mult(mult(X,Y),X) = mult(mult(X,rd(Y,Z)),mult(Z,X)), inference(rewrite, [status(thm)], [f5, s2])).
fof(s3, plain, ! [X,Y] : mult(ld(X,X),Y) = mult(ld(mult(rd(X,X),X),X),Y), inference(instantiate, [status(thm)], [f3])).
fof(s4, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,mult(rd(X,X),X)),mult(mult(Y,mult(rd(X,X),X)),mult(ld(mult(rd(X,X),X),X),Y))), inference(rewrite, [status(thm)], [f2, s3])).
fof(s5, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,mult(rd(X,X),X)),mult(mult(Y,X),Y)), inference(rewrite, [status(thm)], [lemma_6, s4])).
fof(s6, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,mult(rd(X,X),X)),mult(mult(Y,rd(X,X)),mult(X,Y))), inference(rewrite, [status(thm)], [lemma_7, s5])).
fof(s7, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,mult(rd(X,X),X)),mult(mult(Y,mult(rd(X,X),X)),Y)), inference(rewrite, [status(thm)], [f5, s6])).
fof(lemma_8, lemma, ! [X,Y] : mult(ld(X,X),Y) = Y, inference(rewrite, [status(thm)], [f2, s7])).
fof(s8, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = mult(mult(ld(X,X),sK0(ld(X,X))),ld(X,X)), inference(instantiate, [status(thm)], [lemma_8])).
fof(s9, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = mult(mult(ld(X,X),X),mult(ld(X,sK0(ld(X,X))),ld(X,X))), inference(rewrite, [status(thm)], [lemma_6, s8])).
fof(s10, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = mult(X,mult(ld(X,sK0(ld(X,X))),ld(X,X))), inference(rewrite, [status(thm)], [lemma_8, s9])).
fof(s11, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(mult(X,mult(ld(X,sK0(ld(X,X))),ld(X,X))),X),X), inference(rewrite, [status(thm)], [f4, s10])).
fof(s12, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(mult(X,ld(X,sK0(ld(X,X)))),mult(ld(X,X),X)),X), inference(rewrite, [status(thm)], [f5, s11])).
fof(s13, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(mult(X,ld(X,sK0(ld(X,X)))),X),X), inference(rewrite, [status(thm)], [lemma_8, s12])).
fof(s14, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = mult(X,ld(X,sK0(ld(X,X)))), inference(rewrite, [status(thm)], [f4, s13])).
fof(s15, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = sK0(ld(X,X)), inference(rewrite, [status(thm)], [f1, s14])).
fof(s16, plain, ! [X] : mult(ld(X,X),sK0(ld(X,X))) = sK0(ld(X,X)), inference(instantiate, [status(thm)], [lemma_8])).
fof(discharged, plain, (! [Y] : mult(sK0(ld(Y,Y)),ld(Y,Y)) = sK0(ld(Y,Y)) & ! [X] : mult(ld(X,X),sK0(ld(X,X))) = sK0(ld(X,X))), inference(conclude, [status(thm)], [s15, s16])).
fof(f6, theorem, ? [X0]: ! [X1]: (mult(X1, X0) = X1 & mult(X0, X1) = X1), inference(generalization, [status(thm)], [discharged, f9])).
% SZS output end Proof
