% SZS output start Proof
cnf(c5, axiom, individual(f_citynamedfn(s_agen, c_france)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/CSR/CSR032+1.p', just1)).
fof(c6, axiom, ! [X]: (individual(X) => isa(X, c_individual)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/CSR/CSR032+1.p', just57)).
fof(s1, plain, isa(f_citynamedfn(s_agen,c_france),c_individual), inference(mp, [status(thm)], [c6, c5])).
fof(c1, theorem, ? [COL]: (mtvisible(c_reasoningaboutpossibleantecedentsmt) => isa(f_citynamedfn(s_agen, c_france), COL)), inference(conclude, [status(thm)], [s1])).
% SZS output end Proof
