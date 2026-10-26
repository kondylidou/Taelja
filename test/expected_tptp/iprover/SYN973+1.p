% SZS output start Proof
fof(c_50, assumption, p(z), introduced(assumption, [], [])).
fof(s1, plain, p(z), inference(instantiate, [status(thm), assumptions([c_50])], [c_50])).
fof(f1, theorem, p(z) => p(z), inference(implies, [status(thm), discharge(implies, [c_50])], [s1, c_50])).
% SZS output end Proof
