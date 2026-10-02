% SZS output start Proof
cnf(c2, axiom, sum(X, Y, add(X, Y)), file('TPTP/Problems/BOO/BOO006-1.p', closure_of_addition)).
cnf(c3, axiom, product(inverse(X2), X2, additive_identity), file('TPTP/Problems/BOO/BOO006-1.p', multiplicative_inverse1)).
cnf(c4, axiom, sum(X2, additive_identity, X2), file('TPTP/Problems/BOO/BOO006-1.p', additive_identity2)).
cnf(c5, axiom, product(X2, multiplicative_identity, X2), file('TPTP/Problems/BOO/BOO006-1.p', multiplicative_identity2)).
cnf(c6, axiom, ~ product(X2, Y2, V1) | ~ product(X2, Z, V2) | ~ sum(Y2, Z, V3) | ~ sum(V1, V2, V4) | product(X2, V3, V4), file('TPTP/Problems/BOO/BOO006-1.p', distributivity2)).
cnf(c11, axiom, ~ sum(X2, Y2, Z2) | sum(Y2, X2, Z2), file('TPTP/Problems/BOO/BOO006-1.p', commutativity_of_addition)).
cnf(c13, axiom, ~ sum(X2, Y2, U) | ~ sum(X2, Y2, V) | U = V, file('TPTP/Problems/BOO/BOO006-1.p', addition_is_well_defined)).
cnf(c17, axiom, product(X2, Y2, multiply(X2, Y2)), file('TPTP/Problems/BOO/BOO006-1.p', closure_of_multiplication)).
cnf(c18, axiom, ~ product(X2, Y2, U2) | ~ product(X2, Y2, V5) | U2 = V5, file('TPTP/Problems/BOO/BOO006-1.p', multiplication_is_well_defined)).
cnf(c21, axiom, ~ sum(X2, Y2, V1_2) | ~ sum(X2, Z2, V2_2) | ~ product(Y2, Z2, V3_2) | ~ sum(X2, V3_2, V4_2) | product(V1_2, V2_2, V4_2), file('TPTP/Problems/BOO/BOO006-1.p', distributivity5)).
cnf(c26, axiom, product(multiplicative_identity, X2, X2), file('TPTP/Problems/BOO/BOO006-1.p', multiplicative_identity1)).
cnf(c28, axiom, ~ product(X2, Y2, Z2) | product(Y2, X2, Z2), file('TPTP/Problems/BOO/BOO006-1.p', commutativity_of_multiplication)).
cnf(c41, axiom, sum(additive_identity, X2, X2), file('TPTP/Problems/BOO/BOO006-1.p', additive_identity1)).
cnf(c52, axiom, product(X2, inverse(X2), additive_identity), file('TPTP/Problems/BOO/BOO006-1.p', multiplicative_inverse2)).
cnf(c56, axiom, sum(inverse(X2), X2, multiplicative_identity), file('TPTP/Problems/BOO/BOO006-1.p', additive_inverse1)).
fof(lemma_16, lemma, ! [X,Y] : sum(X,Y,add(Y,X)), inference(mp, [status(thm)], [c11, c2])).
fof(lemma_17, lemma, ! [X,Y] : add(X,Y) = add(Y,X), inference(mp, [status(thm)], [c13, c2, lemma_16])).
fof(lemma_18, lemma, ! [X,Y] : product(X,Y,multiply(Y,X)), inference(mp, [status(thm)], [c28, c17])).
fof(lemma_19, lemma, ! [X,Y] : multiply(X,Y) = multiply(Y,X), inference(mp, [status(thm)], [c18, c17, lemma_18])).
fof(s1, plain, sum(multiplicative_identity,additive_identity,multiplicative_identity), inference(instantiate, [status(thm)], [c4])).
fof(s2, plain, ! [X] : sum(multiplicative_identity,X,add(multiplicative_identity,X)), inference(instantiate, [status(thm)], [c2])).
fof(s3, plain, ! [X] : product(additive_identity,X,multiply(additive_identity,X)), inference(instantiate, [status(thm)], [c17])).
fof(s4, plain, ! [X] : sum(multiplicative_identity,multiply(additive_identity,X),add(multiplicative_identity,multiply(additive_identity,X))), inference(instantiate, [status(thm)], [c2])).
fof(s5, plain, ! [X] : product(multiplicative_identity,add(multiplicative_identity,X),add(multiplicative_identity,multiply(additive_identity,X))), inference(mp, [status(thm)], [c21, s1, s2, s3, s4])).
fof(lemma_20, lemma, ! [X] : product(multiplicative_identity,add(multiplicative_identity,X),add(multiplicative_identity,multiply(X,additive_identity))), inference(rewrite, [status(thm)], [lemma_19, s5])).
fof(s6, plain, ! [X] : product(multiplicative_identity,add(multiplicative_identity,X),add(multiplicative_identity,X)), inference(instantiate, [status(thm)], [c26])).
fof(s7, plain, ! [X] : add(multiplicative_identity,X) = add(multiplicative_identity,multiply(X,additive_identity)), inference(mp, [status(thm)], [c18, s6, lemma_20])).
fof(lemma_21, lemma, ! [X] : add(multiplicative_identity,multiply(X,additive_identity)) = add(X,multiplicative_identity), inference(rewrite, [status(thm)], [lemma_17, s7])).
fof(s8, plain, product(additive_identity,multiplicative_identity,additive_identity), inference(instantiate, [status(thm)], [c5])).
fof(s9, plain, ! [X] : product(additive_identity,X,multiply(additive_identity,X)), inference(instantiate, [status(thm)], [c17])).
fof(s10, plain, ! [X] : sum(multiplicative_identity,X,add(multiplicative_identity,X)), inference(instantiate, [status(thm)], [c2])).
fof(s11, plain, ! [X] : sum(additive_identity,multiply(additive_identity,X),multiply(additive_identity,X)), inference(instantiate, [status(thm)], [c41])).
fof(s12, plain, ! [X] : product(additive_identity,add(multiplicative_identity,X),multiply(additive_identity,X)), inference(mp, [status(thm)], [c6, s8, s9, s10, s11])).
fof(lemma_22, lemma, ! [X] : product(additive_identity,add(multiplicative_identity,X),multiply(X,additive_identity)), inference(rewrite, [status(thm)], [lemma_19, s12])).
fof(s13, plain, ! [X] : product(additive_identity,add(multiplicative_identity,X),multiply(additive_identity,add(multiplicative_identity,X))), inference(instantiate, [status(thm)], [c17])).
fof(s14, plain, ! [X] : multiply(additive_identity,add(multiplicative_identity,X)) = multiply(X,additive_identity), inference(mp, [status(thm)], [c18, s13, lemma_22])).
fof(lemma_23, lemma, ! [X] : multiply(additive_identity,add(X,multiplicative_identity)) = multiply(X,additive_identity), inference(rewrite, [status(thm)], [lemma_17, s14])).
fof(s15, plain, ! [X] : product(inverse(add(X,multiplicative_identity)),multiplicative_identity,inverse(add(X,multiplicative_identity))), inference(instantiate, [status(thm)], [c5])).
fof(s16, plain, ! [X] : product(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity),additive_identity), inference(instantiate, [status(thm)], [c3])).
fof(s17, plain, ! [X] : sum(multiplicative_identity,add(X,multiplicative_identity),add(multiplicative_identity,add(X,multiplicative_identity))), inference(instantiate, [status(thm)], [c2])).
fof(s18, plain, ! [X] : sum(inverse(add(X,multiplicative_identity)),additive_identity,inverse(add(X,multiplicative_identity))), inference(instantiate, [status(thm)], [c4])).
fof(s19, plain, ! [X] : product(inverse(add(X,multiplicative_identity)),add(multiplicative_identity,add(X,multiplicative_identity)),inverse(add(X,multiplicative_identity))), inference(mp, [status(thm)], [c6, s15, s16, s17, s18])).
fof(lemma_24, lemma, ! [X] : product(inverse(add(X,multiplicative_identity)),add(add(X,multiplicative_identity),multiplicative_identity),inverse(add(X,multiplicative_identity))), inference(rewrite, [status(thm)], [lemma_17, s19])).
fof(s20, plain, ! [X] : product(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity),multiply(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity))), inference(instantiate, [status(thm)], [c17])).
fof(lemma_25, lemma, ! [X] : product(add(X,multiplicative_identity),inverse(add(X,multiplicative_identity)),multiply(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity))), inference(mp, [status(thm)], [c28, s20])).
fof(s21, plain, ! [X] : product(inverse(add(X,multiplicative_identity)),add(add(X,multiplicative_identity),multiplicative_identity),multiply(inverse(add(X,multiplicative_identity)),add(add(X,multiplicative_identity),multiplicative_identity))), inference(instantiate, [status(thm)], [c17])).
fof(lemma_26, lemma, ! [X] : multiply(inverse(add(X,multiplicative_identity)),add(add(X,multiplicative_identity),multiplicative_identity)) = inverse(add(X,multiplicative_identity)), inference(mp, [status(thm)], [c18, s21, lemma_24])).
fof(s22, plain, ! [X] : product(add(X,multiplicative_identity),inverse(add(X,multiplicative_identity)),additive_identity), inference(instantiate, [status(thm)], [c52])).
fof(lemma_27, lemma, ! [X] : additive_identity = multiply(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity)), inference(mp, [status(thm)], [c18, s22, lemma_25])).
fof(s23, plain, ! [X] : inverse(add(X,multiplicative_identity)) = multiply(inverse(add(X,multiplicative_identity)),add(add(X,multiplicative_identity),multiplicative_identity)), inference(instantiate, [status(thm)], [lemma_26])).
fof(s24, plain, ! [X] : inverse(add(X,multiplicative_identity)) = multiply(inverse(add(X,multiplicative_identity)),add(multiplicative_identity,multiply(add(X,multiplicative_identity),additive_identity))), inference(rewrite, [status(thm)], [lemma_21, s23])).
fof(s25, plain, ! [X] : inverse(add(X,multiplicative_identity)) = multiply(inverse(add(X,multiplicative_identity)),add(multiplicative_identity,multiply(additive_identity,add(X,multiplicative_identity)))), inference(rewrite, [status(thm)], [lemma_19, s24])).
fof(s26, plain, ! [X] : inverse(add(X,multiplicative_identity)) = multiply(inverse(add(X,multiplicative_identity)),add(multiplicative_identity,multiply(X,additive_identity))), inference(rewrite, [status(thm)], [lemma_23, s25])).
fof(s27, plain, ! [X] : inverse(add(X,multiplicative_identity)) = multiply(inverse(add(X,multiplicative_identity)),add(X,multiplicative_identity)), inference(rewrite, [status(thm)], [lemma_21, s26])).
fof(lemma_28, lemma, ! [X] : inverse(add(X,multiplicative_identity)) = additive_identity, inference(rewrite, [status(thm)], [lemma_27, s27])).
fof(s28, plain, sum(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity),add(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity))), inference(instantiate, [status(thm)], [c2])).
fof(lemma_29, lemma, sum(inverse(add(x,multiplicative_identity)),multiply(additive_identity,add(x,multiplicative_identity)),add(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity))), inference(rewrite, [status(thm)], [lemma_19, s28])).
fof(s29, plain, sum(additive_identity,multiply(additive_identity,add(x,multiplicative_identity)),add(additive_identity,multiply(additive_identity,add(x,multiplicative_identity)))), inference(instantiate, [status(thm)], [c2])).
fof(lemma_30, lemma, sum(multiply(additive_identity,add(x,multiplicative_identity)),additive_identity,add(additive_identity,multiply(additive_identity,add(x,multiplicative_identity)))), inference(mp, [status(thm)], [c11, s29])).
fof(s30, plain, sum(inverse(add(x,multiplicative_identity)),additive_identity,inverse(add(x,multiplicative_identity))), inference(instantiate, [status(thm)], [c4])).
fof(s31, plain, sum(inverse(add(x,multiplicative_identity)),add(x,multiplicative_identity),multiplicative_identity), inference(instantiate, [status(thm)], [c56])).
fof(s32, plain, product(additive_identity,add(x,multiplicative_identity),multiply(additive_identity,add(x,multiplicative_identity))), inference(instantiate, [status(thm)], [c17])).
fof(s33, plain, product(inverse(add(x,multiplicative_identity)),multiplicative_identity,add(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity))), inference(mp, [status(thm)], [c21, s30, s31, s32, lemma_29])).
fof(s34, plain, product(inverse(add(x,multiplicative_identity)),multiplicative_identity,inverse(add(x,multiplicative_identity))), inference(instantiate, [status(thm)], [c5])).
fof(lemma_31, lemma, add(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity)) = inverse(add(x,multiplicative_identity)), inference(mp, [status(thm)], [c18, s33, s34])).
fof(s35, plain, sum(multiply(additive_identity,add(x,multiplicative_identity)),additive_identity,multiply(additive_identity,add(x,multiplicative_identity))), inference(instantiate, [status(thm)], [c4])).
fof(lemma_32, lemma, multiply(additive_identity,add(x,multiplicative_identity)) = add(additive_identity,multiply(additive_identity,add(x,multiplicative_identity))), inference(mp, [status(thm)], [c13, s35, lemma_30])).
fof(s36, plain, product(x,additive_identity,multiply(x,additive_identity)), inference(instantiate, [status(thm)], [c17])).
fof(s37, plain, product(x,additive_identity,multiply(additive_identity,add(x,multiplicative_identity))), inference(rewrite, [status(thm)], [lemma_23, s36])).
fof(s38, plain, product(x,additive_identity,add(additive_identity,multiply(additive_identity,add(x,multiplicative_identity)))), inference(rewrite, [status(thm)], [lemma_32, s37])).
fof(s39, plain, product(x,additive_identity,add(inverse(add(x,multiplicative_identity)),multiply(additive_identity,add(x,multiplicative_identity)))), inference(rewrite, [status(thm)], [lemma_28, s38])).
fof(s40, plain, product(x,additive_identity,add(inverse(add(x,multiplicative_identity)),multiply(add(x,multiplicative_identity),additive_identity))), inference(rewrite, [status(thm)], [lemma_19, s39])).
fof(s41, plain, product(x,additive_identity,inverse(add(x,multiplicative_identity))), inference(rewrite, [status(thm)], [lemma_31, s40])).
fof(goal_1, theorem, product(x,additive_identity,additive_identity), inference(rewrite, [status(thm)], [lemma_28, s41])).
% SZS output end Proof
