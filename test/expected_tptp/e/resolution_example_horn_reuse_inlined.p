% SZS output start Proof
fof(ax3, axiom, ! [X2, X3]: ((q(X2, X3) & p(X3)) => q(f(X2), X3)), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax3)).
fof(ax1, axiom, ! [X1]: p(X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax1)).
fof(ax2, axiom, ! [X1]: q(b, X1), file('/home/user/Developer/Taelja/test/input/resolution_example_horn_reuse_inlined.p', ax2)).
fof(s1, plain, ! [X,Y] : (q(X,Y) => q(X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_4, lemma, ! [X,Y] : (q(X,Y) => q(f(X),Y)), inference(mp, [status(thm)], [ax3, s1, ax1])).
fof(s2, plain, q(b,a), inference(instantiate, [status(thm)], [ax2])).
fof(s3, plain, q(f(b),a), inference(mp, [status(thm)], [lemma_4, s2])).
fof(goal, theorem, q(f(f(b)), a), inference(mp, [status(thm)], [lemma_4, s3])).
% SZS output end Proof
