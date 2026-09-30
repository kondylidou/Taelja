% SZS output start Proof
fof(c_0_1_h1, assumption, p(z), introduced(assumption, [], [])).
fof(s1, plain, p(z), inference(instantiate, [status(thm), assumptions([c_0_1_h1])], [c_0_1_h1])).
fof(prove_this, theorem, p(z) => p(z), inference(implies, [status(thm), discharge(implies, [c_0_1_h1])], [s1, c_0_1_h1])).
% SZS output end Proof
