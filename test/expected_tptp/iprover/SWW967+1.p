% SZS output start Proof
fof(f84, axiom, ! [X62, X63]: pred_eq_bitstring_bitstring(X62, X63), file('Problems/SWW/SWW967+1.p', ax83)).
fof(f110, axiom, ! [X97]: (pred_attacker(tuple_client_A_out_9(X97)) => pred_attacker(X97)), file('Problems/SWW/SWW967+1.p', ax109)).
fof(f120, axiom, ! [X113, X114, X115]: (pred_attacker(tuple_client_A_out_1(X113, X114, X115)) => pred_attacker(X115)), file('Problems/SWW/SWW967+1.p', ax119)).
fof(f121, axiom, ! [X116]: (pred_attacker(X116) => pred_attacker(tuple_client_A_in_8(X116))), file('Problems/SWW/SWW967+1.p', ax120)).
fof(f123, axiom, ! [X118]: (pred_attacker(X118) => pred_attacker(tuple_client_A_in_6(X118))), file('Problems/SWW/SWW967+1.p', ax122)).
fof(f125, axiom, ! [X120]: (pred_attacker(X120) => pred_attacker(tuple_client_A_in_4(X120))), file('Problems/SWW/SWW967+1.p', ax124)).
fof(f127, axiom, ! [X122]: (pred_attacker(X122) => pred_attacker(tuple_client_A_in_2(X122))), file('Problems/SWW/SWW967+1.p', ax126)).
fof(f168, axiom, ! [X196]: pred_attacker(tuple_client_A_out_1(name_A, name_B, name_Na(X196))), file('Problems/SWW/SWW967+1.p', ax167)).
fof(f172, axiom, ! [X206, X207, X208, X209, X210]: ((pred_attacker(tuple_client_A_in_2(X208)) & pred_eq_bitstring_bitstring(name_Na(X206), constr_tuple_4_get_0x30(constr_cbc_dec_4(X208, name_Kas))) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X208, name_Kas))) & pred_attacker(tuple_client_A_in_4(X209)) & pred_attacker(tuple_client_A_in_6(X207)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X207, name_Kas))) & pred_attacker(tuple_client_A_in_8(X210)) & pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X209, X208, X206)), constr_cbc_dec_1(X210, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X207, name_Kas))))) => pred_attacker(tuple_client_A_out_9(name_objective))), file('Problems/SWW/SWW967+1.p', ax171)).
fof(lemma_10, lemma, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [f120, f168])).
fof(lemma_11, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(name_Na(X))), inference(mp, [status(thm)], [f125, lemma_10])).
fof(lemma_12, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(name_Na(X))), inference(mp, [status(thm)], [f123, lemma_10])).
fof(lemma_13, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(name_Na(X))), inference(mp, [status(thm)], [f121, lemma_10])).
fof(s1, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [f127, lemma_10])).
fof(s2, plain, ! [Y,X] : pred_eq_bitstring_bitstring(name_Na(Y),constr_tuple_4_get_0x30(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [f84])).
fof(s3, plain, ! [X] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [f84])).
fof(s4, plain, ! [A] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(name_Na(A),name_Kas))), inference(instantiate, [status(thm)], [f84])).
fof(s5, plain, ! [Z,X,Y,B,A] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(name_Na(Z),name_Na(X),Y)),constr_cbc_dec_1(name_Na(B),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(name_Na(A),name_Kas)))), inference(instantiate, [status(thm)], [f84])).
fof(s6, plain, pred_attacker(tuple_client_A_out_9(name_objective)), inference(mp, [status(thm)], [f172, s1, s2, s3, lemma_11, lemma_12, s4, lemma_13, s5])).
fof(f175, theorem, pred_attacker(name_objective), inference(mp, [status(thm)], [f110, s6])).
% SZS output end Proof
