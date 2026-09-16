% SZS output start Proof
fof(f1, axiom, mtvisible(c_tptp_member3356_mt) => marriagelicensedocument(c_tptpmarriagelicensedocument), file('Problems/CSR/CSR051+1.p')).
fof(f77, assumption, mtvisible(c_tptp_member3356_mt), introduced(assumption, [], [])).
fof(s1, plain, marriagelicensedocument(c_tptpmarriagelicensedocument), inference(mp, [status(thm), assumptions([f77])], [f1, f77])).
fof(f28, theorem, ? [X0]: (mtvisible(c_tptp_member3356_mt) => marriagelicensedocument(X0)), inference(implies, [status(thm), discharge(implies, [f77])], [s1, f77])).
% SZS output end Proof
