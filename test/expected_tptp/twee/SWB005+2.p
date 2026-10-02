% SZS output start Proof
cnf(c5, axiom, ir(X), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', simple_ir)).
fof(c6, axiom, ! [X2]: (ir(X2) <=> icext(uri_rdfs_Resource, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', rdfs_ir_def)).
fof(c10, axiom, ! [C, X2]: (iext(uri_rdf_type, X2, C) <=> icext(C, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', rdfs_cext_def)).
fof(c16, axiom, ! [X2]: (icext(uri_owl_Thing, X2) <=> ir(X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', owl_class_thing_ext)).
cnf(c29, axiom, iext(uri_ex_p, uri_ex_s, uri_ex_o), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', testcase_premise_fullish_005_Everything_is_a_Resource)).
fof(c30, axiom, ! [S, P, O]: (iext(P, S, O) => ip(P)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', simple_iext_property)).
fof(c36, axiom, ! [P2]: (iext(uri_rdf_type, P2, uri_rdf_Property) <=> ip(P2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', rdf_type_ip)).
fof(c55, axiom, ! [X2]: (icext(uri_owl_ObjectProperty, X2) <=> ip(X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWB/SWB005+2.p', owl_class_objectproperty_ext)).
fof(axiom_2, plain, ! [Y] : (ir(Y) => icext(uri_rdfs_Resource,Y)), inference(clausify, [status(thm)], [c6])).
fof(axiom_3, plain, ! [Z,Y] : (icext(Z,Y) => iext(uri_rdf_type,Y,Z)), inference(clausify, [status(thm)], [c10])).
fof(axiom_4, plain, ! [Y] : (ir(Y) => icext(uri_owl_Thing,Y)), inference(clausify, [status(thm)], [c16])).
fof(axiom_7, plain, ! [Y] : (ip(Y) => icext(uri_owl_ObjectProperty,Y)), inference(clausify, [status(thm)], [c55])).
fof(axiom_8, plain, ! [U] : (ip(U) => iext(uri_rdf_type,U,uri_rdf_Property)), inference(clausify, [status(thm)], [c36])).
fof(s1, plain, ir(uri_ex_s), inference(instantiate, [status(thm)], [c5])).
fof(s2, plain, icext(uri_rdfs_Resource,uri_ex_s), inference(mp, [status(thm)], [axiom_2, s1])).
fof(s3, plain, iext(uri_rdf_type,uri_ex_s,uri_rdfs_Resource), inference(mp, [status(thm)], [axiom_3, s2])).
fof(s4, plain, ir(uri_ex_s), inference(instantiate, [status(thm)], [c5])).
fof(s5, plain, icext(uri_owl_Thing,uri_ex_s), inference(mp, [status(thm)], [axiom_4, s4])).
fof(s6, plain, iext(uri_rdf_type,uri_ex_s,uri_owl_Thing), inference(mp, [status(thm)], [axiom_3, s5])).
fof(s7, plain, ir(uri_ex_p), inference(instantiate, [status(thm)], [c5])).
fof(s8, plain, icext(uri_rdfs_Resource,uri_ex_p), inference(mp, [status(thm)], [axiom_2, s7])).
fof(s9, plain, iext(uri_rdf_type,uri_ex_p,uri_rdfs_Resource), inference(mp, [status(thm)], [axiom_3, s8])).
fof(s10, plain, ir(uri_ex_p), inference(instantiate, [status(thm)], [c5])).
fof(s11, plain, icext(uri_owl_Thing,uri_ex_p), inference(mp, [status(thm)], [axiom_4, s10])).
fof(s12, plain, iext(uri_rdf_type,uri_ex_p,uri_owl_Thing), inference(mp, [status(thm)], [axiom_3, s11])).
fof(s13, plain, ip(uri_ex_p), inference(mp, [status(thm)], [c30, c29])).
fof(s14, plain, iext(uri_rdf_type,uri_ex_p,uri_rdf_Property), inference(mp, [status(thm)], [axiom_8, s13])).
fof(s15, plain, ip(uri_ex_p), inference(mp, [status(thm)], [c30, c29])).
fof(s16, plain, icext(uri_owl_ObjectProperty,uri_ex_p), inference(mp, [status(thm)], [axiom_7, s15])).
fof(s17, plain, iext(uri_rdf_type,uri_ex_p,uri_owl_ObjectProperty), inference(mp, [status(thm)], [axiom_3, s16])).
fof(s18, plain, ir(uri_ex_o), inference(instantiate, [status(thm)], [c5])).
fof(s19, plain, icext(uri_rdfs_Resource,uri_ex_o), inference(mp, [status(thm)], [axiom_2, s18])).
fof(s20, plain, iext(uri_rdf_type,uri_ex_o,uri_rdfs_Resource), inference(mp, [status(thm)], [axiom_3, s19])).
fof(s21, plain, ir(uri_ex_o), inference(instantiate, [status(thm)], [c5])).
fof(s22, plain, icext(uri_owl_Thing,uri_ex_o), inference(mp, [status(thm)], [axiom_4, s21])).
fof(s23, plain, iext(uri_rdf_type,uri_ex_o,uri_owl_Thing), inference(mp, [status(thm)], [axiom_3, s22])).
fof(c1, theorem, iext(uri_rdf_type, uri_ex_s, uri_rdfs_Resource) & iext(uri_rdf_type, uri_ex_s, uri_owl_Thing) & iext(uri_rdf_type, uri_ex_p, uri_rdfs_Resource) & iext(uri_rdf_type, uri_ex_p, uri_owl_Thing) & iext(uri_rdf_type, uri_ex_p, uri_rdf_Property) & iext(uri_rdf_type, uri_ex_p, uri_owl_ObjectProperty) & iext(uri_rdf_type, uri_ex_o, uri_rdfs_Resource) & iext(uri_rdf_type, uri_ex_o, uri_owl_Thing), inference(conclude, [status(thm)], [s3, s6, s9, s12, s14, s17, s20, s23])).
% SZS output end Proof
