% SZS output start Proof
fof(f1, axiom, ! [X0]: h(a, X0) = c, file('/home/user/Developer/Taelja/test/input/krympa_example_hay.p')).
fof(f2, axiom, ! [X0]: h(X0, b) = X0, file('/home/user/Developer/Taelja/test/input/krympa_example_hay.p')).
fof(s1, plain, a = h(a,b), inference(instantiate, [status(thm)], [f2])).
fof(f3, theorem, a = c, inference(rewrite, [status(thm)], [f1, s1])).
% SZS output end Proof
