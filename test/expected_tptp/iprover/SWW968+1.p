% SZS output start Proof
fof(f79, axiom, ! [X0, X1, X2, X3, X4]: constr_cbc_dec_4(constr_cbc_enc_4(X1, X2, X3, X4, X0), X0) = tuple_4(X1, X2, X3, X4), file('Problems/SWW/SWW968+1.p', ax78)).
fof(f81, axiom, ! [X9, X10, X11]: constr_cbc_dec_2(constr_cbc_enc_2(X10, X11, X9), X9) = tuple_2(X10, X11), file('Problems/SWW/SWW968+1.p', ax80)).
fof(f84, axiom, ! [X19, X20, X21, X22, X23]: constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(X20, X21, X22, X23, X19)) = constr_cbc_enc_2(X20, X21, X19), file('Problems/SWW/SWW968+1.p', ax83)).
fof(f88, axiom, ! [X37, X38, X39]: constr_cbc_2_get_1_prefixes(constr_cbc_enc_2(X38, X39, X37)) = constr_cbc_enc_1(X38, X37), file('Problems/SWW/SWW968+1.p', ax87)).
fof(f89, axiom, ! [X40, X41]: constr_dec(constr_enc(X41, X40), X40) = X41, file('Problems/SWW/SWW968+1.p', ax88)).
fof(f90, axiom, ! [X42, X43, X44, X45]: constr_tuple_4_get_3_bitstring(tuple_4(X42, X43, X44, X45)) = X45, file('Problems/SWW/SWW968+1.p', ax89)).
fof(f92, axiom, ! [X50, X51]: constr_tuple_2_get_0x30_bitstring(tuple_2(X50, X51)) = X50, file('Problems/SWW/SWW968+1.p', ax91)).
fof(f96, axiom, ! [X62, X63]: pred_eq_bitstring_bitstring(X62, X63), file('Problems/SWW/SWW968+1.p', ax95)).
fof(f103, axiom, pred_attacker(tuple_true), file('Problems/SWW/SWW968+1.p', ax102)).
fof(f107, axiom, ! [X73]: (pred_attacker(tuple_server_S_out_2(X73)) => pred_attacker(X73)), file('Problems/SWW/SWW968+1.p', ax106)).
fof(f108, axiom, ! [X74, X75, X76]: ((pred_attacker(X76) & pred_attacker(X75) & pred_attacker(X74)) => pred_attacker(tuple_server_S_in_1(X74, X75, X76))), file('Problems/SWW/SWW968+1.p', ax107)).
fof(f114, axiom, ! [X88, X89]: ((pred_attacker(X89) & pred_attacker(X88)) => pred_attacker(constr_dec(X88, X89))), file('Problems/SWW/SWW968+1.p', ax113)).
fof(f122, axiom, ! [X97]: (pred_attacker(tuple_client_A_out_9(X97)) => pred_attacker(X97)), file('Problems/SWW/SWW968+1.p', ax121)).
fof(f128, axiom, ! [X103]: (pred_attacker(tuple_client_A_out_3(X103)) => pred_attacker(X103)), file('Problems/SWW/SWW968+1.p', ax127)).
fof(f130, axiom, ! [X105]: (pred_attacker(tuple_client_A_out_10(X105)) => pred_attacker(X105)), file('Problems/SWW/SWW968+1.p', ax129)).
fof(f134, axiom, ! [X115, X116, X117]: (pred_attacker(tuple_client_A_out_1(X115, X116, X117)) => pred_attacker(X117)), file('Problems/SWW/SWW968+1.p', ax133)).
fof(f135, axiom, ! [X118]: (pred_attacker(X118) => pred_attacker(tuple_client_A_in_8(X118))), file('Problems/SWW/SWW968+1.p', ax134)).
fof(f137, axiom, ! [X120]: (pred_attacker(X120) => pred_attacker(tuple_client_A_in_6(X120))), file('Problems/SWW/SWW968+1.p', ax136)).
fof(f139, axiom, ! [X122]: (pred_attacker(X122) => pred_attacker(tuple_client_A_in_4(X122))), file('Problems/SWW/SWW968+1.p', ax138)).
fof(f141, axiom, ! [X124]: (pred_attacker(X124) => pred_attacker(tuple_client_A_in_2(X124))), file('Problems/SWW/SWW968+1.p', ax140)).
fof(f152, axiom, ! [X149]: (pred_attacker(X149) => pred_attacker(constr_cbc_4_get_2_prefixes(X149))), file('Problems/SWW/SWW968+1.p', ax151)).
fof(f156, axiom, ! [X153]: (pred_attacker(X153) => pred_attacker(constr_cbc_2_get_1_prefixes(X153))), file('Problems/SWW/SWW968+1.p', ax155)).
fof(f157, axiom, pred_attacker(constr_CONST_4), file('Problems/SWW/SWW968+1.p', ax156)).
fof(f171, axiom, ! [X186, X187]: ((pred_attacker(X187) & pred_attacker(X186)) => pred_attacker(tuple_2(X186, X187))), file('Problems/SWW/SWW968+1.p', ax170)).
fof(f182, axiom, ! [X198]: pred_attacker(tuple_client_A_out_1(name_A, name_B, name_Na(X198))), file('Problems/SWW/SWW968+1.p', ax181)).
fof(f183, axiom, ! [X199, X200]: ((pred_attacker(tuple_client_A_in_2(X200)) & pred_eq_bitstring_bitstring(name_Na(X199), constr_tuple_4_get_0x30(constr_cbc_dec_4(X200, name_Kas))) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X200, name_Kas)))) => pred_attacker(tuple_client_A_out_3(constr_tuple_4_get_3_bitstring(constr_cbc_dec_4(X200, name_Kas))))), file('Problems/SWW/SWW968+1.p', ax182)).
fof(f186, axiom, ! [X208, X209, X210, X211, X212]: ((pred_attacker(tuple_client_A_in_2(X210)) & pred_eq_bitstring_bitstring(name_Na(X208), constr_tuple_4_get_0x30(constr_cbc_dec_4(X210, name_Kas))) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X210, name_Kas))) & pred_attacker(tuple_client_A_in_4(X211)) & pred_attacker(tuple_client_A_in_6(X209)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X209, name_Kas))) & pred_attacker(tuple_client_A_in_8(X212)) & pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X211, X210, X208)), constr_cbc_dec_1(X212, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X209, name_Kas))))) => pred_attacker(tuple_client_A_out_9(name_objective1))), file('Problems/SWW/SWW968+1.p', ax185)).
fof(f187, axiom, ! [X213, X214, X215, X216, X217]: ((pred_attacker(tuple_client_A_in_2(X215)) & pred_eq_bitstring_bitstring(name_Na(X213), constr_tuple_4_get_0x30(constr_cbc_dec_4(X215, name_Kas))) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X215, name_Kas))) & pred_attacker(tuple_client_A_in_4(X216)) & pred_attacker(tuple_client_A_in_6(X214)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X214, name_Kas))) & pred_attacker(tuple_client_A_in_8(X217)) & pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X216, X215, X213)), constr_cbc_dec_1(X217, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X214, name_Kas))))) => pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X214, name_Kas)))))), file('Problems/SWW/SWW968+1.p', ax186)).
fof(f189, axiom, ! [X220, X221, X222, X223]: (pred_attacker(tuple_server_S_in_1(X221, X222, X223)) => pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(X223, X222, name_Kab_66(X220), constr_cbc_enc_2(name_Kab_66(X220), X221, name_Kbs), name_Kas)))), file('Problems/SWW/SWW968+1.p', ax188)).
fof(lemma_30, lemma, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [f134, f182])).
fof(s1, plain, ! [X,Y,Z] : (pred_attacker(tuple_server_S_in_1(X,Y,Z)) => pred_attacker(tuple_server_S_in_1(X,Y,Z))), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y,Z,A] : (pred_attacker(tuple_server_S_in_1(X,Y,Z)) => pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(Z,Y,name_Kab_66(A),constr_cbc_enc_2(name_Kab_66(A),X,name_Kbs),name_Kas)))), inference(mp, [status(thm)], [f189, s1])).
fof(lemma_31, lemma, ! [X,Y,Z,A] : (pred_attacker(tuple_server_S_in_1(X,Y,Z)) => pred_attacker(constr_cbc_enc_4(Z,Y,name_Kab_66(A),constr_cbc_enc_2(name_Kab_66(A),X,name_Kbs),name_Kas))), inference(mp, [status(thm)], [f107, s2])).
fof(s3, plain, ! [A,Z,Y] : pred_attacker(tuple_server_S_in_1(name_Na(A),name_Na(Z),name_Na(Y))), inference(mp, [status(thm)], [f108, lemma_30, lemma_30, lemma_30])).
fof(s4, plain, ! [Y,Z,X,A] : pred_attacker(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas)), inference(mp, [status(thm)], [lemma_31, s3])).
fof(s5, plain, ! [Y,Z,X,A] : pred_attacker(tuple_client_A_in_2(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas))), inference(mp, [status(thm)], [f141, s4])).
fof(s6, plain, ! [B,Y,Z,X,A] : pred_eq_bitstring_bitstring(name_Na(B),constr_tuple_4_get_0x30(constr_cbc_dec_4(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s7, plain, ! [Y,Z,X,A] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s8, plain, ! [Y,Z,X,A] : pred_attacker(tuple_client_A_out_3(constr_tuple_4_get_3_bitstring(constr_cbc_dec_4(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas),name_Kas)))), inference(mp, [status(thm)], [f183, s5, s6, s7])).
fof(s9, plain, ! [Y,Z,X,A] : pred_attacker(constr_tuple_4_get_3_bitstring(constr_cbc_dec_4(constr_cbc_enc_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs),name_Kas),name_Kas))), inference(mp, [status(thm)], [f128, s8])).
fof(s10, plain, ! [Y,Z,X,A] : pred_attacker(constr_tuple_4_get_3_bitstring(tuple_4(name_Na(Y),name_Na(Z),name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs)))), inference(rewrite, [status(thm)], [f79, s9])).
fof(s11, plain, ! [X,A] : pred_attacker(constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs)), inference(rewrite, [status(thm)], [f90, s10])).
fof(s12, plain, ! [X,A] : pred_attacker(constr_cbc_2_get_1_prefixes(constr_cbc_enc_2(name_Kab_66(X),name_Na(A),name_Kbs))), inference(mp, [status(thm)], [f156, s11])).
fof(lemma_32, lemma, ! [X] : pred_attacker(constr_cbc_enc_1(name_Kab_66(X),name_Kbs)), inference(rewrite, [status(thm)], [f88, s12])).
fof(lemma_33, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(constr_cbc_enc_1(name_Kab_66(X),name_Kbs))), inference(mp, [status(thm)], [f139, lemma_32])).
fof(s13, plain, ! [Y,X] : pred_attacker(tuple_server_S_in_1(name_Na(Y),constr_cbc_enc_1(name_Kab_66(X),name_Kbs),tuple_true)), inference(mp, [status(thm)], [f108, f103, lemma_32, lemma_30])).
fof(s14, plain, ! [X,Z,Y] : pred_attacker(constr_cbc_enc_4(tuple_true,constr_cbc_enc_1(name_Kab_66(X),name_Kbs),name_Kab_66(Z),constr_cbc_enc_2(name_Kab_66(Z),name_Na(Y),name_Kbs),name_Kas)), inference(mp, [status(thm)], [lemma_31, s13])).
fof(s15, plain, ! [X,Z,Y] : pred_attacker(constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(tuple_true,constr_cbc_enc_1(name_Kab_66(X),name_Kbs),name_Kab_66(Z),constr_cbc_enc_2(name_Kab_66(Z),name_Na(Y),name_Kbs),name_Kas))), inference(mp, [status(thm)], [f152, s14])).
fof(s16, plain, ! [X] : pred_attacker(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(X),name_Kbs),name_Kas)), inference(rewrite, [status(thm)], [f84, s15])).
fof(lemma_34, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(X),name_Kbs),name_Kas))), inference(mp, [status(thm)], [f137, s16])).
fof(lemma_35, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(constr_cbc_enc_1(name_Kab_66(X),name_Kbs))), inference(mp, [status(thm)], [f135, lemma_32])).
fof(s17, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [f141, lemma_30])).
fof(s18, plain, ! [Y,X] : pred_eq_bitstring_bitstring(name_Na(Y),constr_tuple_4_get_0x30(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s19, plain, ! [X] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s20, plain, ! [A] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(A),name_Kbs),name_Kas),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s21, plain, ! [Z,X,Y,B,A] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(constr_cbc_enc_1(name_Kab_66(Z),name_Kbs),name_Na(X),Y)),constr_cbc_dec_1(constr_cbc_enc_1(name_Kab_66(B),name_Kbs),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(A),name_Kbs),name_Kas),name_Kas)))), inference(instantiate, [status(thm)], [f96])).
fof(s22, plain, ! [A] : pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(A),name_Kbs),name_Kas),name_Kas))))), inference(mp, [status(thm)], [f187, s17, s18, s19, lemma_33, lemma_34, s20, lemma_35, s21])).
fof(s23, plain, ! [A] : pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(tuple_true,constr_cbc_enc_1(name_Kab_66(A),name_Kbs),name_Kas),name_Kas)))), inference(mp, [status(thm)], [f130, s22])).
fof(s24, plain, ! [A] : pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(tuple_true,constr_cbc_enc_1(name_Kab_66(A),name_Kbs))))), inference(rewrite, [status(thm)], [f81, s23])).
fof(lemma_36, lemma, pred_attacker(constr_enc(name_objective2,tuple_true)), inference(rewrite, [status(thm)], [f92, s24])).
fof(lemma_37, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(name_Na(X))), inference(mp, [status(thm)], [f139, lemma_30])).
fof(lemma_38, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(name_Na(X))), inference(mp, [status(thm)], [f137, lemma_30])).
fof(lemma_39, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(name_Na(X))), inference(mp, [status(thm)], [f135, lemma_30])).
fof(s25, plain, pred_attacker(tuple_client_A_in_2(constr_CONST_4)), inference(mp, [status(thm)], [f141, f157])).
fof(s26, plain, ! [X] : pred_eq_bitstring_bitstring(name_Na(X),constr_tuple_4_get_0x30(constr_cbc_dec_4(constr_CONST_4,name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s27, plain, pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(constr_CONST_4,name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s28, plain, ! [Z] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(name_Na(Z),name_Kas))), inference(instantiate, [status(thm)], [f96])).
fof(s29, plain, ! [Y,X,A,Z] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(name_Na(Y),constr_CONST_4,X)),constr_cbc_dec_1(name_Na(A),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(name_Na(Z),name_Kas)))), inference(instantiate, [status(thm)], [f96])).
fof(s30, plain, pred_attacker(tuple_client_A_out_9(name_objective1)), inference(mp, [status(thm)], [f186, s25, s26, s27, lemma_37, lemma_38, s28, lemma_39, s29])).
fof(lemma_40, lemma, pred_attacker(name_objective1), inference(mp, [status(thm)], [f122, s30])).
fof(s31, plain, pred_attacker(constr_dec(constr_enc(name_objective2,tuple_true),tuple_true)), inference(mp, [status(thm)], [f114, f103, lemma_36])).
fof(s32, plain, pred_attacker(name_objective2), inference(rewrite, [status(thm)], [f89, s31])).
fof(f190, theorem, pred_attacker(tuple_2(name_objective1, name_objective2)), inference(mp, [status(thm)], [f171, s32, lemma_40])).
% SZS output end Proof
