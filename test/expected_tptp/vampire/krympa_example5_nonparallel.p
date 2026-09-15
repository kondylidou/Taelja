% SZS output start Proof
fof(f2, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p', unknown)).
fof(f1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p', unknown)).
fof(s1, plain, h(f(b),a) = h(b,a), inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, h(f(b),a) = h(a,a), inference(rewrite, [status(thm)], [f1, s1])).
fof(s3, plain, h(f(b),a) = h(a,b), inference(rewrite, [status(thm)], [f1, s2])).
fof(f3, theorem, h(f(b), a) = h(a, f(b)), inference(rewrite, [status(thm)], [f2, s3])).
% SZS output end Proof
