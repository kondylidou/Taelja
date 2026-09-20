% SZS output start Proof
fof(kb_SUMO_MILO_Domains_9679, axiom, ! [X1]: (s__Sea(X1) => s__BodyOfWater(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_Domains_9679)).
fof(coastal_cities_near_water, axiom, ! [X2]: (s__City(X2) => (is_instance(X2, s__CoastalCitiesClass) => ? [X3]: (s__Sea(X3) & s__orientation(X2, X3, s__Near)))), file('Problems/CSR/CSR117+1.p', coastal_cities_near_water)).
fof(kb_SUMO_MILO_Domains_9582, axiom, ! [X1]: (s__BodyOfWater(X1) => s__WaterArea(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_Domains_9582)).
fof(kb_SUMO_MILO_6365, axiom, ! [X1]: (s__GeographicArea(X1) => s__Region(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6365)).
fof(kb_SUMO_MILO_6345, axiom, ! [X1]: (s__GeopoliticalArea(X1) => s__GeographicArea(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6345)).
fof(latlong_s__Moscow, axiom, latlong(s__Moscow, '55.75695', '37.614975', moscow, ru), file('Problems/CSR/CSR117+1.p', latlong_s__Moscow)).
fof('55.75695_55', axiom, to_int('55.75695') = '55', file('Problems/CSR/CSR117+1.p', '55.75695_55')).
fof(moscow_long_type, axiom, real('37.614975'), file('Problems/CSR/CSR117+1.p', moscow_long_type)).
fof(moscow_lat_type, axiom, real('55.75695'), file('Problems/CSR/CSR117+1.p', moscow_lat_type)).
fof(ru_type, axiom, s__SymbolicString(ru), file('Problems/CSR/CSR117+1.p', ru_type)).
fof(moscow_type, axiom, s__SymbolicString(moscow), file('Problems/CSR/CSR117+1.p', moscow_type)).
fof(flood_near_water, axiom, ! [X4, X5]: ((s__WaterArea(X4) & s__City(X5)) => (s__orientation(X5, X4, s__Near) => s__capability(s__Flooding__t, s__located__m, X5))), file('Problems/CSR/CSR117+1.p', flood_near_water)).
fof(kb_SUMO_MILO_701, axiom, ! [X1]: (s__Region(X1) => s__Object(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_701)).
fof(latlong_s__Copenhagen, axiom, latlong(s__Copenhagen, '55.67631', '12.569355', copenhagen, dk), file('Problems/CSR/CSR117+1.p', latlong_s__Copenhagen)).
fof('55.67631_55', axiom, to_int('55.67631') = '55', file('Problems/CSR/CSR117+1.p', '55.67631_55')).
fof(s__Copenhagen_not_s__Moscow, axiom, look_different(s__Copenhagen, s__Moscow), file('Problems/CSR/CSR117+1.p', s__Copenhagen_not_s__Moscow)).
fof(copenhagen_long_type, axiom, real('12.569355'), file('Problems/CSR/CSR117+1.p', copenhagen_long_type)).
fof(copenhagen_lat_type, axiom, real('55.67631'), file('Problems/CSR/CSR117+1.p', copenhagen_lat_type)).
fof(dk_type, axiom, s__SymbolicString(dk), file('Problems/CSR/CSR117+1.p', dk_type)).
fof(copenhagen_type, axiom, s__SymbolicString(copenhagen), file('Problems/CSR/CSR117+1.p', copenhagen_type)).
fof(kb_SUMO_MILO_6437, axiom, ! [X1]: (s__City(X1) => s__GeopoliticalArea(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6437)).
fof(copenhagen_coastal, axiom, is_instance(s__Copenhagen, s__CoastalCitiesClass), file('Problems/CSR/CSR117+1.p', copenhagen_coastal)).
fof(s__Copenhagen_type, axiom, s__City(s__Copenhagen), file('Problems/CSR/CSR117+1.p', s__Copenhagen_type)).
fof(int_type, axiom, ? [X1]: int(X1), file('Problems/CSR/CSR117+1.p', int_type)).
fof(kb_SUMO_MILO_6428, axiom, ! [X1]: (s__Nation(X1) => s__GeopoliticalArea(X1)), file('Problems/CSR/CSR117+1.p', kb_SUMO_MILO_6428)).
fof(s__Copenhagen_s__Denmark, axiom, capital_city(s__Copenhagen, s__Denmark), file('Problems/CSR/CSR117+1.p', s__Copenhagen_s__Denmark)).
fof(s__Denmark_OECD, axiom, is_instance(s__Denmark, s__OECDMemberEconomiesClass), file('Problems/CSR/CSR117+1.p', s__Denmark_OECD)).
fof(s__Denmark_type, axiom, s__Nation(s__Denmark), file('Problems/CSR/CSR117+1.p', s__Denmark_type)).
fof(skolem_c_0_73, definition, ? [X1]: int(X1) => int(esk17_0), introduced(definition, [new_symbols(definition, [esk17_0])], [])).
fof(skolem_c_0_31, definition, ! [X2]: (s__City(X2) => (is_instance(X2, s__CoastalCitiesClass) => ? [X3]: (s__Sea(X3) & s__orientation(X2, X3, s__Near)))) => ! [X39]: ((s__Sea(esk15_1(X39)) | ~ is_instance(X39, s__CoastalCitiesClass) | ~ s__City(X39)) & (s__orientation(X39, esk15_1(X39), s__Near) | ~ is_instance(X39, s__CoastalCitiesClass) | ~ s__City(X39))), introduced(definition, [new_symbols(definition, [esk15_1])], [])).
fof(axiom_8, plain, int(esk17_0), inference(clausify, [status(thm)], [int_type, skolem_c_0_73])).
fof(axiom_12, plain, ! [X] : ((is_instance(X,s__CoastalCitiesClass) & s__City(X)) => s__orientation(X,esk15_1(X),s__Near)), inference(clausify, [status(thm)], [coastal_cities_near_water, skolem_c_0_31])).
fof(axiom_14, plain, ! [X] : ((is_instance(X,s__CoastalCitiesClass) & s__City(X)) => s__Sea(esk15_1(X))), inference(clausify, [status(thm)], [coastal_cities_near_water, skolem_c_0_31])).
fof(lemma_30, lemma, s__orientation(s__Copenhagen,esk15_1(s__Copenhagen),s__Near), inference(mp, [status(thm)], [axiom_12, copenhagen_coastal, s__Copenhagen_type])).
fof(s1, plain, s__GeopoliticalArea(s__Denmark), inference(mp, [status(thm)], [kb_SUMO_MILO_6428, s__Denmark_type])).
fof(s2, plain, s__GeographicArea(s__Denmark), inference(mp, [status(thm)], [kb_SUMO_MILO_6345, s1])).
fof(s3, plain, s__Region(s__Denmark), inference(mp, [status(thm)], [kb_SUMO_MILO_6365, s2])).
fof(s4, plain, s__Object(s__Denmark), inference(mp, [status(thm)], [kb_SUMO_MILO_701, s3])).
fof(s5, plain, s__GeopoliticalArea(s__Copenhagen), inference(mp, [status(thm)], [kb_SUMO_MILO_6437, s__Copenhagen_type])).
fof(s6, plain, s__GeographicArea(s__Copenhagen), inference(mp, [status(thm)], [kb_SUMO_MILO_6345, s5])).
fof(s7, plain, s__Region(s__Copenhagen), inference(mp, [status(thm)], [kb_SUMO_MILO_6365, s6])).
fof(s8, plain, s__Object(s__Copenhagen), inference(mp, [status(thm)], [kb_SUMO_MILO_701, s7])).
fof(s9, plain, real('55.67631'), inference(instantiate, [status(thm)], [copenhagen_lat_type])).
fof(s10, plain, real('12.569355'), inference(instantiate, [status(thm)], [copenhagen_long_type])).
fof(s11, plain, s__SymbolicString(copenhagen), inference(instantiate, [status(thm)], [copenhagen_type])).
fof(s12, plain, s__SymbolicString(dk), inference(instantiate, [status(thm)], [dk_type])).
fof(s13, plain, int(esk17_0), inference(instantiate, [status(thm)], [axiom_8])).
fof(s14, plain, real('55.75695'), inference(instantiate, [status(thm)], [moscow_lat_type])).
fof(s15, plain, real('37.614975'), inference(instantiate, [status(thm)], [moscow_long_type])).
fof(s16, plain, s__SymbolicString(moscow), inference(instantiate, [status(thm)], [moscow_type])).
fof(s17, plain, s__SymbolicString(ru), inference(instantiate, [status(thm)], [ru_type])).
fof(s18, plain, is_instance(s__Denmark,s__OECDMemberEconomiesClass), inference(instantiate, [status(thm)], [s__Denmark_OECD])).
fof(s19, plain, capital_city(s__Copenhagen,s__Denmark), inference(instantiate, [status(thm)], [s__Copenhagen_s__Denmark])).
fof(s20, plain, look_different(s__Copenhagen,s__Moscow), inference(instantiate, [status(thm)], [s__Copenhagen_not_s__Moscow])).
fof(s21, plain, latlong(s__Copenhagen,'55.67631','12.569355',copenhagen,dk), inference(instantiate, [status(thm)], [latlong_s__Copenhagen])).
fof(s22, plain, latlong(s__Moscow,'55.75695','37.614975',moscow,ru), inference(instantiate, [status(thm)], [latlong_s__Moscow])).
fof(s23, plain, s__Sea(esk15_1(s__Copenhagen)), inference(mp, [status(thm)], [axiom_14, copenhagen_coastal, s__Copenhagen_type])).
fof(s24, plain, s__BodyOfWater(esk15_1(s__Copenhagen)), inference(mp, [status(thm)], [kb_SUMO_MILO_Domains_9679, s23])).
fof(s25, plain, s__WaterArea(esk15_1(s__Copenhagen)), inference(mp, [status(thm)], [kb_SUMO_MILO_Domains_9582, s24])).
fof(s26, plain, s__capability(s__Flooding__t,s__located__m,s__Copenhagen), inference(mp, [status(thm)], [flood_near_water, s25, s__Copenhagen_type, lemma_30])).
fof(s27, plain, to_int('55.67631') = to_int('55.75695'), inference(rewrite, [status(thm)], ['55.75695_55', '55.67631_55'])).
fof(where, theorem, ? [X2, X6, X7, X8, X9, X10, X11, X12, X13, X14, X15]: (s__Object(X2) & s__Object(X6) & real(X7) & real(X8) & s__SymbolicString(X9) & s__SymbolicString(X10) & int(X11) & real(X12) & real(X13) & s__SymbolicString(X14) & s__SymbolicString(X15) & is_instance(X6, s__OECDMemberEconomiesClass) & capital_city(X2, X6) & look_different(X2, s__Moscow) & latlong(X2, X7, X8, X9, X10) & latlong(s__Moscow, X12, X13, X14, X15) & to_int(X7) = to_int(X12) & s__capability(s__Flooding__t, s__located__m, X2)), inference(conclude, [status(thm)], [s4, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s26, s27])).
% SZS output end Proof
