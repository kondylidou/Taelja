% SZS output start Proof
cnf(counting1, axiom, p(X1, X2, X3, X4, X5, X6, X7, one) | ~ p(X1, X2, X3, X4, X5, X6, X7, zero), file('test/input/counting_binary.p', counting1)).
cnf(counting2, axiom, p(X1, X2, X3, X4, X5, X6, one, zero) | ~ p(X1, X2, X3, X4, X5, X6, zero, one), file('test/input/counting_binary.p', counting2)).
cnf(start, axiom, p(zero, zero, zero, zero, zero, zero, zero, zero), file('test/input/counting_binary.p', start)).
cnf(counting3, axiom, p(X1, X2, X3, X4, X5, one, zero, zero) | ~ p(X1, X2, X3, X4, X5, zero, one, one), file('test/input/counting_binary.p', counting3)).
cnf(counting4, axiom, p(X1, X2, X3, X4, one, zero, zero, zero) | ~ p(X1, X2, X3, X4, zero, one, one, one), file('test/input/counting_binary.p', counting4)).
cnf(counting5, axiom, p(X1, X2, X3, one, zero, zero, zero, zero) | ~ p(X1, X2, X3, zero, one, one, one, one), file('test/input/counting_binary.p', counting5)).
cnf(counting6, axiom, p(X1, X2, one, zero, zero, zero, zero, zero) | ~ p(X1, X2, zero, one, one, one, one, one), file('test/input/counting_binary.p', counting6)).
cnf(counting7, axiom, p(X1, one, zero, zero, zero, zero, zero, zero) | ~ p(X1, zero, one, one, one, one, one, one), file('test/input/counting_binary.p', counting7)).
cnf(counting8, axiom, p(one, zero, zero, zero, zero, zero, zero, zero) | ~ p(zero, one, one, one, one, one, one, one), file('test/input/counting_binary.p', counting8)).
fof(s1, plain, ! [X,Y,Z,A,B,C] : (p(X,Y,Z,A,B,C,zero,zero) => p(X,Y,Z,A,B,C,zero,zero)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y,Z,A,B,C] : (p(X,Y,Z,A,B,C,zero,zero) => p(X,Y,Z,A,B,C,zero,one)), inference(mp, [status(thm)], [counting1, s1])).
fof(s3, plain, ! [X,Y,Z,A,B,C] : (p(X,Y,Z,A,B,C,zero,zero) => p(X,Y,Z,A,B,C,one,zero)), inference(mp, [status(thm)], [counting2, s2])).
fof(lemma_10, lemma, ! [X,Y,Z,A,B,C] : (p(X,Y,Z,A,B,C,zero,zero) => p(X,Y,Z,A,B,C,one,one)), inference(mp, [status(thm)], [counting1, s3])).
fof(s4, plain, ! [X,Y,Z,A,B] : (p(X,Y,Z,A,B,zero,zero,zero) => p(X,Y,Z,A,B,zero,zero,zero)), inference(assumption, [status(thm)], [])).
fof(s5, plain, ! [X,Y,Z,A,B] : (p(X,Y,Z,A,B,zero,zero,zero) => p(X,Y,Z,A,B,zero,one,one)), inference(mp, [status(thm)], [lemma_10, s4])).
fof(s6, plain, ! [X,Y,Z,A,B] : (p(X,Y,Z,A,B,zero,zero,zero) => p(X,Y,Z,A,B,one,zero,zero)), inference(mp, [status(thm)], [counting3, s5])).
fof(lemma_11, lemma, ! [X,Y,Z,A,B] : (p(X,Y,Z,A,B,zero,zero,zero) => p(X,Y,Z,A,B,one,one,one)), inference(mp, [status(thm)], [lemma_10, s6])).
fof(s7, plain, ! [X,Y,Z,A] : (p(X,Y,Z,A,zero,zero,zero,zero) => p(X,Y,Z,A,zero,zero,zero,zero)), inference(assumption, [status(thm)], [])).
fof(s8, plain, ! [X,Y,Z,A] : (p(X,Y,Z,A,zero,zero,zero,zero) => p(X,Y,Z,A,zero,one,one,one)), inference(mp, [status(thm)], [lemma_11, s7])).
fof(s9, plain, ! [X,Y,Z,A] : (p(X,Y,Z,A,zero,zero,zero,zero) => p(X,Y,Z,A,one,zero,zero,zero)), inference(mp, [status(thm)], [counting4, s8])).
fof(lemma_12, lemma, ! [X,Y,Z,A] : (p(X,Y,Z,A,zero,zero,zero,zero) => p(X,Y,Z,A,one,one,one,one)), inference(mp, [status(thm)], [lemma_11, s9])).
fof(s10, plain, ! [X,Y,Z] : (p(X,Y,Z,zero,zero,zero,zero,zero) => p(X,Y,Z,zero,zero,zero,zero,zero)), inference(assumption, [status(thm)], [])).
fof(s11, plain, ! [X,Y,Z] : (p(X,Y,Z,zero,zero,zero,zero,zero) => p(X,Y,Z,zero,one,one,one,one)), inference(mp, [status(thm)], [lemma_12, s10])).
fof(s12, plain, ! [X,Y,Z] : (p(X,Y,Z,zero,zero,zero,zero,zero) => p(X,Y,Z,one,zero,zero,zero,zero)), inference(mp, [status(thm)], [counting5, s11])).
fof(lemma_13, lemma, ! [X,Y,Z] : (p(X,Y,Z,zero,zero,zero,zero,zero) => p(X,Y,Z,one,one,one,one,one)), inference(mp, [status(thm)], [lemma_12, s12])).
fof(s13, plain, ! [X,Y] : (p(X,Y,zero,zero,zero,zero,zero,zero) => p(X,Y,zero,zero,zero,zero,zero,zero)), inference(assumption, [status(thm)], [])).
fof(s14, plain, ! [X,Y] : (p(X,Y,zero,zero,zero,zero,zero,zero) => p(X,Y,zero,one,one,one,one,one)), inference(mp, [status(thm)], [lemma_13, s13])).
fof(s15, plain, ! [X,Y] : (p(X,Y,zero,zero,zero,zero,zero,zero) => p(X,Y,one,zero,zero,zero,zero,zero)), inference(mp, [status(thm)], [counting6, s14])).
fof(lemma_14, lemma, ! [X,Y] : (p(X,Y,zero,zero,zero,zero,zero,zero) => p(X,Y,one,one,one,one,one,one)), inference(mp, [status(thm)], [lemma_13, s15])).
fof(s16, plain, p(zero,zero,zero,zero,zero,zero,zero,one), inference(mp, [status(thm)], [counting1, start])).
fof(s17, plain, p(zero,zero,zero,zero,zero,zero,one,zero), inference(mp, [status(thm)], [counting2, s16])).
fof(s18, plain, p(zero,zero,zero,zero,zero,zero,one,one), inference(mp, [status(thm)], [counting1, s17])).
fof(s19, plain, p(zero,zero,zero,zero,zero,one,zero,zero), inference(mp, [status(thm)], [counting3, s18])).
fof(s20, plain, p(zero,zero,zero,zero,zero,one,one,one), inference(mp, [status(thm)], [lemma_10, s19])).
fof(s21, plain, p(zero,zero,zero,zero,one,zero,zero,zero), inference(mp, [status(thm)], [counting4, s20])).
fof(s22, plain, p(zero,zero,zero,zero,one,one,one,one), inference(mp, [status(thm)], [lemma_11, s21])).
fof(s23, plain, p(zero,zero,zero,one,zero,zero,zero,zero), inference(mp, [status(thm)], [counting5, s22])).
fof(s24, plain, p(zero,zero,zero,one,one,one,one,one), inference(mp, [status(thm)], [lemma_12, s23])).
fof(s25, plain, p(zero,zero,one,zero,zero,zero,zero,zero), inference(mp, [status(thm)], [counting6, s24])).
fof(s26, plain, p(zero,zero,one,one,one,one,one,one), inference(mp, [status(thm)], [lemma_13, s25])).
fof(s27, plain, p(zero,one,zero,zero,zero,zero,zero,zero), inference(mp, [status(thm)], [counting7, s26])).
fof(s28, plain, p(zero,one,one,one,one,one,one,one), inference(mp, [status(thm)], [lemma_14, s27])).
fof(s29, plain, p(one,zero,zero,zero,zero,zero,zero,zero), inference(mp, [status(thm)], [counting8, s28])).
fof(s30, plain, p(one,zero,one,one,one,one,one,one), inference(mp, [status(thm)], [lemma_14, s29])).
fof(s31, plain, p(one,one,zero,zero,zero,zero,zero,zero), inference(mp, [status(thm)], [counting7, s30])).
fof(s32, plain, p(one,one,zero,one,one,one,one,one), inference(mp, [status(thm)], [lemma_13, s31])).
fof(s33, plain, p(one,one,one,zero,zero,zero,zero,zero), inference(mp, [status(thm)], [counting6, s32])).
fof(s34, plain, p(one,one,one,zero,one,one,one,one), inference(mp, [status(thm)], [lemma_12, s33])).
fof(s35, plain, p(one,one,one,one,zero,zero,zero,zero), inference(mp, [status(thm)], [counting5, s34])).
fof(s36, plain, p(one,one,one,one,zero,one,one,one), inference(mp, [status(thm)], [lemma_11, s35])).
fof(s37, plain, p(one,one,one,one,one,zero,zero,zero), inference(mp, [status(thm)], [counting4, s36])).
fof(s38, plain, p(one,one,one,one,one,zero,one,one), inference(mp, [status(thm)], [lemma_10, s37])).
fof(s39, plain, p(one,one,one,one,one,one,zero,zero), inference(mp, [status(thm)], [counting3, s38])).
fof(s40, plain, p(one,one,one,one,one,one,zero,one), inference(mp, [status(thm)], [counting1, s39])).
fof(s41, plain, p(one,one,one,one,one,one,one,zero), inference(mp, [status(thm)], [counting2, s40])).
fof(goal_1, theorem, p(one,one,one,one,one,one,one,one), inference(mp, [status(thm)], [counting1, s41])).
% SZS output end Proof
