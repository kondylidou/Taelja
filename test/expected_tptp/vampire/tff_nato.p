% SZS output start Proof
tff(type_def_5, type, country: $tType).
tff(func_def_0, type, sweden: country).
tff(func_def_1, type, germany: country).
tff(func_def_2, type, russia: country).
tff(pred_def_1, type, nato_member: country > $o).
tff(pred_def_2, type, attacked: (country * country) > $o).
tff(pred_def_3, type, protects: (country * country) > $o).
tff(f1, axiom, ! [X0: country, X1: country, X2: country]: ((nato_member(X0) & nato_member(X1) & attacked(X2, X1)) => protects(X0, X1)), file('/tmp/pc7C9zx0G4/SOT_Yknvq2')).
tff(f2, axiom, nato_member(sweden), file('/tmp/pc7C9zx0G4/SOT_Yknvq2')).
tff(f3, axiom, nato_member(germany), file('/tmp/pc7C9zx0G4/SOT_Yknvq2')).
tff(f4, axiom, attacked(russia, germany), file('/tmp/pc7C9zx0G4/SOT_Yknvq2')).
tff(f5, theorem, protects(sweden, germany), inference(mp, [status(thm)], [f1, f2, f3, f4])).
% SZS output end Proof
