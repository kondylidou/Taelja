% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = c, file('/home/user/Developer/Taelja/test/input/test_rl_safety.p', unknown)).
fof(f2, theorem, f(a) = c, inference(instantiate, [status(thm)], [f1])).
% SZS output end Proof
