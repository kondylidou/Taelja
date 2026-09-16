% SZS output start Proof
fof(f1, axiom, ! [X0, X1]: mult(X1, ld(X1, X0)) = X0, file('Problems/GRP/GRP656+1.p')).
fof(f2, axiom, ! [X0, X1]: ld(X1, mult(X1, X0)) = X0, file('Problems/GRP/GRP656+1.p')).
fof(f3, axiom, ! [X0, X1]: mult(rd(X1, X0), X0) = X1, file('Problems/GRP/GRP656+1.p')).
fof(f4, axiom, ! [X0, X1]: rd(mult(X1, X0), X0) = X1, file('Problems/GRP/GRP656+1.p')).
fof(f5, axiom, ! [X0, X1, X2]: mult(mult(X2, X1), mult(X0, X2)) = mult(mult(X2, mult(X1, X0)), X2), file('Problems/GRP/GRP656+1.p')).
fof(f9, definition, ! [X0]: (? [X1]: (mult(X1, X0) != X1 | mult(X0, X1) != X1) => (sK0(X0) != mult(sK0(X0), X0) | sK0(X0) != mult(X0, sK0(X0)))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(s1, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,X),mult(mult(Y,X),mult(ld(X,X),Y))), inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,X),mult(mult(Y,mult(X,ld(X,X))),Y)), inference(rewrite, [status(thm)], [f5, s1])).
fof(s3, plain, ! [X,Y] : mult(ld(X,X),Y) = ld(mult(Y,X),mult(mult(Y,X),Y)), inference(rewrite, [status(thm)], [f1, s2])).
fof(lemma_6, lemma, ! [X,Y] : mult(ld(X,X),Y) = Y, inference(rewrite, [status(thm)], [f2, s3])).
fof(s4, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(mult(sK0(ld(X,X)),ld(X,X)),ld(mult(sK0(ld(X,X)),ld(X,X)),mult(sK0(ld(X,X)),ld(X,X)))),ld(mult(sK0(ld(X,X)),ld(X,X)),mult(sK0(ld(X,X)),ld(X,X)))), inference(instantiate, [status(thm)], [f4])).
fof(s5, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(sK0(ld(X,X)),ld(X,X)),ld(mult(sK0(ld(X,X)),ld(X,X)),mult(sK0(ld(X,X)),ld(X,X)))), inference(rewrite, [status(thm)], [f1, s4])).
fof(s6, plain, ! [X,A] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(sK0(ld(X,X)),ld(X,X)),rd(mult(ld(mult(sK0(ld(X,X)),ld(X,X)),mult(sK0(ld(X,X)),ld(X,X))),A),A)), inference(rewrite, [status(thm)], [f4, s5])).
fof(s7, plain, ! [X,A] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(sK0(ld(X,X)),ld(X,X)),rd(A,A)), inference(rewrite, [status(thm)], [lemma_6, s6])).
fof(s8, plain, ! [X,A] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(sK0(ld(X,X)),ld(X,X)),rd(mult(ld(X,X),A),A)), inference(rewrite, [status(thm)], [lemma_6, s7])).
fof(s9, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = rd(mult(sK0(ld(X,X)),ld(X,X)),ld(X,X)), inference(rewrite, [status(thm)], [f4, s8])).
fof(s10, plain, ! [X] : mult(sK0(ld(X,X)),ld(X,X)) = sK0(ld(X,X)), inference(rewrite, [status(thm)], [f4, s9])).
fof(s11, plain, ! [X] : mult(ld(X,X),sK0(ld(X,X))) = sK0(ld(X,X)), inference(instantiate, [status(thm)], [lemma_6])).
fof(discharged, plain, (! [Y] : mult(sK0(ld(Y,Y)),ld(Y,Y)) = sK0(ld(Y,Y)) & ! [X] : mult(ld(X,X),sK0(ld(X,X))) = sK0(ld(X,X))), inference(conclude, [status(thm)], [s10, s11])).
fof(f6, theorem, ? [X0]: ! [X1]: (mult(X1, X0) = X1 & mult(X0, X1) = X1), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
