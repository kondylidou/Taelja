% SZS output start Proof
fof(ax3, axiom, ! [X1]: (t(X1) => u(X1)), file('reordered_hyp.p', ax3)).
fof(ax2, axiom, s(a), file('reordered_hyp.p', ax2)).
fof(ax1, axiom, r(a), file('reordered_hyp.p', ax1)).
fof(c_0_8, assumption, ! [X] : ((s(X) & r(X)) => t(X)), introduced(assumption, [], [])).
fof(s1, plain, t(a), inference(mp, [status(thm), assumptions([c_0_8])], [c_0_8, ax2, ax1])).
fof(s2, plain, u(a), inference(mp, [status(thm), assumptions([c_0_8])], [ax3, s1])).
fof(goal, theorem, ! [X1]: ((s(X1) & r(X1)) => t(X1)) => u(a), inference(implies, [status(thm), discharge(implies, [c_0_8])], [s2, c_0_8])).
% SZS output end Proof
