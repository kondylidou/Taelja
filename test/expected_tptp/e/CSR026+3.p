% SZS output start Proof
fof(ax2_7997, axiom, ! [X21, X22]: ((mtvisible(X21) & genlmt(X21, X22)) => mtvisible(X22)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_7997)).
fof(ax2_142, axiom, genlmt(c_tptp_member3633_mt, c_tptp_spindleheadmt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_142)).
fof(ax2_1645, axiom, genlmt(c_tptp_spindlecollectormt, c_tptp_member2701_mt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1645)).
fof(ax2_2882, axiom, genlmt(c_tptp_spindlecollectormt, c_tptp_member3633_mt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_2882)).
fof(ax2_4288, axiom, genlmt(c_tptp_spindleheadmt, c_cyclistsmt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_4288)).
fof(ax2_3822, axiom, ! [X2]: ((mtvisible(c_tptp_member2701_mt) & runningshorts(X2)) => tptpofobject(X2, f_tptpquantityfn_2(n_756))), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_3822)).
fof(ax2_1317, axiom, mtvisible(c_cyclistsmt) => runningshorts(c_tptprunningshorts), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1317)).
fof(c_0_14, assumption, mtvisible(c_tptp_spindlecollectormt), introduced(assumption, [], [])).
fof(s1, plain, mtvisible(c_tptp_member3633_mt), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_7997, c_0_14, ax2_2882])).
fof(s2, plain, mtvisible(c_tptp_spindleheadmt), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_7997, s1, ax2_142])).
fof(s3, plain, mtvisible(c_cyclistsmt), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_7997, s2, ax2_4288])).
fof(lemma_9, lemma, runningshorts(c_tptprunningshorts), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_1317, s3])).
fof(s4, plain, mtvisible(c_tptp_member2701_mt), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_7997, c_0_14, ax2_1645])).
fof(s5, plain, tptpofobject(c_tptprunningshorts,f_tptpquantityfn_2(n_756)), inference(mp, [status(thm), assumptions([c_0_14])], [ax2_3822, s4, lemma_9])).
fof(query126, theorem, mtvisible(c_tptp_spindlecollectormt) => tptpofobject(c_tptprunningshorts, f_tptpquantityfn_2(n_756)), inference(implies, [status(thm), discharge(implies, [c_0_14])], [s5, c_0_14])).
% SZS output end Proof
