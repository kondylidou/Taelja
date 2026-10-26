% SZS output start Proof
tff(type_def_5, type, person: $tType).
tff(type_def_6, type, city: $tType).
tff(func_def_0, type, a: person).
tff(pred_def_1, type, q: person > $o).
tff(pred_def_2, type, s: person > $o).
tff(pred_def_3, type, p: (person * city) > $o).
tff(taelja_type_f, type, f: person > person).
tff(taelja_type_g, type, g: person > person).
tff(taelja_type_home, type, home: person > city).
tff(f1, axiom, ! [X0: person]: f(X0) = X0, file('tff_typed_lemma.p', ax1)).
tff(f2, axiom, ! [X0: person]: f(X0) = g(X0), file('tff_typed_lemma.p', ax2)).
tff(f3, axiom, ! [X0: person]: (g(X0) = X0 => q(X0)), file('tff_typed_lemma.p', ax3)).
tff(f4, axiom, s(a), file('tff_typed_lemma.p', ax4)).
tff(f5, axiom, ! [X0: person, X1: city]: ((home(X0) = X1 & q(X0) & s(X0)) => p(X0, X1)), file('tff_typed_lemma.p', ax5)).
tff(s1, plain, ! [X: person] : g(X) = f(X), inference(instantiate, [status(thm)], [f2])).
tff(lemma_6, lemma, ! [X: person] : g(X) = X, inference(rewrite, [status(thm)], [f1, s1])).
tff(s2, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_6])).
tff(s3, plain, q(a), inference(mp, [status(thm)], [f3, s2])).
tff(f6, theorem, p(a, home(a)), inference(mp, [status(thm)], [f5, s3, f4])).
% SZS output end Proof
