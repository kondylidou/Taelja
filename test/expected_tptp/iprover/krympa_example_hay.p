% SZS output start Proof
fof(f1, axiom, ! [X0]: h(a, X0) = c, file('krympa_example_hay.p', ax1)).
fof(f2, axiom, ! [X1]: h(X1, b) = X1, file('krympa_example_hay.p', ax2)).
fof(s1, plain, a = h(a,b), inference(instantiate, [status(thm)], [f2])).
fof(f3, theorem, a = c, inference(rewrite, [status(thm)], [f1, s1])).
% SZS output end Proof
