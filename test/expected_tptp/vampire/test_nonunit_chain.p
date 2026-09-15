% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/test_nonunit_chain.p', unknown)).
fof(f2, axiom, p(a) => q(a), file('/home/user/Developer/Taelja/test/input/test_nonunit_chain.p', unknown)).
fof(f3, axiom, (p(a) & q(a)) => r(a), file('/home/user/Developer/Taelja/test/input/test_nonunit_chain.p', unknown)).
fof(lemma_4, lemma, q(a), inference(mp, [status(thm)], [f2, f1])).
fof(f4, theorem, r(a), inference(mp, [status(thm)], [f3, f1, lemma_4])).
% SZS output end Proof
