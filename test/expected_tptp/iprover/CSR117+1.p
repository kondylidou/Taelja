% SZS output start Proof
fof(f15, axiom, ! [X0]: (s__Region(X0) => s__Object(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_701)).
fof(f16, axiom, ! [X0]: (s__GeographicArea(X0) => s__Region(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6365)).
fof(f17, axiom, ! [X0]: (s__GeopoliticalArea(X0) => s__GeographicArea(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6345)).
fof(f18, axiom, ! [X0]: (s__Nation(X0) => s__GeopoliticalArea(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6428)).
fof(f19, axiom, ! [X0]: (s__City(X0) => s__GeopoliticalArea(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6437)).
fof(f21, axiom, ! [X0]: (s__BodyOfWater(X0) => s__WaterArea(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_Domains_9582)).
fof(f22, axiom, ! [X0]: (s__Sea(X0) => s__BodyOfWater(X0)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_Domains_9679)).
fof(f27, axiom, ! [X1]: (s__City(X1) => (is_instance(X1, s__CoastalCitiesClass) => ? [X2]: (s__orientation(X1, X2, s__Near) & s__Sea(X2)))), file('Problems/CSR/CSR117+1.p', coastal_cities_near_water)).
fof(f28, axiom, ! [X3, X4]: ((s__City(X4) & s__WaterArea(X3)) => (s__orientation(X4, X3, s__Near) => s__capability(s__Flooding__t, s__located__m, X4))), file('Problems/CSR/CSR117+1.p', flood_near_water)).
fof(f32, axiom, ? [X0]: int(X0), file('Problems/CSR/CSR117+1.p', int_type)).
fof(f35, axiom, is_instance(s__Copenhagen, s__CoastalCitiesClass), file('Problems/CSR/CSR117+1.p', copenhagen_coastal)).
fof(f40, axiom, s__Nation(s__Denmark), file('Problems/CSR/CSR117+1.p', s__Denmark_type)).
fof(f41, axiom, is_instance(s__Denmark, s__OECDMemberEconomiesClass), file('Problems/CSR/CSR117+1.p', s__Denmark_OECD)).
fof(f102, axiom, s__City(s__Copenhagen), file('Problems/CSR/CSR117+1.p', s__Copenhagen_type)).
fof(f103, axiom, capital_city(s__Copenhagen, s__Denmark), file('Problems/CSR/CSR117+1.p', s__Copenhagen_s__Denmark)).
fof(f150, axiom, real('55.67631'), file('Problems/CSR/CSR117+1.p', copenhagen_lat_type)).
fof(f151, axiom, real('12.569355'), file('Problems/CSR/CSR117+1.p', copenhagen_long_type)).
fof(f152, axiom, s__SymbolicString(copenhagen), file('Problems/CSR/CSR117+1.p', copenhagen_type)).
fof(f153, axiom, s__SymbolicString(dk), file('Problems/CSR/CSR117+1.p', dk_type)).
fof(f154, axiom, latlong(s__Copenhagen, '55.67631', '12.569355', copenhagen, dk), file('Problems/CSR/CSR117+1.p', latlong_s__Copenhagen)).
fof(f170, axiom, real('55.75695'), file('Problems/CSR/CSR117+1.p', moscow_lat_type)).
fof(f171, axiom, real('37.614975'), file('Problems/CSR/CSR117+1.p', moscow_long_type)).
fof(f172, axiom, s__SymbolicString(moscow), file('Problems/CSR/CSR117+1.p', moscow_type)).
fof(f173, axiom, s__SymbolicString(ru), file('Problems/CSR/CSR117+1.p', ru_type)).
fof(f174, axiom, latlong(s__Moscow, '55.75695', '37.614975', moscow, ru), file('Problems/CSR/CSR117+1.p', latlong_s__Moscow)).
fof(f206, axiom, look_different(s__Copenhagen, s__Moscow), file('Problems/CSR/CSR117+1.p', s__Copenhagen_not_s__Moscow)).
fof(f237, axiom, '55' = to_int('55.67631'), file('Problems/CSR/CSR117+1.p', '55.67631_55')).
fof(f238, axiom, '55' = to_int('55.75695'), file('Problems/CSR/CSR117+1.p', '55.75695_55')).
fof(f347, plain, ! [X0]: (? [X1]: (s__orientation(X0, X1, s__Near) & s__Sea(X1)) => (s__orientation(X0, sK14(X0), s__Near) & s__Sea(sK14(X0)))), introduced(choice_axiom, [new_symbols(definition, [sK14])], [])).
fof(f351, plain, ? [X0]: int(X0) => int(sK16), introduced(choice_axiom, [new_symbols(definition, [sK16])], [])).
fof(axiom_14, plain, ! [X] : ((is_instance(X,s__CoastalCitiesClass) & s__City(X)) => s__Sea(sK14(X))), inference(clausify, [status(thm)], [f27, f347])).
fof(axiom_17, plain, ! [X] : ((is_instance(X,s__CoastalCitiesClass) & s__City(X)) => s__orientation(X,sK14(X),s__Near)), inference(clausify, [status(thm)], [f27, f347])).
fof(axiom_29, plain, int(sK16), inference(clausify, [status(thm)], [f32, f351])).
fof(s1, plain, ! [X] : (s__GeopoliticalArea(X) => s__GeopoliticalArea(X)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X] : (s__GeopoliticalArea(X) => s__GeographicArea(X)), inference(mp, [status(thm)], [f17, s1])).
fof(s3, plain, ! [X] : (s__GeopoliticalArea(X) => s__Region(X)), inference(mp, [status(thm)], [f16, s2])).
fof(lemma_30, lemma, ! [X] : (s__GeopoliticalArea(X) => s__Object(X)), inference(mp, [status(thm)], [f15, s3])).
fof(s4, plain, s__Sea(sK14(s__Copenhagen)), inference(mp, [status(thm)], [axiom_14, f35, f102])).
fof(s5, plain, s__BodyOfWater(sK14(s__Copenhagen)), inference(mp, [status(thm)], [f22, s4])).
fof(lemma_31, lemma, s__WaterArea(sK14(s__Copenhagen)), inference(mp, [status(thm)], [f21, s5])).
fof(lemma_32, lemma, s__orientation(s__Copenhagen,sK14(s__Copenhagen),s__Near), inference(mp, [status(thm)], [axiom_17, f35, f102])).
fof(s6, plain, s__capability(s__Flooding__t,s__located__m,s__Copenhagen), inference(mp, [status(thm)], [f28, f102, lemma_31, lemma_32])).
fof(s7, plain, to_int('55.67631') = '55', inference(instantiate, [status(thm)], [f237])).
fof(s8, plain, to_int('55.67631') = to_int('55.75695'), inference(rewrite, [status(thm)], [f238, s7])).
fof(s9, plain, latlong(s__Moscow,'55.75695','37.614975',moscow,ru), inference(instantiate, [status(thm)], [f174])).
fof(s10, plain, latlong(s__Copenhagen,'55.67631','12.569355',copenhagen,dk), inference(instantiate, [status(thm)], [f154])).
fof(s11, plain, look_different(s__Copenhagen,s__Moscow), inference(instantiate, [status(thm)], [f206])).
fof(s12, plain, capital_city(s__Copenhagen,s__Denmark), inference(instantiate, [status(thm)], [f103])).
fof(s13, plain, is_instance(s__Denmark,s__OECDMemberEconomiesClass), inference(instantiate, [status(thm)], [f41])).
fof(s14, plain, s__SymbolicString(ru), inference(instantiate, [status(thm)], [f173])).
fof(s15, plain, s__SymbolicString(moscow), inference(instantiate, [status(thm)], [f172])).
fof(s16, plain, real('37.614975'), inference(instantiate, [status(thm)], [f171])).
fof(s17, plain, real('55.75695'), inference(instantiate, [status(thm)], [f170])).
fof(s18, plain, int(sK16), inference(instantiate, [status(thm)], [axiom_29])).
fof(s19, plain, s__SymbolicString(dk), inference(instantiate, [status(thm)], [f153])).
fof(s20, plain, s__SymbolicString(copenhagen), inference(instantiate, [status(thm)], [f152])).
fof(s21, plain, real('12.569355'), inference(instantiate, [status(thm)], [f151])).
fof(s22, plain, real('55.67631'), inference(instantiate, [status(thm)], [f150])).
fof(s23, plain, s__GeopoliticalArea(s__Denmark), inference(mp, [status(thm)], [f18, f40])).
fof(s24, plain, s__Object(s__Denmark), inference(mp, [status(thm)], [lemma_30, s23])).
fof(s25, plain, s__GeopoliticalArea(s__Copenhagen), inference(mp, [status(thm)], [f19, f102])).
fof(s26, plain, s__Object(s__Copenhagen), inference(mp, [status(thm)], [lemma_30, s25])).
fof(f29, theorem, ? [X1, X5, X6, X7, X8, X9, X10, X11, X12, X13, X14]: (s__capability(s__Flooding__t, s__located__m, X1) & to_int(X6) = to_int(X11) & latlong(s__Moscow, X11, X12, X13, X14) & latlong(X1, X6, X7, X8, X9) & look_different(X1, s__Moscow) & capital_city(X1, X5) & is_instance(X5, s__OECDMemberEconomiesClass) & s__SymbolicString(X14) & s__SymbolicString(X13) & real(X12) & real(X11) & int(X10) & s__SymbolicString(X9) & s__SymbolicString(X8) & real(X7) & real(X6) & s__Object(X5) & s__Object(X1)), inference(conclude, [status(thm)], [s6, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s24, s26])).
% SZS output end Proof
