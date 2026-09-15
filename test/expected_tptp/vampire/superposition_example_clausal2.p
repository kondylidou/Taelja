% SZS output start Proof
fof(f3, axiom, g(f(a)) = g(f(b)), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p')).
fof(f2, axiom, ! [X0, X1]: (g(X0) = g(X1) => X0 = X1), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p')).
fof(f1, axiom, ! [X0, X1]: (f(X0) = f(X1) => X0 = X1), file('/home/user/Developer/Taelja/test/input/superposition_example_clausal2.p')).
fof(s1, plain, f(a) = f(b), inference(mp, [status(thm)], [f2, f3])).
fof(f4, theorem, a = b, inference(mp, [status(thm)], [f1, s1])).
% SZS output end Proof
