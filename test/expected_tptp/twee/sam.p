% SZS output start Proof
cnf(c2, axiom, join(X, Y) = join(Y, X), file('sam.p', g_comm)).
cnf(c3, axiom, join(X2, join(Y2, Z)) = join(join(X2, Y2), Z), file('sam.p', g_assoc)).
cnf(c5, axiom, meet(X2, Y2) = meet(Y2, X2), file('sam.p', f_comm)).
cnf(c7, axiom, join(X2, meet(X2, Y2)) = X2, file('sam.p', ax34)).
cnf(c11, axiom, meet(X2, join(X2, Y2)) = X2, file('sam.p', ax31)).
cnf(c15, axiom, meet(X2, meet(Y2, Z2)) = meet(meet(X2, Y2), Z2), file('sam.p', f_assoc)).
cnf(c20, axiom, comp(b, join(c, d)), file('sam.p', premise2)).
cnf(c21, axiom, ~ comp(X2, Y2) | meet(X2, Y2) = zero, file('sam.p', comp1)).
cnf(c24, axiom, meet(zero, X2) = zero, file('sam.p', ax32)).
cnf(c28, axiom, join(zero, X2) = X2, file('sam.p', ax33)).
fof(lemma_11, lemma, meet(b,join(c,d)) = zero, inference(mp, [status(thm)], [c21, c20])).
fof(s1, plain, ! [X] : join(meet(b,c),X) = join(meet(b,meet(c,join(c,d))),X), inference(instantiate, [status(thm)], [c11])).
fof(s2, plain, ! [X] : join(meet(b,c),X) = join(meet(b,meet(c,join(d,c))),X), inference(rewrite, [status(thm)], [c2, s1])).
fof(s3, plain, ! [X] : join(meet(b,c),X) = join(meet(b,meet(join(d,c),c)),X), inference(rewrite, [status(thm)], [c5, s2])).
fof(s4, plain, ! [X] : join(meet(b,c),X) = join(meet(meet(b,join(d,c)),c),X), inference(rewrite, [status(thm)], [c15, s3])).
fof(s5, plain, ! [X] : join(meet(b,c),X) = join(meet(meet(b,join(c,d)),c),X), inference(rewrite, [status(thm)], [c2, s4])).
fof(s6, plain, ! [X] : join(meet(b,c),X) = join(meet(zero,c),X), inference(rewrite, [status(thm)], [lemma_11, s5])).
fof(s7, plain, ! [X] : join(meet(b,c),X) = join(zero,X), inference(rewrite, [status(thm)], [c24, s6])).
fof(lemma_12, lemma, ! [X] : join(meet(b,c),X) = X, inference(rewrite, [status(thm)], [c28, s7])).
fof(s8, plain, meet(join(a,meet(b,c)),join(a,meet(b,d))) = meet(join(a,meet(b,c)),join(join(meet(b,c),a),meet(b,d))), inference(instantiate, [status(thm)], [lemma_12])).
fof(s9, plain, meet(join(a,meet(b,c)),join(a,meet(b,d))) = meet(join(a,meet(b,c)),join(join(a,meet(b,c)),meet(b,d))), inference(rewrite, [status(thm)], [c2, s8])).
fof(s10, plain, meet(join(a,meet(b,c)),join(a,meet(b,d))) = join(a,meet(b,c)), inference(rewrite, [status(thm)], [c11, s9])).
fof(s11, plain, meet(join(a,meet(b,c)),join(a,meet(b,d))) = join(meet(b,c),a), inference(rewrite, [status(thm)], [c2, s10])).
fof(goal_1, theorem, meet(join(a,meet(b,c)),join(a,meet(b,d))) = a, inference(rewrite, [status(thm)], [lemma_12, s11])).
% SZS output end Proof
