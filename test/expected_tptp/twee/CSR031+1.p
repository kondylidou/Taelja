% SZS output start Proof
fof(c1, axiom, ! [OBJ]: ~ (collection(OBJ) & individual(OBJ)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/CSR/CSR031+1.p', just4)).
fof(c7, axiom, ! [ARG2, INS]: (disjointwith(INS, ARG2) => collection(INS)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/CSR/CSR031+1.p', just34)).
cnf(c11, axiom, individual(c_tptptptpcol_16_8398), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/CSR/CSR031+1.p', just6)).
fof(c6, assumption, disjointwith(c_tptptptpcol_16_8398,c_tptpcol_16_18488), introduced(assumption, [], [])).
fof(s1, plain, collection(c_tptptptpcol_16_8398), inference(mp, [status(thm), assumptions([c6])], [c7, c6])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c6])], [c1, s1, c11])).
fof(c4, theorem, ~ disjointwith(c_tptptptpcol_16_8398, c_tptpcol_16_18488), inference(implies, [status(thm), discharge(implies, [c6])], [s2, c6])).
% SZS output end Proof
