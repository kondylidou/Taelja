% SZS output start Proof
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/horn_example_relational_rw.p')).
fof(f2, axiom, a = b, file('/home/user/Developer/Taelja/test/input/horn_example_relational_rw.p')).
fof(f3, axiom, p(b) => q(b), file('/home/user/Developer/Taelja/test/input/horn_example_relational_rw.p')).
fof(s1, plain, p(b), inference(rewrite, [status(thm)], [f2, f1])).
fof(f4, theorem, q(b), inference(mp, [status(thm)], [f3, s1])).
% SZS output end Proof
