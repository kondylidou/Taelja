% SZS output start Proof
fof(f1, axiom, p(a), file('test_nonunit_single.p', f1)).
fof(f2, axiom, p(a) => q(a), file('test_nonunit_single.p', f2)).
fof(f3, theorem, q(a), inference(mp, [status(thm)], [f2, f1])).
% SZS output end Proof
