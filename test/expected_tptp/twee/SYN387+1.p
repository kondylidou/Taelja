% SZS output start Proof
fof(c8, assumption, p, introduced(assumption, [], [])).
fof(s1, plain, p, inference(instantiate, [status(thm), assumptions([c8])], [c8])).
fof(c1, theorem, p | ~ p, inference(implies, [status(thm), discharge(implies, [c8])], [s1, c8])).
% SZS output end Proof
