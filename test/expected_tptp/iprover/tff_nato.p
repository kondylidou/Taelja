% SZS output start Proof
tff(type_def_5, type, country: $tType).
tff(func_def_0, type, sweden: country).
tff(pred_def_1, type, nato_member: country > $o).
tff(pred_def_2, type, attacked: (country * country) > $o).
tff(pred_def_3, type, protects: (country * country) > $o).
tff(taelja_type_germany, type, germany: country).
tff(taelja_type_russia, type, russia: country).
tff(f1, axiom, ! [X0: country, X1: country, X2: country]: ((attacked(X2, X1) & nato_member(X1) & nato_member(X0)) => protects(X0, X1)), file('tff_nato.p', nato_protection)).
tff(f2, axiom, nato_member(sweden), file('tff_nato.p', sweden_nato_member)).
tff(f3, axiom, nato_member(germany), file('tff_nato.p', germany_nato_member)).
tff(f4, axiom, attacked(russia, germany), file('tff_nato.p', russia_attacked_germany)).
tff(f5, theorem, protects(sweden, germany), inference(mp, [status(thm)], [f1, f4, f3, f2])).
% SZS output end Proof
