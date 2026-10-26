% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (X0 != additive_identity | product(X0, h(X0, X1), X1)), file('Problems/RNG/RNG038-1.p', some_property)).
fof(c_53, plain, ! [X0]: sum(additive_identity, X0, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', additive_identity1)).
fof(c_54, plain, ! [X0]: sum(X0, additive_identity, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', additive_identity2)).
fof(c_56, plain, ! [X0, X1]: sum(X0, X1, add(X0, X1)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', closure_of_addition)).
fof(c_57, plain, ! [X0]: sum(additive_inverse(X0), X0, additive_identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', left_inverse)).
fof(c_58, plain, ! [X0]: sum(X0, additive_inverse(X0), additive_identity), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', right_inverse)).
fof(c_59, plain, ! [X0, X1, X2, X3, X4, X5]: (~ sum(X0, X1, X2) | ~ sum(X1, X3, X4) | ~ sum(X2, X3, X5) | sum(X0, X4, X5)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', associativity_of_addition1)).
fof(c_60, plain, ! [X0, X1, X2, X3, X4, X5]: (~ sum(X0, X1, X2) | ~ sum(X0, X3, X4) | ~ sum(X1, X5, X3) | sum(X2, X5, X4)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', associativity_of_addition2)).
fof(c_61, plain, ! [X0, X1, X2]: (~ sum(X0, X1, X2) | sum(X1, X0, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', commutativity_of_addition)).
fof(c_66, plain, ! [X0, X1, X2, X3, X4, X5, X6]: (~ product(X0, X1, X2) | ~ product(X3, X1, X4) | ~ product(X5, X1, X6) | ~ sum(X0, X3, X5) | sum(X2, X4, X6)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', distributivity3)).
fof(c_68, plain, ! [X0, X1, X2, X3]: (~ sum(X0, X1, X2) | ~ sum(X0, X1, X3) | X2 = X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/RNG001-0.ax', addition_is_well_defined)).
fof(lemma_12, lemma, ! [X] : product(additive_identity,h(additive_identity,X),X), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_13, lemma, ! [X,Y] : sum(X,Y,add(Y,X)), inference(mp, [status(thm)], [c_61, c_56])).
fof(s1, plain, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(additive_identity,additive_identity,additive_identity)), inference(instantiate, [status(thm)], [c_54])).
fof(s2, plain, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(additive_identity,X,add(Y,Z))), inference(assumption, [status(thm)], [])).
fof(s3, plain, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(additive_identity,X,add(X,additive_identity))), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_14, lemma, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(additive_identity,add(Y,Z),add(X,additive_identity))), inference(mp, [status(thm)], [c_59, s1, s2, s3])).
fof(s4, plain, ! [X] : sum(additive_identity,X,add(X,additive_identity)), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_15, lemma, ! [X] : X = add(X,additive_identity), inference(mp, [status(thm)], [c_68, c_53, s4])).
fof(s5, plain, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(additive_identity,add(Y,Z),add(X,additive_identity))), inference(mp, [status(thm)], [lemma_14])).
fof(s6, plain, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(Y,Z,add(X,additive_identity))), inference(mp, [status(thm)], [c_60, c_53, s5, c_56])).
fof(lemma_16, lemma, ! [X,Y,Z] : (sum(additive_identity,X,add(Y,Z)) => sum(Y,Z,X)), inference(rewrite, [status(thm)], [lemma_15, s6])).
fof(s7, plain, ! [X] : sum(additive_inverse(X),additive_inverse(additive_inverse(X)),additive_identity), inference(instantiate, [status(thm)], [c_58])).
fof(s8, plain, ! [X] : sum(additive_identity,additive_inverse(additive_inverse(X)),additive_inverse(additive_inverse(X))), inference(instantiate, [status(thm)], [c_53])).
fof(lemma_17, lemma, ! [X] : sum(X,additive_identity,additive_inverse(additive_inverse(X))), inference(mp, [status(thm)], [c_59, c_58, s7, s8])).
fof(lemma_18, lemma, ! [X] : X = additive_inverse(additive_inverse(X)), inference(mp, [status(thm)], [c_68, c_54, lemma_17])).
fof(s9, plain, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(additive_inverse(additive_inverse(X)),additive_inverse(X),additive_identity)), inference(instantiate, [status(thm)], [c_57])).
fof(s10, plain, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(additive_inverse(additive_inverse(X)),Z,add(additive_inverse(additive_inverse(X)),Z))), inference(instantiate, [status(thm)], [c_56])).
fof(s11, plain, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(additive_inverse(X),Y,Z)), inference(assumption, [status(thm)], [])).
fof(s12, plain, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(additive_identity,Y,add(additive_inverse(additive_inverse(X)),Z))), inference(mp, [status(thm)], [c_60, s9, s10, s11])).
fof(s13, plain, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(additive_inverse(additive_inverse(X)),Z,Y)), inference(mp, [status(thm)], [lemma_16, s12])).
fof(lemma_19, lemma, ! [X,Y,Z] : (sum(additive_inverse(X),Y,Z) => sum(X,Z,Y)), inference(rewrite, [status(thm)], [lemma_18, s13])).
fof(s14, plain, ! [X,Y,Z,A,B] : ((sum(add(X,Y),Z,A) & sum(Y,Z,B)) => sum(Y,Z,B)), inference(assumption, [status(thm)], [])).
fof(s15, plain, ! [X,Y,Z,A,B] : ((sum(add(X,Y),Z,A) & sum(Y,Z,B)) => sum(add(X,Y),Z,A)), inference(assumption, [status(thm)], [])).
fof(lemma_20, lemma, ! [X,Y,Z,A,B] : ((sum(add(X,Y),Z,A) & sum(Y,Z,B)) => sum(X,B,A)), inference(mp, [status(thm)], [c_59, c_56, s14, s15])).
fof(s16, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [lemma_12])).
fof(s17, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [lemma_12])).
fof(s18, plain, product(additive_identity,h(additive_identity,b),b), inference(instantiate, [status(thm)], [lemma_12])).
fof(s19, plain, sum(additive_identity,additive_identity,additive_identity), inference(instantiate, [status(thm)], [c_53])).
fof(lemma_21, lemma, sum(b,b,b), inference(mp, [status(thm)], [c_66, s16, s17, s18, s19])).
fof(s20, plain, sum(additive_inverse(b),b,add(additive_inverse(b),b)), inference(instantiate, [status(thm)], [c_56])).
fof(s21, plain, sum(b,add(additive_inverse(b),b),b), inference(mp, [status(thm)], [lemma_19, s20])).
fof(s22, plain, sum(add(additive_inverse(b),b),b,b), inference(mp, [status(thm)], [c_61, s21])).
fof(lemma_22, lemma, sum(additive_inverse(b),b,b), inference(mp, [status(thm)], [lemma_20, s22, lemma_21])).
fof(s23, plain, sum(additive_inverse(a),a,additive_identity), inference(instantiate, [status(thm)], [c_57])).
fof(s24, plain, sum(additive_inverse(a),a,add(a,additive_inverse(a))), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_23, lemma, additive_identity = add(a,additive_inverse(a)), inference(mp, [status(thm)], [c_68, s23, s24])).
fof(s25, plain, sum(additive_inverse(b),additive_identity,add(additive_identity,additive_inverse(b))), inference(instantiate, [status(thm)], [lemma_13])).
fof(s26, plain, sum(b,add(additive_identity,additive_inverse(b)),additive_identity), inference(mp, [status(thm)], [lemma_19, s25])).
fof(s27, plain, sum(add(additive_identity,additive_inverse(b)),b,additive_identity), inference(mp, [status(thm)], [c_61, s26])).
fof(s28, plain, sum(additive_identity,b,additive_identity), inference(mp, [status(thm)], [lemma_20, s27, lemma_22])).
fof(s29, plain, sum(additive_identity,b,add(a,additive_inverse(a))), inference(rewrite, [status(thm)], [lemma_23, s28])).
fof(lemma_24, lemma, sum(a,additive_inverse(a),b), inference(mp, [status(thm)], [lemma_16, s29])).
fof(s30, plain, sum(a,additive_inverse(a),additive_identity), inference(instantiate, [status(thm)], [c_58])).
fof(goal_1, theorem, additive_identity = b, inference(mp, [status(thm)], [c_68, s30, lemma_24])).
% SZS output end Proof
