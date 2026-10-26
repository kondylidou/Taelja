% SZS output start Proof
fof(f1, axiom, p => q, file('tptp_implication_conjecture.p', 1)).
fof(f2, axiom, q => r, file('tptp_implication_conjecture.p', 2)).
fof(c_52, assumption, p, introduced(assumption, [], [])).
fof(s1, plain, q, inference(mp, [status(thm), assumptions([c_52])], [f1, c_52])).
fof(s2, plain, r, inference(mp, [status(thm), assumptions([c_52])], [f2, s1])).
fof(f3, theorem, p => r, inference(implies, [status(thm), discharge(implies, [c_52])], [s2, c_52])).
% SZS output end Proof
