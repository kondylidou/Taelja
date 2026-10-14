% SZS output start Proof
cnf(f1, axiom, ~ p(X0, X1) | ~ r(X0) | q(X0, X1), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a1)).
cnf(f2, axiom, ~ q(X0, f(X2)) | ~ t(X2) | s(X0, f(X2)), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a2)).
cnf(f3, axiom, ~ r(X0) | u(X0), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a3)).
cnf(f4, axiom, ~ s(X0, X1) | ~ u(X0) | p(f(X0), f(b)), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a4)).
cnf(f5, axiom, r(a), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a5)).
cnf(f6, axiom, r(f(X0)), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a6)).
cnf(f7, axiom, t(a), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a7)).
cnf(f8, axiom, t(b), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a8)).
cnf(f9, axiom, p(a, f(a)), file('/home/user/Developer/Taelja/test/input/test_lemma_self_resolution.p', a9)).
fof(s1, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => p(X,f(Y))), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => r(X)), inference(assumption, [status(thm)], [])).
fof(s3, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => q(X,f(Y))), inference(mp, [status(thm)], [f1, s1, s2])).
fof(s4, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => t(Y)), inference(assumption, [status(thm)], [])).
fof(s5, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => s(X,f(Y))), inference(mp, [status(thm)], [f2, s3, s4])).
fof(s6, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => u(X)), inference(mp, [status(thm)], [f3])).
fof(lemma_10, lemma, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => p(f(X),f(b))), inference(mp, [status(thm)], [f4, s5, s6])).
fof(s7, plain, p(f(a),f(b)), inference(mp, [status(thm)], [lemma_10, f9, f5, f7])).
fof(s8, plain, r(f(a)), inference(instantiate, [status(thm)], [f6])).
fof(goal_1, theorem, p(f(f(a)),f(b)), inference(mp, [status(thm)], [lemma_10, s7, s8, f8])).
% SZS output end Proof
