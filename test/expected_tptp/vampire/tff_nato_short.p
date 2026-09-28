% SZS output start Proof
tff(type_def_5, type, country: $tType).
tff(func_def_0, type, sweden: country).
tff(func_def_1, type, germany: country).
tff(pred_def_1, type, nato: country > $o).
tff(pred_def_2, type, attacked: country > $o).
tff(pred_def_3, type, protects: (country * country) > $o).
tff(f1, axiom, ! [X0: country, X1: country]: ((nato(X0) & nato(X1) & attacked(X1)) => protects(X0, X1)), file('test/input/tff_nato_short.p')).
tff(f2, axiom, nato(sweden), file('test/input/tff_nato_short.p')).
tff(f3, axiom, nato(germany), file('test/input/tff_nato_short.p')).
tff(f4, axiom, attacked(germany), file('test/input/tff_nato_short.p')).
tff(f5, theorem, protects(sweden, germany), inference(mp, [status(thm)], [f1, f2, f3, f4])).
% SZS output end Proof
