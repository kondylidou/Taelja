% SZS output start Proof
cnf(c2, axiom, compose(X, compose(Y, Z)) = compose(compose(X, Y), Z), file('TPTP/Problems/CAT/CAT003-4.p', associativity_of_compose)).
cnf(c3, hypothesis, compose(X2, compose(a, b)) != Y2 | compose(Z2, compose(a, b)) != Y2 | X2 = Z2, file('TPTP/Problems/CAT/CAT003-4.p', epimorphism)).
cnf(c5, hypothesis, compose(h, a) = compose(g, a), file('TPTP/Problems/CAT/CAT003-4.p', ha_equals_ga)).
fof(s1, plain, compose(g,compose(a,b)) = compose(compose(g,a),b), inference(instantiate, [status(thm)], [c2])).
fof(lemma_4, lemma, compose(g,compose(a,b)) = compose(compose(h,a),b), inference(rewrite, [status(thm)], [c5, s1])).
fof(s2, plain, compose(h,compose(a,b)) = compose(compose(h,a),b), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, g = h, inference(mp, [status(thm)], [c3, s2, lemma_4])).
% SZS output end Proof
