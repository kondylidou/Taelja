% SZS output start Proof
fof(f1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p')).
fof(f2, axiom, ! [X0]: f(X0) = X0, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p')).
fof(s1, plain, h(f(b),a) = h(f(b),b), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, h(f(b),a) = h(b,b), inference(rewrite, [status(thm)], [f2, s1])).
fof(s3, plain, h(f(b),a) = h(b,f(b)), inference(rewrite, [status(thm)], [f2, s2])).
fof(f3, theorem, h(f(b), a) = h(a, f(b)), inference(rewrite, [status(thm)], [f1, s3])).
% SZS output end Proof
