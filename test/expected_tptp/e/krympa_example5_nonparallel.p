% SZS output start Proof
fof(ax2, axiom, ! [X1]: f(X1) = X1, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p', ax2)).
fof(ax1, axiom, a = b, file('/home/user/Developer/Taelja/test/input/krympa_example5_nonparallel.p', ax1)).
fof(s1, plain, h(f(b),a) = h(b,a), inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, h(f(b),a) = h(a,a), inference(rewrite, [status(thm)], [ax1, s1])).
fof(s3, plain, h(f(b),a) = h(a,b), inference(rewrite, [status(thm)], [ax1, s2])).
fof(goal, theorem, h(f(b), a) = h(a, f(b)), inference(rewrite, [status(thm)], [ax2, s3])).
% SZS output end Proof
