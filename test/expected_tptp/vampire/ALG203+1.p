% SZS output start Proof
fof(f1, axiom, ! [X0]: (sorti1(X0) => ! [X1]: (sorti1(X1) => sorti1(op1(X0, X1)))), file('Problems/ALG/ALG203+1.p')).
fof(f3, axiom, ? [X0]: (sorti1(X0) & op1(X0, X0) = X0) & ? [X1]: (sorti1(X1) & op1(X1, X1) != X1), file('Problems/ALG/ALG203+1.p')).
fof(f4, axiom, ~ (? [X0]: (sorti2(X0) & op2(X0, X0) = X0) & ? [X1]: (sorti2(X1) & op2(X1, X1) != X1)), file('Problems/ALG/ALG203+1.p')).
fof(f12, definition, ? [X0]: (sorti1(X0) & op1(X0, X0) = X0) => (sorti1(sK0) & sK0 = op1(sK0, sK0)), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f13, definition, ? [X1]: (sorti1(X1) & op1(X1, X1) != X1) => (sorti1(sK1) & sK1 != op1(sK1, sK1)), introduced(definition, [new_symbols(definition, [sK1])], [])).
fof(axiom_1, plain, sorti1(sK1), inference(clausify, [status(thm)], [f3, f13, f12])).
fof(f25, assumption, ! [X] : (sorti1(X) => j(h(X)) = X), introduced(assumption, [], [])).
fof(f24, assumption, ! [Y] : (sorti1(Y) => sorti2(h(Y))), introduced(assumption, [], [])).
fof(axiom_4, plain, sorti1(sK0), inference(clausify, [status(thm)], [f3, f13, f12])).
fof(axiom_5, plain, sK0 = op1(sK0,sK0), inference(clausify, [status(thm)], [f3, f13, f12])).
fof(f28, assumption, ! [Z,A] : ((sorti1(Z) & sorti1(A)) => h(op1(A,Z)) = op2(h(A),h(Z))), introduced(assumption, [], [])).
fof(axiom_9, plain, (sK1 = op1(sK1,sK1) => $false), inference(clausify, [status(thm)], [f3, f13, f12])).
fof(lemma_10, lemma, j(h(sK1)) = sK1, inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(s1, plain, sorti2(h(sK1)), inference(mp, [status(thm), assumptions([f24])], [f24, axiom_1])).
fof(s2, plain, sorti2(h(j(h(sK1)))), inference(rewrite, [status(thm), assumptions([f25, f24])], [lemma_10, s1])).
fof(lemma_11, lemma, sorti2(h(sK1)), inference(rewrite, [status(thm), assumptions([f25, f24])], [lemma_10, s2])).
fof(s3, plain, h(op1(sK0,sK0)) = op2(h(sK0),h(sK0)), inference(mp, [status(thm), assumptions([f28])], [f28, axiom_4, axiom_4])).
fof(lemma_12, lemma, h(sK0) = op2(h(sK0),h(sK0)), inference(rewrite, [status(thm), assumptions([f28])], [axiom_5, s3])).
fof(s4, plain, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f24])], [f24, axiom_4])).
fof(s5, plain, op2(h(sK1),h(sK1)) = h(sK1), inference(mp, [status(thm), assumptions([f24, f28, f25])], [f4, s4, lemma_12, lemma_11])).
fof(lemma_13, lemma, op2(h(j(h(sK1))),h(sK1)) = h(sK1), inference(rewrite, [status(thm), assumptions([f25, f24, f28])], [lemma_10, s5])).
fof(s6, plain, h(op1(sK1,sK1)) = op2(h(sK1),h(sK1)), inference(mp, [status(thm), assumptions([f28])], [f28, axiom_1, axiom_1])).
fof(lemma_14, lemma, h(op1(j(h(sK1)),sK1)) = op2(h(sK1),h(sK1)), inference(rewrite, [status(thm), assumptions([f25, f28])], [lemma_10, s6])).
fof(s7, plain, sorti1(op1(sK1,sK1)), inference(mp, [status(thm)], [f1, axiom_1, axiom_1])).
fof(lemma_15, lemma, j(h(op1(sK1,sK1))) = op1(sK1,sK1), inference(mp, [status(thm), assumptions([f25])], [f25, s7])).
fof(s8, plain, sK1 = j(h(sK1)), inference(instantiate, [status(thm), assumptions([f25])], [lemma_10])).
fof(s9, plain, sK1 = j(op2(h(j(h(sK1))),h(sK1))), inference(rewrite, [status(thm), assumptions([f25, f24, f28])], [lemma_13, s8])).
fof(s10, plain, sK1 = j(op2(h(sK1),h(sK1))), inference(rewrite, [status(thm), assumptions([f25, f24, f28])], [lemma_10, s9])).
fof(s11, plain, sK1 = j(h(op1(j(h(sK1)),sK1))), inference(rewrite, [status(thm), assumptions([f25, f28, f24])], [lemma_14, s10])).
fof(s12, plain, sK1 = j(h(op1(sK1,sK1))), inference(rewrite, [status(thm), assumptions([f25, f28, f24])], [lemma_10, s11])).
fof(lemma_16, lemma, sK1 = op1(sK1,sK1), inference(rewrite, [status(thm), assumptions([f25, f28, f24])], [lemma_15, s12])).
fof(s13, plain, $false, inference(mp, [status(thm), assumptions([f25, f28, f24])], [axiom_9, lemma_16])).
fof(f5, theorem, (! [X0]: (sorti1(X0) => sorti2(h(X0))) & ! [X1]: (sorti2(X1) => sorti1(j(X1)))) => ~ (! [X2]: (sorti1(X2) => ! [X3]: (sorti1(X3) => h(op1(X2, X3)) = op2(h(X2), h(X3)))) & ! [X4]: (sorti2(X4) => ! [X5]: (sorti2(X5) => j(op2(X4, X5)) = op1(j(X4), j(X5)))) & ! [X6]: (sorti2(X6) => h(j(X6)) = X6) & ! [X7]: (sorti1(X7) => j(h(X7)) = X7)), inference(implies, [status(thm), discharge(implies, [f25, f24, f28])], [s13, f25, f24, f28])).
% SZS output end Proof
