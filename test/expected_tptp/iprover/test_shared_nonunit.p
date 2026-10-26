% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ p(X0) | q(X0, X1)), file('test_shared_nonunit.p', ax1)).
fof(c_50, plain, ! [X0, X1]: (~ q(X0, X1) | p(f(X0))), file('test_shared_nonunit.p', ax2)).
fof(c_51, plain, q(a, a), file('test_shared_nonunit.p', ax3)).
fof(s1, plain, ! [X,Y] : (q(X,Y) => q(X,Y)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y] : (q(X,Y) => p(f(X))), inference(mp, [status(thm)], [c_50, s1])).
fof(lemma_4, lemma, ! [X,Y,Z] : (q(X,Y) => q(f(X),Z)), inference(mp, [status(thm)], [c_49, s2])).
fof(s3, plain, q(f(a),a), inference(mp, [status(thm)], [lemma_4, c_51])).
fof(s4, plain, q(f(f(a)),a), inference(mp, [status(thm)], [lemma_4, s3])).
fof(goal_1, theorem, q(f(f(f(a))),f(f(f(a)))), inference(mp, [status(thm)], [lemma_4, s4])).
% SZS output end Proof
