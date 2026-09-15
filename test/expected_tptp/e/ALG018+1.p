% SZS output start Proof
fof(ax3, axiom, ? [X1]: (sorti1(X1) & ! [X2]: (sorti1(X2) => op1(X2, X2) = X1)), file('Problems/ALG/ALG018+1.p', ax3)).
fof(ax2, axiom, ! [X1]: (sorti2(X1) => ! [X2]: (sorti2(X2) => sorti2(op2(X1, X2)))), file('Problems/ALG/ALG018+1.p', ax2)).
fof(ax4, axiom, ~ ? [X1]: (sorti2(X1) & ! [X2]: (sorti2(X2) => op2(X2, X2) = X1)), file('Problems/ALG/ALG018+1.p', ax4)).
fof(axiom_1, plain, sorti1(esk1_0), inference(clausify, [status(thm)], [ax3])).
fof(axiom_2, plain, ! [X] : (sorti1(X) => op1(X,X) = esk1_0), inference(clausify, [status(thm)], [ax3])).
fof(c_0_13, assumption, ! [X] : (sorti1(X) => sorti2(h(X))), introduced(assumption, [], [])).
fof(c_0_12, assumption, ! [X,Y] : ((sorti1(X) & sorti1(Y)) => h(op1(X,Y)) = op2(h(X),h(Y))), introduced(assumption, [], [])).
fof(axiom_6, plain, ! [X] : (sorti2(X) => sorti2(esk2_1(X))), inference(clausify, [status(thm)], [ax4])).
fof(c_0_9, assumption, ! [X,Y] : ((sorti2(X) & sorti2(Y)) => j(op2(X,Y)) = op1(j(X),j(Y))), introduced(assumption, [], [])).
fof(c_0_10, assumption, ! [X] : (sorti2(X) => sorti1(j(X))), introduced(assumption, [], [])).
fof(c_0_14, assumption, ! [X] : (sorti2(X) => h(j(X)) = X), introduced(assumption, [], [])).
fof(axiom_10, plain, ! [X] : ((sorti2(X) & op2(esk2_1(X),esk2_1(X)) = X) => $false), inference(clausify, [status(thm)], [ax4])).
fof(s1, plain, sorti2(h(esk1_0)), inference(mp, [status(thm), assumptions([c_0_13])], [c_0_13, axiom_1])).
fof(lemma_11, lemma, sorti2(esk2_1(h(esk1_0))), inference(mp, [status(thm), assumptions([c_0_13])], [axiom_6, s1])).
fof(s2, plain, sorti2(h(esk1_0)), inference(mp, [status(thm), assumptions([c_0_13])], [c_0_13, axiom_1])).
fof(s3, plain, sorti2(esk2_1(h(esk1_0))), inference(mp, [status(thm), assumptions([c_0_13])], [axiom_6, s2])).
fof(s4, plain, sorti2(op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0)))), inference(mp, [status(thm), assumptions([c_0_13])], [ax2, s3, lemma_11])).
fof(lemma_12, lemma, h(j(op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))))) = op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))), inference(mp, [status(thm), assumptions([c_0_14, c_0_13])], [c_0_14, s4])).
fof(lemma_13, lemma, j(op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0)))) = op1(j(esk2_1(h(esk1_0))),j(esk2_1(h(esk1_0)))), inference(mp, [status(thm), assumptions([c_0_9, c_0_13])], [c_0_9, lemma_11, lemma_11])).
fof(s5, plain, sorti1(j(esk2_1(h(esk1_0)))), inference(mp, [status(thm), assumptions([c_0_10, c_0_13])], [c_0_10, lemma_11])).
fof(lemma_14, lemma, op1(j(esk2_1(h(esk1_0))),j(esk2_1(h(esk1_0)))) = esk1_0, inference(mp, [status(thm), assumptions([c_0_10, c_0_13])], [axiom_2, s5])).
fof(s6, plain, op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))) = h(j(op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))))), inference(instantiate, [status(thm), assumptions([c_0_14, c_0_13])], [lemma_12])).
fof(s7, plain, op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))) = h(op1(j(esk2_1(h(esk1_0))),j(esk2_1(h(esk1_0))))), inference(rewrite, [status(thm), assumptions([c_0_9, c_0_13, c_0_14])], [lemma_13, s6])).
fof(lemma_15, lemma, op2(esk2_1(h(esk1_0)),esk2_1(h(esk1_0))) = h(esk1_0), inference(rewrite, [status(thm), assumptions([c_0_10, c_0_13, c_0_9, c_0_14])], [lemma_14, s7])).
fof(s8, plain, sorti2(h(esk1_0)), inference(mp, [status(thm), assumptions([c_0_13])], [c_0_13, axiom_1])).
fof(s9, plain, $false, inference(mp, [status(thm), assumptions([c_0_13, c_0_10, c_0_9, c_0_14])], [axiom_10, s8, lemma_15])).
fof(co1, theorem, (! [X1]: (sorti1(X1) => sorti2(h(X1))) & ! [X2]: (sorti2(X2) => sorti1(j(X2)))) => ~ (! [X3]: (sorti1(X3) => ! [X4]: (sorti1(X4) => h(op1(X3, X4)) = op2(h(X3), h(X4)))) & ! [X5]: (sorti2(X5) => ! [X6]: (sorti2(X6) => j(op2(X5, X6)) = op1(j(X5), j(X6)))) & ! [X7]: (sorti2(X7) => h(j(X7)) = X7) & ! [X8]: (sorti1(X8) => j(h(X8)) = X8)), inference(implies, [status(thm), discharge(implies, [c_0_13, c_0_12, c_0_9, c_0_10, c_0_14])], [s9, c_0_13, c_0_12, c_0_9, c_0_10, c_0_14])).
% SZS output end Proof
