% SZS output start Proof
fof(c_49, plain, ! [X0]: least_upper_bound(identity, X0) = X0, file('Problems/GRP/GRP192-1.p', p40a_1)).
fof(c_51, plain, ! [X0, X1]: greatest_lower_bound(X0, X1) = greatest_lower_bound(X1, X0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP004-2.ax', symmetry_of_glb)).
fof(c_57, plain, ! [X0, X1]: least_upper_bound(X0, greatest_lower_bound(X0, X1)) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP004-2.ax', lub_absorbtion)).
fof(c_62, plain, ! [X0, X1, X2]: greatest_lower_bound(multiply(X0, X1), multiply(X2, X1)) = multiply(greatest_lower_bound(X0, X2), X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP004-2.ax', monotony_glb2)).
fof(c_63, plain, ! [X0]: multiply(identity, X0) = X0, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP004-0.ax', left_identity)).
fof(c_64, plain, ! [X0]: multiply(inverse(X0), X0) = identity, file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Axioms/GRP004-0.ax', left_inverse)).
fof(s1, plain, ! [X] : greatest_lower_bound(identity,X) = least_upper_bound(identity,greatest_lower_bound(identity,X)), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_7, lemma, ! [X] : greatest_lower_bound(identity,X) = identity, inference(rewrite, [status(thm)], [c_57, s1])).
fof(s2, plain, ! [X] : X = multiply(identity,X), inference(instantiate, [status(thm)], [c_63])).
fof(s3, plain, ! [X] : X = multiply(greatest_lower_bound(identity,inverse(X)),X), inference(rewrite, [status(thm)], [lemma_7, s2])).
fof(s4, plain, ! [X] : X = greatest_lower_bound(multiply(identity,X),multiply(inverse(X),X)), inference(rewrite, [status(thm)], [c_62, s3])).
fof(s5, plain, ! [X] : X = greatest_lower_bound(X,multiply(inverse(X),X)), inference(rewrite, [status(thm)], [c_63, s4])).
fof(s6, plain, ! [X] : X = greatest_lower_bound(X,identity), inference(rewrite, [status(thm)], [c_64, s5])).
fof(s7, plain, ! [X] : X = greatest_lower_bound(identity,X), inference(rewrite, [status(thm)], [c_51, s6])).
fof(lemma_8, lemma, ! [X] : X = identity, inference(rewrite, [status(thm)], [lemma_7, s7])).
fof(lemma_9, lemma, ! [X] : X = identity, inference(instantiate, [status(thm)], [lemma_8])).
fof(s8, plain, multiply(a,b) = identity, inference(instantiate, [status(thm)], [lemma_9])).
fof(goal_1, theorem, multiply(a,b) = multiply(b,a), inference(rewrite, [status(thm)], [lemma_9, s8])).
% SZS output end Proof
