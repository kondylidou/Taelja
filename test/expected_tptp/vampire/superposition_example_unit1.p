% SZS output start Proof
fof(f1, axiom, c = a, file('/home/user/Developer/Taelja/test/input/superposition_example_unit1.p', unknown)).
fof(f2, axiom, b = a, file('/home/user/Developer/Taelja/test/input/superposition_example_unit1.p', unknown)).
fof(s1, plain, f(c) = f(a), inference(instantiate, [status(thm)], [f1])).
fof(f3, theorem, f(c) = f(b), inference(rewrite, [status(thm)], [f2, s1])).
% SZS output end Proof
