% SZS output start Proof
fof(f1, axiom, p(a), file('test_nonunit_chain.p', f1)).
fof(f2, axiom, p(a) => q(a), file('test_nonunit_chain.p', f2)).
fof(f3, axiom, (q(a) & p(a)) => r(a), file('test_nonunit_chain.p', f3)).
fof(s1, plain, q(a), inference(mp, [status(thm)], [f2, f1])).
fof(f4, theorem, r(a), inference(mp, [status(thm)], [f3, s1, f1])).
% SZS output end Proof
