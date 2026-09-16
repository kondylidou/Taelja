% SZS output start Proof
fof(f1, axiom, ! [X0]: (f(X0) = c => f(X0) = b), file('/home/user/Developer/Taelja/test/input/superposition_exercise12_2.p')).
fof(f2, axiom, ! [X0]: f(f(X0)) = X0, file('/home/user/Developer/Taelja/test/input/superposition_exercise12_2.p')).
fof(s1, plain, f(f(c)) = c, inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, f(f(c)) = b, inference(mp, [status(thm)], [f1, s1])).
fof(f3, theorem, b = c, inference(rewrite, [status(thm)], [f2, s2])).
% SZS output end Proof
