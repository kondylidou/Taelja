% SZS output start Proof
fof(f3, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', unknown)).
fof(f1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', unknown)).
fof(f2, axiom, b = c, file('/home/user/Developer/Taelja/test/input/superposition_example_clausal1.p', unknown)).
fof(s1, plain, c = b, inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, c = a, inference(rewrite, [status(thm)], [f1, s1])).
fof(s3, plain, f(d) = d, inference(instantiate, [status(thm)], [f3])).
fof(f4, theorem, c = a & f(d) = d, inference(conclude, [status(thm)], [s2, s3])).
% SZS output end Proof
