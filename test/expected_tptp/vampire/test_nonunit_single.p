% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/test_nonunit_single.p')).
fof(f2, axiom, p(a) => q(a), file('/home/user/Developer/Taelja/test/input/test_nonunit_single.p')).
fof(f3, theorem, q(a), inference(mp, [status(thm)], [f2, f1])).
% SZS output end Proof
