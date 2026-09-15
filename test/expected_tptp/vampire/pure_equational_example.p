% SZS output start Proof
fof(f1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/pure_equational_example.p', unknown)).
fof(f2, axiom, b = c, file('/home/user/Developer/Taelja/test/input/pure_equational_example.p', unknown)).
fof(f3, theorem, a = c, inference(rewrite, [status(thm)], [f2, f1])).
% SZS output end Proof
