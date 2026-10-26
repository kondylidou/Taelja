% SZS output start Proof
fof(f1907, axiom, ! [X1]: ((runningshorts(X1) & mtvisible(c_tptp_member2701_mt)) => tptpofobject(X1, f_tptpquantityfn_2(n_756))), file('Problems/CSR/CSR026+3.p', ax2_1907)).
fof(f2363, axiom, genlmt(c_tptp_spindlecollectormt, c_tptp_member2701_mt), file('Problems/CSR/CSR026+3.p', ax2_2363)).
fof(f2882, axiom, genlmt(c_tptp_spindlecollectormt, c_tptp_member3633_mt), file('Problems/CSR/CSR026+3.p', ax2_2882)).
fof(f3932, axiom, genlmt(c_tptp_member3633_mt, c_tptp_spindleheadmt), file('Problems/CSR/CSR026+3.p', ax2_3932)).
fof(f3995, axiom, mtvisible(c_cyclistsmt) => runningshorts(c_tptprunningshorts), file('Problems/CSR/CSR026+3.p', ax2_3995)).
fof(f4481, axiom, genlmt(c_tptp_spindleheadmt, c_cyclistsmt), file('Problems/CSR/CSR026+3.p', ax2_4481)).
fof(f7997, axiom, ! [X20, X21]: ((genlmt(X20, X21) & mtvisible(X20)) => mtvisible(X21)), file('Problems/CSR/CSR026+3.p', ax2_7997)).
fof(c_7336, assumption, mtvisible(c_tptp_spindlecollectormt), introduced(assumption, [], [])).
fof(lemma_9, lemma, mtvisible(c_tptp_member3633_mt), inference(mp, [status(thm), assumptions([c_7336])], [f7997, f2882, c_7336])).
fof(lemma_10, lemma, mtvisible(c_tptp_spindleheadmt), inference(mp, [status(thm), assumptions([c_7336])], [f7997, f3932, lemma_9])).
fof(lemma_11, lemma, mtvisible(c_tptp_member2701_mt), inference(mp, [status(thm), assumptions([c_7336])], [f7997, f2363, c_7336])).
fof(s1, plain, mtvisible(c_cyclistsmt), inference(mp, [status(thm), assumptions([c_7336])], [f7997, f4481, lemma_10])).
fof(s2, plain, runningshorts(c_tptprunningshorts), inference(mp, [status(thm), assumptions([c_7336])], [f3995, s1])).
fof(s3, plain, tptpofobject(c_tptprunningshorts,f_tptpquantityfn_2(n_756)), inference(mp, [status(thm), assumptions([c_7336])], [f1907, s2, lemma_11])).
fof(f8006, theorem, mtvisible(c_tptp_spindlecollectormt) => tptpofobject(c_tptprunningshorts, f_tptpquantityfn_2(n_756)), inference(implies, [status(thm), discharge(implies, [c_7336])], [s3, c_7336])).
% SZS output end Proof
