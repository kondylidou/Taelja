% SZS output start Proof
fof(ax171, axiom, ! [X207, X208, X209, X210, X211]: ((pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X210, X209, X207)), constr_cbc_dec_1(X211, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X208, name_Kas)))) & pred_attacker(tuple_client_A_in_8(X211)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X208, name_Kas))) & pred_attacker(tuple_client_A_in_6(X208)) & pred_attacker(tuple_client_A_in_4(X210)) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X209, name_Kas))) & pred_eq_bitstring_bitstring(name_Na(X207), constr_tuple_4_get_0x30(constr_cbc_dec_4(X209, name_Kas))) & pred_attacker(tuple_client_A_in_2(X209))) => pred_attacker(tuple_client_A_out_9(name_objective))), file('Problems/SWW/SWW967+1.p', ax171)).
fof(ax83, axiom, ! [X63, X64]: pred_eq_bitstring_bitstring(X63, X64), file('Problems/SWW/SWW967+1.p', ax83)).
fof(ax120, axiom, ! [X117]: (pred_attacker(X117) => pred_attacker(tuple_client_A_in_8(X117))), file('Problems/SWW/SWW967+1.p', ax120)).
fof(ax122, axiom, ! [X119]: (pred_attacker(X119) => pred_attacker(tuple_client_A_in_6(X119))), file('Problems/SWW/SWW967+1.p', ax122)).
fof(ax124, axiom, ! [X121]: (pred_attacker(X121) => pred_attacker(tuple_client_A_in_4(X121))), file('Problems/SWW/SWW967+1.p', ax124)).
fof(ax126, axiom, ! [X123]: (pred_attacker(X123) => pred_attacker(tuple_client_A_in_2(X123))), file('Problems/SWW/SWW967+1.p', ax126)).
fof(ax119, axiom, ! [X114, X115, X116]: (pred_attacker(tuple_client_A_out_1(X114, X115, X116)) => pred_attacker(X116)), file('Problems/SWW/SWW967+1.p', ax119)).
fof(ax167, axiom, ! [X197]: pred_attacker(tuple_client_A_out_1(name_A, name_B, name_Na(X197))), file('Problems/SWW/SWW967+1.p', ax167)).
fof(ax109, axiom, ! [X98]: (pred_attacker(tuple_client_A_out_9(X98)) => pred_attacker(X98)), file('Problems/SWW/SWW967+1.p', ax109)).
fof(s1, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax119, ax167])).
fof(s2, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax126, s1])).
fof(s3, plain, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax124, s2])).
fof(s4, plain, ! [X] : pred_attacker(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))))), inference(mp, [status(thm)], [ax122, s3])).
fof(lemma_10, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))))), inference(mp, [status(thm)], [ax120, s4])).
fof(s5, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax119, ax167])).
fof(s6, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax126, s5])).
fof(s7, plain, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax124, s6])).
fof(lemma_11, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))))), inference(mp, [status(thm)], [ax122, s7])).
fof(s8, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax119, ax167])).
fof(s9, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax126, s8])).
fof(lemma_12, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax124, s9])).
fof(s10, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax119, ax167])).
fof(lemma_13, lemma, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax126, s10])).
fof(s11, plain, ! [X,Y] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(tuple_client_A_in_2(name_Na(X)),name_Na(X),Y)),constr_cbc_dec_1(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))),name_Kas)))), inference(instantiate, [status(thm)], [ax83])).
fof(s12, plain, ! [X] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s13, plain, ! [X] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s14, plain, ! [Y,X] : pred_eq_bitstring_bitstring(name_Na(Y),constr_tuple_4_get_0x30(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s15, plain, pred_attacker(tuple_client_A_out_9(name_objective)), inference(mp, [status(thm)], [ax171, s11, lemma_10, s12, lemma_11, lemma_12, s13, s14, lemma_13])).
fof(co0, theorem, pred_attacker(name_objective), inference(mp, [status(thm)], [ax109, s15])).
% SZS output end Proof
