% SZS output start Proof
fof(ax185, axiom, ! [X209, X210, X211, X212, X213]: ((pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X212, X211, X209)), constr_cbc_dec_1(X213, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X210, name_Kas)))) & pred_attacker(tuple_client_A_in_8(X213)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X210, name_Kas))) & pred_attacker(tuple_client_A_in_6(X210)) & pred_attacker(tuple_client_A_in_4(X212)) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X211, name_Kas))) & pred_eq_bitstring_bitstring(name_Na(X209), constr_tuple_4_get_0x30(constr_cbc_dec_4(X211, name_Kas))) & pred_attacker(tuple_client_A_in_2(X211))) => pred_attacker(tuple_client_A_out_9(name_objective1))), file('Problems/SWW/SWW968+1.p', ax185)).
fof(ax95, axiom, ! [X63, X64]: pred_eq_bitstring_bitstring(X63, X64), file('Problems/SWW/SWW968+1.p', ax95)).
fof(ax134, axiom, ! [X119]: (pred_attacker(X119) => pred_attacker(tuple_client_A_in_8(X119))), file('Problems/SWW/SWW968+1.p', ax134)).
fof(ax136, axiom, ! [X121]: (pred_attacker(X121) => pred_attacker(tuple_client_A_in_6(X121))), file('Problems/SWW/SWW968+1.p', ax136)).
fof(ax186, axiom, ! [X214, X215, X216, X217, X218]: ((pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(X217, X216, X214)), constr_cbc_dec_1(X218, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X215, name_Kas)))) & pred_attacker(tuple_client_A_in_8(X218)) & pred_eq_bitstring_bitstring(name_A, constr_tuple_2_get_1(constr_cbc_dec_2(X215, name_Kas))) & pred_attacker(tuple_client_A_in_6(X215)) & pred_attacker(tuple_client_A_in_4(X217)) & pred_eq_bitstring_bitstring(name_B, constr_tuple_4_get_1(constr_cbc_dec_4(X216, name_Kas))) & pred_eq_bitstring_bitstring(name_Na(X214), constr_tuple_4_get_0x30(constr_cbc_dec_4(X216, name_Kas))) & pred_attacker(tuple_client_A_in_2(X216))) => pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2, constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(X215, name_Kas)))))), file('Problems/SWW/SWW968+1.p', ax186)).
fof(ax138, axiom, ! [X123]: (pred_attacker(X123) => pred_attacker(tuple_client_A_in_4(X123))), file('Problems/SWW/SWW968+1.p', ax138)).
fof(ax140, axiom, ! [X125]: (pred_attacker(X125) => pred_attacker(tuple_client_A_in_2(X125))), file('Problems/SWW/SWW968+1.p', ax140)).
fof(ax133, axiom, ! [X116, X117, X118]: (pred_attacker(tuple_client_A_out_1(X116, X117, X118)) => pred_attacker(X118)), file('Problems/SWW/SWW968+1.p', ax133)).
fof(ax181, axiom, ! [X199]: pred_attacker(tuple_client_A_out_1(name_A, name_B, name_Na(X199))), file('Problems/SWW/SWW968+1.p', ax181)).
fof(ax170, axiom, ! [X187, X188]: ((pred_attacker(X187) & pred_attacker(X188)) => pred_attacker(tuple_2(X187, X188))), file('Problems/SWW/SWW968+1.p', ax170)).
fof(ax121, axiom, ! [X98]: (pred_attacker(tuple_client_A_out_9(X98)) => pred_attacker(X98)), file('Problems/SWW/SWW968+1.p', ax121)).
fof(ax113, axiom, ! [X89, X90]: ((pred_attacker(X89) & pred_attacker(X90)) => pred_attacker(constr_dec(X89, X90))), file('Problems/SWW/SWW968+1.p', ax113)).
fof(ax88, axiom, ! [X41, X42]: constr_dec(constr_enc(X42, X41), X41) = X42, file('Problems/SWW/SWW968+1.p', ax88)).
fof(ax129, axiom, ! [X106]: (pred_attacker(tuple_client_A_out_10(X106)) => pred_attacker(X106)), file('Problems/SWW/SWW968+1.p', ax129)).
fof(ax151, axiom, ! [X150]: (pred_attacker(X150) => pred_attacker(constr_cbc_4_get_2_prefixes(X150))), file('Problems/SWW/SWW968+1.p', ax151)).
fof(ax83, axiom, ! [X20, X21, X22, X23, X24]: constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(X21, X22, X23, X24, X20)) = constr_cbc_enc_2(X21, X22, X20), file('Problems/SWW/SWW968+1.p', ax83)).
fof(ax106, axiom, ! [X74]: (pred_attacker(tuple_server_S_out_2(X74)) => pred_attacker(X74)), file('Problems/SWW/SWW968+1.p', ax106)).
fof(ax188, axiom, ! [X221, X222, X223, X224]: (pred_attacker(tuple_server_S_in_1(X222, X223, X224)) => pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(X224, X223, name_Kab_66(X221), constr_cbc_enc_2(name_Kab_66(X221), X222, name_Kbs), name_Kas)))), file('Problems/SWW/SWW968+1.p', ax188)).
fof(ax80, axiom, ! [X10, X11, X12]: constr_cbc_dec_2(constr_cbc_enc_2(X11, X12, X10), X10) = tuple_2(X11, X12), file('Problems/SWW/SWW968+1.p', ax80)).
fof(ax91, axiom, ! [X51, X52]: constr_tuple_2_get_0x30_bitstring(tuple_2(X51, X52)) = X51, file('Problems/SWW/SWW968+1.p', ax91)).
fof(ax107, axiom, ! [X75, X76, X77]: ((pred_attacker(X75) & pred_attacker(X76) & pred_attacker(X77)) => pred_attacker(tuple_server_S_in_1(X75, X76, X77))), file('Problems/SWW/SWW968+1.p', ax107)).
fof(ax160, axiom, pred_attacker(constr_CONST_0x30), file('Problems/SWW/SWW968+1.p', ax160)).
fof(s1, plain, pred_attacker(tuple_server_S_in_1(constr_CONST_0x30,constr_CONST_0x30,constr_CONST_0x30)), inference(mp, [status(thm)], [ax107, ax160, ax160, ax160])).
fof(s2, plain, ! [X] : pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax188, s1])).
fof(s3, plain, ! [X] : pred_attacker(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas)), inference(mp, [status(thm)], [ax106, s2])).
fof(s4, plain, ! [X] : pred_attacker(constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax151, s3])).
fof(s5, plain, pred_attacker(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)), inference(rewrite, [status(thm)], [ax83, s4])).
fof(s6, plain, pred_attacker(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas))), inference(mp, [status(thm)], [ax136, s5])).
fof(lemma_23, lemma, pred_attacker(tuple_client_A_in_8(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)))), inference(mp, [status(thm)], [ax134, s6])).
fof(s7, plain, pred_attacker(tuple_server_S_in_1(constr_CONST_0x30,constr_CONST_0x30,constr_CONST_0x30)), inference(mp, [status(thm)], [ax107, ax160, ax160, ax160])).
fof(s8, plain, ! [X] : pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax188, s7])).
fof(s9, plain, ! [X] : pred_attacker(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas)), inference(mp, [status(thm)], [ax106, s8])).
fof(s10, plain, ! [X] : pred_attacker(constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax151, s9])).
fof(s11, plain, pred_attacker(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)), inference(rewrite, [status(thm)], [ax83, s10])).
fof(lemma_24, lemma, pred_attacker(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas))), inference(mp, [status(thm)], [ax136, s11])).
fof(s12, plain, pred_attacker(tuple_server_S_in_1(constr_CONST_0x30,constr_CONST_0x30,constr_CONST_0x30)), inference(mp, [status(thm)], [ax107, ax160, ax160, ax160])).
fof(s13, plain, ! [X] : pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax188, s12])).
fof(s14, plain, ! [X] : pred_attacker(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas)), inference(mp, [status(thm)], [ax106, s13])).
fof(s15, plain, ! [X] : pred_attacker(constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax151, s14])).
fof(s16, plain, pred_attacker(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)), inference(rewrite, [status(thm)], [ax83, s15])).
fof(s17, plain, pred_attacker(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas))), inference(mp, [status(thm)], [ax136, s16])).
fof(lemma_25, lemma, pred_attacker(tuple_client_A_in_4(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)))), inference(mp, [status(thm)], [ax138, s17])).
fof(s18, plain, pred_attacker(tuple_server_S_in_1(constr_CONST_0x30,constr_CONST_0x30,constr_CONST_0x30)), inference(mp, [status(thm)], [ax107, ax160, ax160, ax160])).
fof(s19, plain, ! [X] : pred_attacker(tuple_server_S_out_2(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax188, s18])).
fof(s20, plain, ! [X] : pred_attacker(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas)), inference(mp, [status(thm)], [ax106, s19])).
fof(s21, plain, ! [X] : pred_attacker(constr_cbc_4_get_2_prefixes(constr_cbc_enc_4(constr_CONST_0x30,constr_CONST_0x30,name_Kab_66(X),constr_cbc_enc_2(name_Kab_66(X),constr_CONST_0x30,name_Kbs),name_Kas))), inference(mp, [status(thm)], [ax151, s20])).
fof(s22, plain, pred_attacker(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)), inference(rewrite, [status(thm)], [ax83, s21])).
fof(s23, plain, pred_attacker(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas))), inference(mp, [status(thm)], [ax136, s22])).
fof(lemma_26, lemma, pred_attacker(tuple_client_A_in_2(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)))), inference(mp, [status(thm)], [ax140, s23])).
fof(s24, plain, ! [X] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)),tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)),X)),constr_cbc_dec_1(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(instantiate, [status(thm)], [ax95])).
fof(s25, plain, pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s26, plain, pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s27, plain, ! [X] : pred_eq_bitstring_bitstring(name_Na(X),constr_tuple_4_get_0x30(constr_cbc_dec_4(tuple_client_A_in_6(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas)),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s28, plain, pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas))))), inference(mp, [status(thm)], [ax186, s24, lemma_23, s25, lemma_24, lemma_25, s26, s27, lemma_26])).
fof(s29, plain, pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30))))), inference(rewrite, [status(thm)], [ax80, s28])).
fof(lemma_27, lemma, pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_CONST_0x30))), inference(rewrite, [status(thm)], [ax91, s29])).
fof(s30, plain, pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30))))), inference(rewrite, [status(thm)], [ax91, lemma_27])).
fof(lemma_28, lemma, pred_attacker(tuple_client_A_out_10(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas))))), inference(rewrite, [status(thm)], [ax80, s30])).
fof(s31, plain, pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(mp, [status(thm)], [ax129, lemma_28])).
fof(s32, plain, pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30)))), inference(rewrite, [status(thm)], [ax80, s31])).
fof(lemma_29, lemma, pred_attacker(constr_enc(name_objective2,constr_CONST_0x30)), inference(rewrite, [status(thm)], [ax91, s32])).
fof(s33, plain, pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30)))), inference(rewrite, [status(thm)], [ax91, lemma_29])).
fof(lemma_30, lemma, pred_attacker(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(rewrite, [status(thm)], [ax80, s33])).
fof(s34, plain, pred_attacker(constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30))), inference(rewrite, [status(thm)], [ax91, ax160])).
fof(lemma_31, lemma, pred_attacker(constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas))), inference(rewrite, [status(thm)], [ax80, s34])).
fof(s35, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax133, ax181])).
fof(s36, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax140, s35])).
fof(s37, plain, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax138, s36])).
fof(s38, plain, ! [X] : pred_attacker(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))))), inference(mp, [status(thm)], [ax136, s37])).
fof(lemma_32, lemma, ! [X] : pred_attacker(tuple_client_A_in_8(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))))), inference(mp, [status(thm)], [ax134, s38])).
fof(s39, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax133, ax181])).
fof(s40, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax140, s39])).
fof(s41, plain, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax138, s40])).
fof(lemma_33, lemma, ! [X] : pred_attacker(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))))), inference(mp, [status(thm)], [ax136, s41])).
fof(s42, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax133, ax181])).
fof(s43, plain, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax140, s42])).
fof(lemma_34, lemma, ! [X] : pred_attacker(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))), inference(mp, [status(thm)], [ax138, s43])).
fof(s44, plain, ! [X] : pred_attacker(name_Na(X)), inference(mp, [status(thm)], [ax133, ax181])).
fof(lemma_35, lemma, ! [X] : pred_attacker(tuple_client_A_in_2(name_Na(X))), inference(mp, [status(thm)], [ax140, s44])).
fof(s45, plain, pred_attacker(constr_dec(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas))),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(mp, [status(thm)], [ax113, lemma_30, lemma_31])).
fof(s46, plain, pred_attacker(constr_dec(constr_enc(name_objective2,constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30))),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(rewrite, [status(thm)], [ax80, s45])).
fof(lemma_36, lemma, pred_attacker(constr_dec(constr_enc(name_objective2,constr_CONST_0x30),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(constr_cbc_enc_2(constr_CONST_0x30,constr_CONST_0x30,name_Kas),name_Kas)))), inference(rewrite, [status(thm)], [ax91, s46])).
fof(s47, plain, pred_attacker(constr_dec(constr_enc(name_objective2,constr_CONST_0x30),constr_tuple_2_get_0x30_bitstring(tuple_2(constr_CONST_0x30,constr_CONST_0x30)))), inference(rewrite, [status(thm)], [ax80, lemma_36])).
fof(s48, plain, pred_attacker(constr_dec(constr_enc(name_objective2,constr_CONST_0x30),constr_CONST_0x30)), inference(rewrite, [status(thm)], [ax91, s47])).
fof(lemma_37, lemma, pred_attacker(name_objective2), inference(rewrite, [status(thm)], [ax88, s48])).
fof(s49, plain, ! [X,Y] : pred_eq_bitstring_bitstring(tuple_succ(name_Na0x27(tuple_client_A_in_2(name_Na(X)),name_Na(X),Y)),constr_cbc_dec_1(tuple_client_A_in_6(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X)))),constr_tuple_2_get_0x30_bitstring(constr_cbc_dec_2(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))),name_Kas)))), inference(instantiate, [status(thm)], [ax95])).
fof(s50, plain, ! [X] : pred_eq_bitstring_bitstring(name_A,constr_tuple_2_get_1(constr_cbc_dec_2(tuple_client_A_in_4(tuple_client_A_in_2(name_Na(X))),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s51, plain, ! [X] : pred_eq_bitstring_bitstring(name_B,constr_tuple_4_get_1(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s52, plain, ! [Y,X] : pred_eq_bitstring_bitstring(name_Na(Y),constr_tuple_4_get_0x30(constr_cbc_dec_4(name_Na(X),name_Kas))), inference(instantiate, [status(thm)], [ax95])).
fof(s53, plain, pred_attacker(tuple_client_A_out_9(name_objective1)), inference(mp, [status(thm)], [ax185, s49, lemma_32, s50, lemma_33, lemma_34, s51, s52, lemma_35])).
fof(s54, plain, pred_attacker(name_objective1), inference(mp, [status(thm)], [ax121, s53])).
fof(co0, theorem, pred_attacker(tuple_2(name_objective1, name_objective2)), inference(mp, [status(thm)], [ax170, s54, lemma_37])).
% SZS output end Proof
