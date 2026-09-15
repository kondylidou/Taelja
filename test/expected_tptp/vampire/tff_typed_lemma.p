% SZS output start Proof
tff(type_def_5, type, person: $tType).
tff(type_def_6, type, city: $tType).
tff(func_def_0, type, a: person).
tff(func_def_1, type, f: person > person).
tff(func_def_2, type, g: person > person).
tff(func_def_3, type, home: person > city).
tff(pred_def_1, type, q: person > $o).
tff(pred_def_2, type, s: person > $o).
tff(pred_def_3, type, p: (person * city) > $o).
tff(f1, axiom, ! [X0: person]: f(X0) = X0, file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/nato/typed3.p')).
tff(f2, axiom, ! [X0: person]: g(X0) = f(X0), file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/nato/typed3.p')).
tff(f3, axiom, ! [X0: person]: (g(X0) = X0 => q(X0)), file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/nato/typed3.p')).
tff(f4, axiom, s(a), file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/nato/typed3.p')).
tff(f5, axiom, ! [X0: person, X1: city]: ((s(X0) & q(X0) & X1 = home(X0)) => p(X0, X1)), file('/private/tmp/claude-501/-Users-kondylidou-Developer-Taelja/86a13e38-6767-4fc5-ad36-f71491dfe6c5/scratchpad/nato/typed3.p')).
tff(lemma_6, lemma, ! [X: person] : g(X) = X, inference(rewrite, [status(thm)], [f1, f2])).
tff(s1, plain, g(a) = a, inference(instantiate, [status(thm)], [lemma_6])).
tff(lemma_7, lemma, q(a), inference(mp, [status(thm)], [f3, s1])).
tff(f6, theorem, p(a, home(a)), inference(mp, [status(thm)], [f5, f4, lemma_7])).
% SZS output end Proof
