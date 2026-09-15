% SZS output start Proof
fof(1, axiom, p => q).
fof(2, axiom, q => r).
fof(c4a, assumption, p, introduced(assumption, [], [])).
fof(s1, plain, q, inference(mp, [status(thm), assumptions([c4a])], [1, c4a])).
fof(s2, plain, r, inference(mp, [status(thm), assumptions([c4a])], [2, s1])).
fof(3, theorem, p => r, inference(implies, [status(thm), discharge(implies, [c4a])], [s2, c4a])).
% SZS output end Proof
