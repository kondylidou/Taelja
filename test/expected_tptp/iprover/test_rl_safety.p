% SZS output start Proof
fof(f1, axiom, ! [X0]: f(X0) = c, file('test_rl_safety.p', f1)).
fof(f2, theorem, c = f(a), inference(instantiate, [status(thm)], [f1])).
% SZS output end Proof
