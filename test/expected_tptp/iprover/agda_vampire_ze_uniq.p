% SZS output start Proof
fof(f1, axiom, ! [X0]: plus(ze, X0) = X0, file('agda_vampire_ze_uniq.p', neutl)).
fof(f2, axiom, ! [X0]: ze = plus(neg(X0), X0), file('agda_vampire_ze_uniq.p', negl)).
fof(f3, axiom, ! [X0, X1, X2]: plus(plus(X0, X1), X2) = plus(X0, plus(X1, X2)), file('agda_vampire_ze_uniq.p', assoc)).
fof(f7, plain, ? [X0, X1]: (ze != X0 & plus(X0, X1) = X1) => (ze != sK0 & sK1 = plus(sK0, sK1)), introduced(choice_axiom, [new_symbols(definition, [sK0,sK1])], [])).
fof(c_53, assumption, plus(sK0,sK1) = sK1, introduced(assumption, [], [])).
fof(s1, plain, ! [X,Y] : plus(neg(X),plus(X,Y)) = plus(plus(neg(X),X),Y), inference(instantiate, [status(thm)], [f3])).
fof(s2, plain, ! [X,Y] : plus(neg(X),plus(X,Y)) = plus(ze,Y), inference(rewrite, [status(thm)], [f2, s1])).
fof(lemma_5, lemma, ! [X,Y] : plus(neg(X),plus(X,Y)) = Y, inference(rewrite, [status(thm)], [f1, s2])).
fof(s3, plain, ! [X,Y] : plus(neg(neg(X)),Y) = plus(neg(neg(X)),plus(neg(X),plus(X,Y))), inference(instantiate, [status(thm)], [lemma_5])).
fof(lemma_6, lemma, ! [X,Y] : plus(neg(neg(X)),Y) = plus(X,Y), inference(rewrite, [status(thm)], [lemma_5, s3])).
fof(s4, plain, ! [X] : plus(X,neg(X)) = plus(neg(neg(X)),neg(X)), inference(instantiate, [status(thm)], [lemma_6])).
fof(lemma_7, lemma, ! [X] : plus(X,neg(X)) = ze, inference(rewrite, [status(thm)], [f2, s4])).
fof(lemma_8, lemma, plus(sK0,plus(sK0,sK1)) = plus(sK0,sK1), inference(instantiate, [status(thm), assumptions([c_53])], [c_53])).
fof(s5, plain, ze = plus(neg(neg(plus(sK0,sK1))),neg(plus(sK0,sK1))), inference(instantiate, [status(thm)], [f2])).
fof(s6, plain, ze = plus(plus(sK0,sK1),neg(plus(sK0,sK1))), inference(rewrite, [status(thm)], [lemma_6, s5])).
fof(s7, plain, ze = plus(plus(sK0,plus(sK0,sK1)),neg(plus(sK0,sK1))), inference(rewrite, [status(thm), assumptions([c_53])], [lemma_8, s6])).
fof(s8, plain, ze = plus(sK0,plus(plus(sK0,sK1),neg(plus(sK0,sK1)))), inference(rewrite, [status(thm), assumptions([c_53])], [f3, s7])).
fof(s9, plain, ze = plus(sK0,ze), inference(rewrite, [status(thm), assumptions([c_53])], [lemma_7, s8])).
fof(s10, plain, ze = plus(neg(neg(sK0)),ze), inference(rewrite, [status(thm), assumptions([c_53])], [lemma_6, s9])).
fof(s11, plain, ze = plus(neg(neg(sK0)),plus(neg(sK0),sK0)), inference(rewrite, [status(thm), assumptions([c_53])], [f2, s10])).
fof(s12, plain, ze = sK0, inference(rewrite, [status(thm), assumptions([c_53])], [lemma_5, s11])).
fof(discharged, plain, (plus(sK0,sK1) = sK1 => ze = sK0), inference(implies, [status(thm), discharge(implies, [c_53])], [s12, c_53])).
fof(f4, theorem, ! [X0, X1]: (plus(X0, X1) = X1 => ze = X0), inference(generalization, [status(thm)], [discharged, f7])).
% SZS output end Proof
