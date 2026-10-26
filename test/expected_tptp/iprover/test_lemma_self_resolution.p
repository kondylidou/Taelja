% SZS output start Proof
fof(c_49, plain, ! [X0, X1]: (~ p(X0, X1) | ~ r(X0) | q(X0, X1)), file('test_lemma_self_resolution.p', a1)).
fof(c_50, plain, ! [X0, X1]: (~ q(X0, f(X1)) | ~ t(X1) | s(X0, f(X1))), file('test_lemma_self_resolution.p', a2)).
fof(c_51, plain, ! [X0]: (~ r(X0) | u(X0)), file('test_lemma_self_resolution.p', a3)).
fof(c_52, plain, ! [X0, X1]: (~ s(X0, X1) | ~ u(X0) | p(f(X0), f(b))), file('test_lemma_self_resolution.p', a4)).
fof(c_53, plain, r(a), file('test_lemma_self_resolution.p', a5)).
fof(c_54, plain, ! [X0]: r(f(X0)), file('test_lemma_self_resolution.p', a6)).
fof(c_55, plain, t(a), file('test_lemma_self_resolution.p', a7)).
fof(c_56, plain, t(b), file('test_lemma_self_resolution.p', a8)).
fof(c_57, plain, p(a, f(a)), file('test_lemma_self_resolution.p', a9)).
fof(s1, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => p(X,f(Y))), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => r(X)), inference(assumption, [status(thm)], [])).
fof(s3, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => q(X,f(Y))), inference(mp, [status(thm)], [c_49, s1, s2])).
fof(s4, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => t(Y)), inference(assumption, [status(thm)], [])).
fof(s5, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => s(X,f(Y))), inference(mp, [status(thm)], [c_50, s3, s4])).
fof(s6, plain, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => u(X)), inference(mp, [status(thm)], [c_51])).
fof(lemma_10, lemma, ! [X,Y] : ((p(X,f(Y)) & r(X) & t(Y)) => p(f(X),f(b))), inference(mp, [status(thm)], [c_52, s5, s6])).
fof(s7, plain, p(f(a),f(b)), inference(mp, [status(thm)], [lemma_10, c_57, c_53, c_55])).
fof(s8, plain, r(f(a)), inference(instantiate, [status(thm)], [c_54])).
fof(goal_1, theorem, p(f(f(a)),f(b)), inference(mp, [status(thm)], [lemma_10, s7, s8, c_56])).
% SZS output end Proof
