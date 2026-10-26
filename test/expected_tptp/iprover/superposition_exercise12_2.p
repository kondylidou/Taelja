% SZS output start Proof
fof(f1, axiom, ! [X0]: (f(X0) = c => f(X0) = b), file('superposition_exercise12_2.p', ax1)).
fof(f2, axiom, ! [X1]: f(f(X1)) = X1, file('superposition_exercise12_2.p', ax2)).
fof(s1, plain, f(f(c)) = c, inference(instantiate, [status(thm)], [f2])).
fof(s2, plain, f(f(c)) = b, inference(mp, [status(thm)], [f1, s1])).
fof(f3, theorem, c = b, inference(rewrite, [status(thm)], [f2, s2])).
% SZS output end Proof
