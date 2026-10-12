% SZS output start Proof
cnf(c1, axiom, ~ p(X) | q(X, Y), file('test_shared_nonunit.p', ax1)).
cnf(c2, axiom, ~ q(X, Z) | p(f(X)), file('test_shared_nonunit.p', ax2)).
cnf(c3, axiom, q(a, a), file('test_shared_nonunit.p', ax3)).
fof(s1, plain, ! [X,Y] : (q(X,Y) => q(X,Y)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y] : (q(X,Y) => p(f(X))), inference(mp, [status(thm)], [c2, s1])).
fof(lemma_4, lemma, ! [X,Y,Z] : (q(X,Y) => q(f(X),Z)), inference(mp, [status(thm)], [c1, s2])).
fof(s3, plain, ! [X] : q(f(a),X), inference(mp, [status(thm)], [lemma_4, c3])).
fof(s4, plain, ! [Y] : q(f(f(a)),Y), inference(mp, [status(thm)], [lemma_4, s3])).
fof(goal_1, theorem, q(f(f(f(a))),f(f(f(a)))), inference(mp, [status(thm)], [lemma_4, s4])).
% SZS output end Proof
