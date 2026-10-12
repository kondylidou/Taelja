% SZS output start Proof
cnf(associativity2, axiom, product(X3, X4, X6) | ~ product(X1, X2, X3) | ~ product(X2, X4, X5) | ~ product(X1, X5, X6), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', associativity2)).
cnf(left_inverse, axiom, product(inverse(X1), X1, identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_inverse)).
cnf(total_function2, axiom, X3 = X4 | ~ product(X1, X2, X3) | ~ product(X1, X2, X4), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function2)).
cnf(right_identity, axiom, product(X1, identity, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_identity)).
cnf(left_identity, axiom, product(identity, X1, X1), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', left_identity)).
cnf(c_is_an_inverse_of_b, hypothesis, product(c, b, identity), file('Problems/GRP/GRP009-1.p', c_is_an_inverse_of_b)).
cnf(total_function1, axiom, product(X1, X2, multiply(X1, X2)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', total_function1)).
cnf(a_is_an_inverse_of_b, hypothesis, product(a, b, identity), file('Problems/GRP/GRP009-1.p', a_is_an_inverse_of_b)).
cnf(right_inverse, axiom, product(X1, inverse(X1), identity), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/GRP003-0.ax', right_inverse)).
fof(s1, plain, ! [X] : product(identity,X,multiply(identity,X)), inference(instantiate, [status(thm)], [total_function1])).
fof(lemma_10, lemma, ! [X] : multiply(identity,X) = X, inference(mp, [status(thm)], [total_function2, left_identity, s1])).
fof(s2, plain, ! [X,Y,Z] : (product(X,Y,Z) => product(X,Y,Z)), inference(assumption, [status(thm)], [])).
fof(lemma_11, lemma, ! [X,Y,Z] : (product(X,Y,Z) => multiply(X,Y) = Z), inference(mp, [status(thm)], [total_function2, total_function1, s2])).
fof(s3, plain, ! [X,Y] : (product(X,Y,identity) => product(X,Y,identity)), inference(assumption, [status(thm)], [])).
fof(s4, plain, ! [X,Y] : (product(X,Y,identity) => product(inverse(X),identity,inverse(X))), inference(instantiate, [status(thm)], [right_identity])).
fof(lemma_12, lemma, ! [X,Y] : (product(X,Y,identity) => product(identity,Y,inverse(X))), inference(mp, [status(thm)], [associativity2, left_inverse, s3, s4])).
fof(s5, plain, product(identity,b,inverse(a)), inference(mp, [status(thm)], [lemma_12, a_is_an_inverse_of_b])).
fof(lemma_13, lemma, multiply(identity,b) = inverse(a), inference(mp, [status(thm)], [lemma_11, s5])).
fof(s6, plain, inverse(a) = multiply(identity,b), inference(instantiate, [status(thm)], [lemma_13])).
fof(lemma_14, lemma, inverse(a) = b, inference(rewrite, [status(thm)], [lemma_10, s6])).
fof(s7, plain, product(b,inverse(b),identity), inference(instantiate, [status(thm)], [right_inverse])).
fof(s8, plain, product(c,identity,c), inference(instantiate, [status(thm)], [right_identity])).
fof(s9, plain, product(identity,inverse(b),c), inference(mp, [status(thm)], [associativity2, c_is_an_inverse_of_b, s7, s8])).
fof(lemma_15, lemma, multiply(identity,inverse(b)) = c, inference(mp, [status(thm)], [lemma_11, s9])).
fof(s10, plain, inverse(b) = multiply(identity,inverse(b)), inference(instantiate, [status(thm)], [lemma_10])).
fof(lemma_16, lemma, inverse(b) = c, inference(rewrite, [status(thm)], [lemma_15, s10])).
fof(s11, plain, product(inverse(a),a,identity), inference(instantiate, [status(thm)], [left_inverse])).
fof(s12, plain, product(b,a,identity), inference(rewrite, [status(thm)], [lemma_14, s11])).
fof(s13, plain, product(identity,a,inverse(b)), inference(mp, [status(thm)], [lemma_12, s12])).
fof(s14, plain, product(identity,a,c), inference(rewrite, [status(thm)], [lemma_16, s13])).
fof(s15, plain, multiply(identity,a) = c, inference(mp, [status(thm)], [lemma_11, s14])).
fof(goal_1, theorem, a = c, inference(rewrite, [status(thm)], [lemma_10, s15])).
% SZS output end Proof
