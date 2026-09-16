% SZS output start Proof
fof(ax2, axiom, ! [X1]: h(X1) = X1, file('eq_hyp.p', ax2)).
fof(ax1, axiom, g(a) = b, file('eq_hyp.p', ax1)).
fof(c_0_9, assumption, f(esk1_0) = a, introduced(assumption, [], [])).
fof(s1, plain, g(h(f(esk1_0))) = g(f(esk1_0)), inference(instantiate, [status(thm)], [ax2])).
fof(s2, plain, g(h(f(esk1_0))) = g(a), inference(rewrite, [status(thm), assumptions([c_0_9])], [c_0_9, s1])).
fof(s3, plain, g(h(f(esk1_0))) = b, inference(rewrite, [status(thm), assumptions([c_0_9])], [ax1, s2])).
fof(discharged, plain, (f(esk1_0) = a => g(h(f(esk1_0))) = b), inference(implies, [status(thm), discharge(implies, [c_0_9])], [s3, c_0_9])).
fof(goal, theorem, ! [X1]: (f(X1) = a => g(h(f(X1))) = b), inference(generalization, [status(thm)], [discharged])).
% SZS output end Proof
