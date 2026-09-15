% SZS output start Proof
fof(f2, axiom, q(b), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p')).
fof(f1, axiom, p(a), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p')).
fof(f3, axiom, ! [X0, X1]: ((p(X0) & q(X1)) => r(X0, X1)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_2unit.p')).
fof(f4, theorem, r(a, b), inference(mp, [status(thm)], [f3, f1, f2])).
% SZS output end Proof
