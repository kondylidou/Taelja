% SZS output start Proof
fof(f2, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/units_only_relational_example.p', unknown)).
fof(f1, axiom, ! [X0]: p(f(X0)), file('/home/user/Developer/Taelja/test/input/units_only_relational_example.p', unknown)).
fof(s1, plain, p(f(a)), inference(instantiate, [status(thm)], [f1])).
fof(f3, theorem, p(a), inference(rewrite, [status(thm)], [f2, s1])).
% SZS output end Proof
