% SZS output start Proof
fof(f2, axiom, ! [X0]: (sorti2(X0) => ! [X1]: (sorti2(X1) => sorti2(op2(X0, X1)))), file('Problems/ALG/ALG018+1.p')).
fof(f3, axiom, ? [X0]: (sorti1(X0) & ! [X1]: (sorti1(X1) => op1(X1, X1) = X0)), file('Problems/ALG/ALG018+1.p')).
fof(f4, axiom, ~ ? [X0]: (sorti2(X0) & ! [X1]: (sorti2(X1) => op2(X1, X1) = X0)), file('Problems/ALG/ALG018+1.p')).
fof(f13, definition, ? [X0]: (sorti1(X0) & ! [X1]: (op1(X1, X1) = X0 | ~ sorti1(X1))) => (sorti1(sK0) & ! [X1]: (op1(X1, X1) = sK0 | ~ sorti1(X1))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f15, definition, ! [X0]: (? [X1]: (op2(X1, X1) != X0 & sorti2(X1)) => (op2(sK1(X0), sK1(X0)) != X0 & sorti2(sK1(X0)))), introduced(definition, [new_symbols(definition, [sK1])], [])).
fof(axiom_1, plain, sorti1(sK0), inference(clausify, [status(thm)], [f3, f13])).
fof(f25, assumption, ! [X] : (sorti1(X) => sorti2(h(X))), introduced(assumption, [], [])).
fof(axiom_3, plain, ! [Y] : (sorti2(Y) => sorti2(sK1(Y))), inference(clausify, [status(thm)], [f4, f15])).
fof(f24, assumption, ! [Z] : (sorti2(Z) => sorti1(j(Z))), introduced(assumption, [], [])).
fof(axiom_5, plain, ! [A] : (sorti1(A) => op1(A,A) = sK0), inference(clausify, [status(thm)], [f3, f13])).
fof(f28, assumption, ! [B,C] : ((sorti2(B) & sorti2(C)) => j(op2(C,B)) = op1(j(C),j(B))), introduced(assumption, [], [])).
fof(f27, assumption, ! [U] : (sorti2(U) => h(j(U)) = U), introduced(assumption, [], [])).
fof(axiom_9, plain, ! [Y] : ((op2(sK1(Y),sK1(Y)) = Y & sorti2(Y)) => $false), inference(clausify, [status(thm)], [f4, f15])).
fof(s1, plain, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(lemma_10, lemma, sorti2(sK1(h(sK0))), inference(mp, [status(thm), assumptions([f25])], [axiom_3, s1])).
fof(s2, plain, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(s3, plain, sorti2(sK1(h(sK0))), inference(mp, [status(thm), assumptions([f25])], [axiom_3, s2])).
fof(s4, plain, sorti1(j(sK1(h(sK0)))), inference(mp, [status(thm), assumptions([f24, f25])], [f24, s3])).
fof(lemma_11, lemma, op1(j(sK1(h(sK0))),j(sK1(h(sK0)))) = sK0, inference(mp, [status(thm), assumptions([f24, f25])], [axiom_5, s4])).
fof(s5, plain, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(lemma_12, lemma, sorti2(sK1(h(sK0))), inference(mp, [status(thm), assumptions([f25])], [axiom_3, s5])).
fof(s6, plain, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(s7, plain, sorti2(sK1(h(sK0))), inference(mp, [status(thm), assumptions([f25])], [axiom_3, s6])).
fof(s8, plain, j(op2(sK1(h(sK0)),sK1(h(sK0)))) = op1(j(sK1(h(sK0))),j(sK1(h(sK0)))), inference(mp, [status(thm), assumptions([f28, f25])], [f28, s7, lemma_12])).
fof(lemma_13, lemma, j(op2(sK1(h(op1(j(sK1(h(sK0))),j(sK1(h(sK0)))))),sK1(h(sK0)))) = op1(j(sK1(h(sK0))),j(sK1(h(sK0)))), inference(rewrite, [status(thm), assumptions([f24, f25, f28])], [lemma_11, s8])).
fof(s9, plain, sK0 = op1(j(sK1(h(sK0))),j(sK1(h(sK0)))), inference(instantiate, [status(thm), assumptions([f24, f25])], [lemma_11])).
fof(s10, plain, sK0 = j(op2(sK1(h(op1(j(sK1(h(sK0))),j(sK1(h(sK0)))))),sK1(h(sK0)))), inference(rewrite, [status(thm), assumptions([f24, f25, f28])], [lemma_13, s9])).
fof(lemma_14, lemma, sK0 = j(op2(sK1(h(sK0)),sK1(h(sK0)))), inference(rewrite, [status(thm), assumptions([f24, f25, f28])], [lemma_11, s10])).
fof(s11, plain, sorti2(op2(sK1(h(sK0)),sK1(h(sK0)))), inference(mp, [status(thm), assumptions([f25])], [f2, lemma_10, lemma_10])).
fof(s12, plain, sorti2(op2(sK1(h(j(op2(sK1(h(sK0)),sK1(h(sK0)))))),sK1(h(sK0)))), inference(rewrite, [status(thm), assumptions([f24, f25, f28])], [lemma_14, s11])).
fof(s13, plain, sorti2(op2(sK1(h(sK0)),sK1(h(sK0)))), inference(rewrite, [status(thm), assumptions([f24, f25, f28])], [lemma_14, s12])).
fof(s14, plain, h(j(op2(sK1(h(sK0)),sK1(h(sK0))))) = op2(sK1(h(sK0)),sK1(h(sK0))), inference(mp, [status(thm), assumptions([f27, f24, f25, f28])], [f27, s13])).
fof(lemma_15, lemma, h(j(op2(sK1(h(j(op2(sK1(h(sK0)),sK1(h(sK0)))))),sK1(h(sK0))))) = op2(sK1(h(sK0)),sK1(h(sK0))), inference(rewrite, [status(thm), assumptions([f24, f25, f28, f27])], [lemma_14, s14])).
fof(s15, plain, op2(sK1(h(sK0)),sK1(h(sK0))) = h(j(op2(sK1(h(j(op2(sK1(h(sK0)),sK1(h(sK0)))))),sK1(h(sK0))))), inference(instantiate, [status(thm), assumptions([f24, f25, f28, f27])], [lemma_15])).
fof(s16, plain, op2(sK1(h(sK0)),sK1(h(sK0))) = h(j(op2(sK1(h(sK0)),sK1(h(sK0))))), inference(rewrite, [status(thm), assumptions([f24, f25, f28, f27])], [lemma_14, s15])).
fof(lemma_16, lemma, op2(sK1(h(sK0)),sK1(h(sK0))) = h(sK0), inference(rewrite, [status(thm), assumptions([f24, f25, f28, f27])], [lemma_14, s16])).
fof(lemma_17, lemma, sorti2(h(sK0)), inference(mp, [status(thm), assumptions([f25])], [f25, axiom_1])).
fof(s17, plain, $false, inference(mp, [status(thm), assumptions([f24, f25, f28, f27])], [axiom_9, lemma_16, lemma_17])).
fof(f5, theorem, (! [X0]: (sorti1(X0) => sorti2(h(X0))) & ! [X1]: (sorti2(X1) => sorti1(j(X1)))) => ~ (! [X2]: (sorti1(X2) => ! [X3]: (sorti1(X3) => h(op1(X2, X3)) = op2(h(X2), h(X3)))) & ! [X4]: (sorti2(X4) => ! [X5]: (sorti2(X5) => j(op2(X4, X5)) = op1(j(X4), j(X5)))) & ! [X6]: (sorti2(X6) => h(j(X6)) = X6) & ! [X7]: (sorti1(X7) => j(h(X7)) = X7)), inference(implies, [status(thm), discharge(implies, [f25, f24, f28, f27])], [s17, f25, f24, f28, f27])).
% SZS output end Proof
