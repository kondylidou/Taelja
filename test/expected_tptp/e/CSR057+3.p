% SZS output start Proof
fof(ax2_7997, axiom, ! [X21, X22]: ((mtvisible(X21) & genlmt(X21, X22)) => mtvisible(X22)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_7997)).
fof(ax2_1724, axiom, ! [X1]: (geolevel_4(X1) => geographicalregion(X1)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1724)).
fof(ax2_1120, axiom, mtvisible(c_worldgeographymt) => geolevel_4(c_georegion_l4_x75_y75), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1120)).
fof(ax2_1229, axiom, genlmt(c_tptpgeo_member8_mt, c_tptpgeo_spindleheadmt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1229)).
fof(ax2_1111, axiom, genlmt(c_tptpgeo_spindleheadmt, c_worldgeographymt), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1111)).
fof(ax2_7882, axiom, ! [X15]: (geographicalregion(X15) => geographicalsubregions(X15, X15)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_7882)).
fof(ax2_1935, axiom, ! [X3, X4]: (geographicalsubregions(X3, X4) => inregion(X4, X3)), file('/home/user/Desktop/TPTP-v9.2.1/Axioms/CSR002+2.ax', ax2_1935)).
fof(c_0_15, assumption, mtvisible(c_tptpgeo_member8_mt), introduced(assumption, [], [])).
fof(s1, plain, mtvisible(c_tptpgeo_spindleheadmt), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_7997, c_0_15, ax2_1229])).
fof(s2, plain, mtvisible(c_worldgeographymt), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_7997, s1, ax2_1111])).
fof(s3, plain, geolevel_4(c_georegion_l4_x75_y75), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_1120, s2])).
fof(s4, plain, geographicalregion(c_georegion_l4_x75_y75), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_1724, s3])).
fof(s5, plain, geographicalsubregions(c_georegion_l4_x75_y75,c_georegion_l4_x75_y75), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_7882, s4])).
fof(s6, plain, inregion(c_georegion_l4_x75_y75,c_georegion_l4_x75_y75), inference(mp, [status(thm), assumptions([c_0_15])], [ax2_1935, s5])).
fof(query157, theorem, ? [X15]: (mtvisible(c_tptpgeo_member8_mt) => inregion(X15, c_georegion_l4_x75_y75)), inference(implies, [status(thm), discharge(implies, [c_0_15])], [s6, c_0_15])).
% SZS output end Proof
