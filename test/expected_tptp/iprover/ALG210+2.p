% SZS output start Proof
fof(f1, axiom, ! [X0, X1, X2]: times(times(X0, X1), X2) = times(X1, times(X2, X0)), file('Problems/ALG/ALG210+2.p', axiom_1)).
fof(f2, axiom, ! [X1]: (element(X1) <=> ? [X2]: (times(X1, X1) = X2 & times(X1, X2) = X1)), file('Problems/ALG/ALG210+2.p', axiom_2)).
fof(f10, plain, ! [X0]: (? [X2]: (times(X0, X0) = X2 & times(X0, X2) = X0) => (times(X0, X0) = sK0(X0) & times(X0, sK0(X0)) = X0)), introduced(choice_axiom, [new_symbols(definition, [sK0])], [])).
fof(f12, plain, ? [X0, X1, X2]: (~ element(X2) & times(X0, X1) = X2 & element(X1) & element(X0)) => (~ element(sK3) & sK3 = times(sK1, sK2) & element(sK2) & element(sK1)), introduced(choice_axiom, [new_symbols(definition, [sK3,sK1,sK2])], [])).
fof(c_54, assumption, times(sK1,sK2) = sK3, introduced(assumption, [], [])).
fof(c_55, assumption, element(sK2), introduced(assumption, [], [])).
fof(axiom_3, plain, ! [X] : (element(X) => times(X,X) = sK0(X)), inference(clausify, [status(thm)], [f2, f10])).
fof(axiom_5, plain, ! [X] : (element(X) => times(X,sK0(X)) = X), inference(clausify, [status(thm)], [f2, f10])).
fof(c_56, assumption, element(sK1), introduced(assumption, [], [])).
fof(axiom_7, plain, ! [X,Y] : ((times(X,X) = Y & times(X,Y) = X) => element(X)), inference(clausify, [status(thm)], [f2, f10])).
fof(s1, plain, ! [X] : times(sK2,times(X,sK1)) = times(times(sK1,sK2),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_8, lemma, ! [X] : times(sK2,times(X,sK1)) = times(sK3,X), inference(rewrite, [status(thm), assumptions([c_54])], [c_54, s1])).
fof(lemma_9, lemma, times(sK2,sK2) = sK0(sK2), inference(mp, [status(thm), assumptions([c_55])], [axiom_3, c_55])).
fof(s2, plain, ! [X,Y,Z,A] : times(X,times(Y,times(Z,A))) = times(times(times(Z,A),X),Y), inference(instantiate, [status(thm)], [f1])).
fof(s3, plain, ! [X,Y,Z,A] : times(X,times(Y,times(Z,A))) = times(times(A,times(X,Z)),Y), inference(rewrite, [status(thm)], [f1, s2])).
fof(s4, plain, ! [X,Y,Z,A] : times(X,times(Y,times(Z,A))) = times(times(X,Z),times(Y,A)), inference(rewrite, [status(thm)], [f1, s3])).
fof(s5, plain, ! [X,Y,Z,A] : times(X,times(Y,times(Z,A))) = times(Z,times(times(Y,A),X)), inference(rewrite, [status(thm)], [f1, s4])).
fof(lemma_10, lemma, ! [X,Y,Z,A] : times(X,times(Y,times(Z,A))) = times(Z,times(A,times(X,Y))), inference(rewrite, [status(thm)], [f1, s5])).
fof(s6, plain, ! [X,Y] : times(sK1,times(sK2,times(X,Y))) = times(X,times(Y,times(sK1,sK2))), inference(instantiate, [status(thm)], [lemma_10])).
fof(lemma_11, lemma, ! [X,Y] : times(sK1,times(sK2,times(X,Y))) = times(X,times(Y,sK3)), inference(rewrite, [status(thm), assumptions([c_54])], [c_54, s6])).
fof(lemma_12, lemma, times(sK1,sK1) = sK0(sK1), inference(mp, [status(thm), assumptions([c_56])], [axiom_3, c_56])).
fof(s7, plain, ! [X] : times(sK1,times(X,sK1)) = times(times(sK1,sK1),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_13, lemma, ! [X] : times(sK1,times(X,sK1)) = times(sK0(sK1),X), inference(rewrite, [status(thm), assumptions([c_56])], [lemma_12, s7])).
fof(lemma_14, lemma, times(sK1,sK0(sK1)) = sK1, inference(mp, [status(thm), assumptions([c_56])], [axiom_5, c_56])).
fof(s8, plain, times(sK0(sK1),sK1) = times(sK1,times(sK1,sK1)), inference(instantiate, [status(thm), assumptions([c_56])], [lemma_13])).
fof(s9, plain, times(sK0(sK1),sK1) = times(sK1,sK0(sK1)), inference(rewrite, [status(thm), assumptions([c_56])], [lemma_12, s8])).
fof(lemma_15, lemma, times(sK0(sK1),sK1) = sK1, inference(rewrite, [status(thm), assumptions([c_56])], [lemma_14, s9])).
fof(s10, plain, ! [X] : times(sK1,times(X,sK0(sK1))) = times(times(sK0(sK1),sK1),X), inference(instantiate, [status(thm)], [f1])).
fof(lemma_16, lemma, ! [X] : times(sK1,times(X,sK0(sK1))) = times(sK1,X), inference(rewrite, [status(thm), assumptions([c_56])], [lemma_15, s10])).
fof(lemma_17, lemma, times(sK2,sK0(sK2)) = sK2, inference(mp, [status(thm), assumptions([c_55])], [axiom_5, c_55])).
fof(s11, plain, times(sK2,times(sK2,sK3)) = times(sK1,times(sK2,times(sK2,sK2))), inference(instantiate, [status(thm), assumptions([c_54])], [lemma_11])).
fof(s12, plain, times(sK2,times(sK2,sK3)) = times(sK1,times(sK2,sK0(sK2))), inference(rewrite, [status(thm), assumptions([c_55, c_54])], [lemma_9, s11])).
fof(s13, plain, times(sK2,times(sK2,sK3)) = times(sK1,sK2), inference(rewrite, [status(thm), assumptions([c_55, c_54])], [lemma_17, s12])).
fof(lemma_18, lemma, times(sK2,times(sK2,sK3)) = sK3, inference(rewrite, [status(thm), assumptions([c_54, c_55])], [c_54, s13])).
fof(s14, plain, times(sK2,times(sK3,sK3)) = times(sK1,times(sK2,times(sK2,sK3))), inference(instantiate, [status(thm), assumptions([c_54])], [lemma_11])).
fof(lemma_19, lemma, times(sK2,times(sK3,sK3)) = times(sK1,sK3), inference(rewrite, [status(thm), assumptions([c_54, c_55])], [lemma_18, s14])).
fof(s15, plain, times(sK3,sK1) = times(sK3,times(sK1,sK0(sK1))), inference(instantiate, [status(thm), assumptions([c_56])], [lemma_14])).
fof(s16, plain, times(sK3,sK1) = times(sK2,times(times(sK1,sK0(sK1)),sK1)), inference(rewrite, [status(thm), assumptions([c_54, c_56])], [lemma_8, s15])).
fof(s17, plain, times(sK3,sK1) = times(sK2,times(sK0(sK1),times(sK1,sK1))), inference(rewrite, [status(thm), assumptions([c_54, c_56])], [f1, s16])).
fof(s18, plain, times(sK3,sK1) = times(sK1,times(sK1,times(sK2,sK0(sK1)))), inference(rewrite, [status(thm), assumptions([c_54, c_56])], [lemma_10, s17])).
fof(s19, plain, times(sK3,sK1) = times(sK1,times(sK1,sK2)), inference(rewrite, [status(thm), assumptions([c_56, c_54])], [lemma_16, s18])).
fof(lemma_20, lemma, times(sK3,sK1) = times(sK1,sK3), inference(rewrite, [status(thm), assumptions([c_54, c_56])], [c_54, s19])).
fof(s20, plain, times(sK2,sK0(sK1)) = times(sK2,times(sK1,sK1)), inference(instantiate, [status(thm), assumptions([c_56])], [lemma_12])).
fof(lemma_21, lemma, times(sK2,sK0(sK1)) = times(sK3,sK1), inference(rewrite, [status(thm), assumptions([c_54, c_56])], [lemma_8, s20])).
fof(s21, plain, times(sK3,times(sK3,sK3)) = times(sK1,times(sK2,times(sK3,sK3))), inference(instantiate, [status(thm), assumptions([c_54])], [lemma_11])).
fof(s22, plain, times(sK3,times(sK3,sK3)) = times(sK1,times(sK1,sK3)), inference(rewrite, [status(thm), assumptions([c_54, c_55])], [lemma_19, s21])).
fof(s23, plain, times(sK3,times(sK3,sK3)) = times(sK1,times(sK3,sK1)), inference(rewrite, [status(thm), assumptions([c_54, c_56, c_55])], [lemma_20, s22])).
fof(s24, plain, times(sK3,times(sK3,sK3)) = times(sK1,times(sK2,sK0(sK1))), inference(rewrite, [status(thm), assumptions([c_54, c_56, c_55])], [lemma_21, s23])).
fof(s25, plain, times(sK3,times(sK3,sK3)) = times(sK1,sK2), inference(rewrite, [status(thm), assumptions([c_56, c_54, c_55])], [lemma_16, s24])).
fof(lemma_22, lemma, times(sK3,times(sK3,sK3)) = sK3, inference(rewrite, [status(thm), assumptions([c_54, c_56, c_55])], [c_54, s25])).
fof(s26, plain, element(sK3), inference(mp, [status(thm), assumptions([c_54, c_56, c_55])], [axiom_7, lemma_22])).
fof(discharged, plain, ((times(sK1,sK2) = sK3 & element(sK2) & element(sK1)) => element(sK3)), inference(implies, [status(thm), discharge(implies, [c_54, c_55, c_56])], [s26, c_54, c_55, c_56])).
fof(f3, theorem, ! [X0, X1, X2]: ((times(X0, X1) = X2 & element(X1) & element(X0)) => element(X2)), inference(generalization, [status(thm)], [discharged, f12])).
% SZS output end Proof
