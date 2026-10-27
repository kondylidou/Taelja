% SZS output start Proof
fof(ax171, axiom, ! [X207, X208, X209, X210, X211]: ((pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X210, X209, X207)), constr_cbc_dec_1(X211, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X208, name_Kas)))) & pred_attacker(tuple_client_A_in_8(X211)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X208, name_Kas))) & pred_attacker(tuple_client_A_in_6(X208)) & pred_attacker(tuple_client_A_in_4(X210)) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X209, name_Kas))) & pred_eq_bitstring_bitstring(name_Na(X207), constr_tuple_4_get_0x30(constr_cbc_dec_4(X209, name_Kas))) & pred_attacker(tuple_client_A_in_2(X209))) => pred_attacker(tuple_client_A_out_9(name_objective))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax171)).
fof(ax83, axiom, ! [X63, X64]: pred_eq_bitstring_bitstring(X63, X64), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax83)).
fof(ax120, axiom, ! [X117]: (pred_attacker(X117) => pred_attacker(tuple_client_A_in_8(X117))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax120)).
fof(ax122, axiom, ! [X119]: (pred_attacker(X119) => pred_attacker(tuple_client_A_in_6(X119))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax122)).
fof(ax124, axiom, ! [X121]: (pred_attacker(X121) => pred_attacker(tuple_client_A_in_4(X121))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax124)).
fof(ax126, axiom, ! [X123]: (pred_attacker(X123) => pred_attacker(tuple_client_A_in_2(X123))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax126)).
fof(ax119, axiom, ! [X114, X115, X116]: (pred_attacker(tuple_client_A_out_1(X114, X115, X116)) => pred_attacker(X116)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax119)).
fof(ax167, axiom, ! [X197]: pred_attacker(tuple_client_A_out_1(name_A, name_B, name_Na(X197))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax167)).
fof(ax109, axiom, ! [X98]: (pred_attacker(tuple_client_A_out_9(X98)) => pred_attacker(X98)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SWW/SWW967+1.p', ax109)).
fof(lemma_10, lemma, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax119, ax167])).
fof(lemma_11, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(name_Na(X))), inference(mp, [status(thm)], [ax120, lemma_10])).
fof(lemma_12, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(name_Na(X))), inference(mp, [status(thm)], [ax122, lemma_10])).
fof(lemma_13, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(name_Na(X))), inference(mp, [status(thm)], [ax124, lemma_10])).
fof(lemma_14, lemma, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax126, lemma_10])).
fof(s1, plain, ! [X,Y,Z,A,B] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(name_Na(X),name_Na(Y),Z)),constr_cbc_dec_1(name_Na(A),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(name_Na(B),name_Kas)))), inference(instantiate, [status(thm)], [ax83])).
fof(s2, plain, ! [B] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(name_Na(B),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s3, plain, ! [Y] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(name_Na(Y),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s4, plain, ! [Z,Y] : pred_eq_bitstring_bitstring(name_Na(Z),constr_tuple_4_get_0x30(constr_cbc_dec_4(name_Na(Y),name_Kas))), inference(instantiate, [status(thm)], [ax83])).
fof(s5, plain, pred_attacker(tuple_client_A_out_9(name_objective)), inference(mp, [status(thm)], [ax171, s1, lemma_11, s2, lemma_12, lemma_13, s3, s4, lemma_14])).
fof(co0, theorem, pred_attacker(name_objective), inference(mp, [status(thm)], [ax109, s5])).
% SZS output end Proof
