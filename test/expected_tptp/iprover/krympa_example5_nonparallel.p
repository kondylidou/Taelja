% SZS output start Proof
fof(f1, axiom, a = b, file('krympa_example5_nonparallel.p', ax1)).
fof(f2, axiom, ! [X0]: f(X0) = X0, file('krympa_example5_nonparallel.p', ax2)).
fof(s1, plain, h(f(b),a) = h(f(a),a), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, h(f(b),a) = h(a,a), inference(rewrite, [status(thm)], [f2, s1])).
fof(s3, plain, h(f(b),a) = h(a,f(a)), inference(rewrite, [status(thm)], [f2, s2])).
fof(f3, theorem, h(f(b), a) = h(a, f(b)), inference(rewrite, [status(thm)], [f1, s3])).
% SZS output end Proof
