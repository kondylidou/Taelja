% SZS output start Proof
fof(f1, axiom, ! [X0]: plus(ze, X0) = X0, file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/ze_uniq.p')).
fof(f2, axiom, ! [X0]: plus(neg(X0), X0) = ze, file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/ze_uniq.p')).
fof(f3, axiom, ! [X0, X1, X2]: plus(plus(X0, X1), X2) = plus(X0, plus(X1, X2)), file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/ze_uniq.p')).
fof(f7, definition, ? [X0, X1]: (ze != X0 & plus(X0, X1) = X1) => (ze != sK0 & sK1 = plus(sK0, sK1)), introduced(definition, [new_symbols(definition, [sK0,sK1])], [])).
fof(f12, assumption, sK1 = plus(sK0,sK1), introduced(assumption, [], [])).
fof(s1, plain, ! [X,Y] : plus(neg(X),plus(X,Y)) = plus(plus(neg(X),X),Y), inference(instantiate, [status(thm)], [f3])).
fof(s2, plain, ! [X,Y] : plus(neg(X),plus(X,Y)) = plus(ze,Y), inference(rewrite, [status(thm)], [f2, s1])).
fof(lemma_5, lemma, ! [X,Y] : plus(neg(X),plus(X,Y)) = Y, inference(rewrite, [status(thm)], [f1, s2])).
fof(s3, plain, ! [X,Y] : plus(X,Y) = plus(neg(neg(X)),plus(neg(X),plus(X,Y))), inference(instantiate, [status(thm)], [lemma_5])).
fof(lemma_6, lemma, ! [X,Y] : plus(X,Y) = plus(neg(neg(X)),Y), inference(rewrite, [status(thm)], [lemma_5, s3])).
fof(s4, plain, sK1 = plus(neg(plus(neg(sK1),sK0)),plus(plus(neg(sK1),sK0),sK1)), inference(instantiate, [status(thm)], [lemma_5])).
fof(s5, plain, sK1 = plus(neg(plus(neg(sK1),sK0)),plus(neg(sK1),plus(sK0,sK1))), inference(rewrite, [status(thm)], [f3, s4])).
fof(s6, plain, sK1 = plus(neg(plus(neg(sK1),sK0)),plus(neg(sK1),sK1)), inference(rewrite, [status(thm), assumptions([f12])], [f12, s5])).
fof(s7, plain, sK1 = plus(neg(plus(neg(sK1),sK0)),ze), inference(rewrite, [status(thm), assumptions([f12])], [f2, s6])).
fof(s8, plain, sK1 = plus(neg(neg(neg(plus(neg(sK1),sK0)))),ze), inference(rewrite, [status(thm), assumptions([f12])], [lemma_6, s7])).
fof(s9, plain, sK1 = plus(neg(neg(neg(plus(neg(sK1),sK0)))),plus(neg(neg(plus(neg(sK1),sK0))),neg(plus(neg(sK1),sK0)))), inference(rewrite, [status(thm), assumptions([f12])], [f2, s8])).
fof(lemma_7, lemma, sK1 = neg(plus(neg(sK1),sK0)), inference(rewrite, [status(thm), assumptions([f12])], [lemma_5, s9])).
fof(s10, plain, sK0 = plus(neg(neg(sK1)),plus(neg(sK1),sK0)), inference(instantiate, [status(thm)], [lemma_5])).
fof(s11, plain, sK0 = plus(sK1,plus(neg(sK1),sK0)), inference(rewrite, [status(thm)], [lemma_6, s10])).
fof(s12, plain, sK0 = plus(neg(plus(neg(sK1),sK0)),plus(neg(sK1),sK0)), inference(rewrite, [status(thm), assumptions([f12])], [lemma_7, s11])).
fof(s13, plain, sK0 = ze, inference(rewrite, [status(thm), assumptions([f12])], [f2, s12])).
fof(discharged, plain, (sK1 = plus(sK0,sK1) => sK0 = ze), inference(implies, [status(thm), discharge(implies, [f12])], [s13, f12])).
fof(f4, theorem, ! [X0, X1]: (plus(X0, X1) = X1 => X0 = ze), inference(generalization, [status(thm)], [discharged, f7])).
% SZS output end Proof
