% SZS output start Proof
fof(c_53, plain, ! [X0]: join(X0, n0, X0), file('Problems/LAT/LAT005-2.p', join_x_and_0)).
fof(c_56, plain, ! [X0]: meet(X0, X0, X0), file('Problems/LAT/LAT005-2.p', meet_x_and_x)).
fof(c_59, plain, ! [X0, X1, X2]: (~ meet(X0, X1, X2) | meet(X1, X0, X2)), file('Problems/LAT/LAT005-2.p', commutativity_of_meet)).
fof(c_60, plain, ! [X0, X1, X2]: (~ join(X0, X1, X2) | join(X1, X0, X2)), file('Problems/LAT/LAT005-2.p', commutativity_of_join)).
fof(c_61, plain, ! [X0, X1, X2]: (~ meet(X0, X1, X2) | join(X0, X2, X0)), file('Problems/LAT/LAT005-2.p', absorbtion1)).
fof(c_62, plain, ! [X0, X1, X2]: (~ join(X0, X1, X2) | meet(X0, X2, X0)), file('Problems/LAT/LAT005-2.p', absorbtion2)).
fof(c_63, plain, ! [X0, X1, X2, X3, X4, X5]: (~ meet(X0, X1, X2) | ~ meet(X0, X3, X4) | ~ meet(X1, X5, X3) | meet(X2, X5, X4)), file('Problems/LAT/LAT005-2.p', associativity_of_meet1)).
fof(c_64, plain, ! [X0, X1, X2, X3, X4, X5]: (~ meet(X0, X1, X2) | ~ meet(X1, X3, X4) | ~ meet(X2, X3, X5) | meet(X0, X4, X5)), file('Problems/LAT/LAT005-2.p', associativity_of_meet2)).
fof(c_68, plain, ! [X0, X1, X2, X3, X4, X5]: (~ join(X0, X1, X2) | ~ join(X0, X3, X4) | ~ meet(X0, X5, X0) | ~ meet(X1, X5, X3) | meet(X5, X2, X4)), file('Problems/LAT/LAT005-2.p', modularity2)).
fof(c_70, plain, meet(a, b, c), file('Problems/LAT/LAT005-2.p', meet_a_and_b)).
fof(c_72, plain, meet(c, r2, n0), file('Problems/LAT/LAT005-2.p', meet_c_and_r2)).
fof(c_73, plain, meet(r2, b, e), file('Problems/LAT/LAT005-2.p', meet_r2_and_b)).
fof(c_74, plain, join(a, b, c2), file('Problems/LAT/LAT005-2.p', join_a_and_b)).
fof(c_76, plain, meet(c2, r1, n0), file('Problems/LAT/LAT005-2.p', meet_c2_and_r1)).
fof(c_77, plain, meet(r2, a, d), file('Problems/LAT/LAT005-2.p', meet_r2_and_a)).
fof(c_78, plain, join(r1, e, a2), file('Problems/LAT/LAT005-2.p', join_r1_and_e)).
fof(c_79, plain, join(r1, d, b2), file('Problems/LAT/LAT005-2.p', join_r1_and_d)).
fof(lemma_18, lemma, meet(r2,c,n0), inference(mp, [status(thm)], [c_59, c_72])).
fof(s1, plain, ! [X,Y,Z] : ((meet(b,X,Y) & meet(r2,Y,Z)) => meet(r2,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s2, plain, ! [X,Y,Z] : ((meet(b,X,Y) & meet(r2,Y,Z)) => meet(b,X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_19, lemma, ! [X,Y,Z] : ((meet(b,X,Y) & meet(r2,Y,Z)) => meet(e,X,Z)), inference(mp, [status(thm)], [c_63, c_73, s1, s2])).
fof(s3, plain, ! [X,Y,Z] : ((meet(a,X,Y) & meet(r2,Y,Z)) => meet(r2,Y,Z)), inference(assumption, [status(thm)], [])).
fof(s4, plain, ! [X,Y,Z] : ((meet(a,X,Y) & meet(r2,Y,Z)) => meet(a,X,Y)), inference(assumption, [status(thm)], [])).
fof(lemma_20, lemma, ! [X,Y,Z] : ((meet(a,X,Y) & meet(r2,Y,Z)) => meet(d,X,Z)), inference(mp, [status(thm)], [c_63, c_77, s3, s4])).
fof(lemma_21, lemma, meet(r1,c2,n0), inference(mp, [status(thm)], [c_59, c_76])).
fof(s5, plain, meet(c,c,c), inference(instantiate, [status(thm)], [c_56])).
fof(lemma_22, lemma, meet(c,n0,n0), inference(mp, [status(thm)], [c_64, s5, c_72, c_72])).
fof(s6, plain, meet(n0,n0,n0), inference(instantiate, [status(thm)], [c_56])).
fof(lemma_23, lemma, meet(r2,n0,n0), inference(mp, [status(thm)], [c_64, lemma_18, lemma_22, s6])).
fof(s7, plain, join(b,a,c2), inference(mp, [status(thm)], [c_60, c_74])).
fof(s8, plain, meet(b,c2,b), inference(mp, [status(thm)], [c_62, s7])).
fof(lemma_24, lemma, meet(e,c2,e), inference(mp, [status(thm)], [lemma_19, s8, c_73])).
fof(s9, plain, meet(b,a,c), inference(mp, [status(thm)], [c_59, c_70])).
fof(s10, plain, meet(e,a,n0), inference(mp, [status(thm)], [lemma_19, s9, lemma_18])).
fof(s11, plain, meet(a,e,n0), inference(mp, [status(thm)], [c_59, s10])).
fof(lemma_25, lemma, meet(d,e,n0), inference(mp, [status(thm)], [lemma_20, s11, lemma_23])).
fof(s12, plain, join(e,r1,a2), inference(mp, [status(thm)], [c_60, c_78])).
fof(s13, plain, join(e,n0,e), inference(instantiate, [status(thm)], [c_53])).
fof(lemma_26, lemma, meet(c2,a2,e), inference(mp, [status(thm)], [c_68, s12, s13, lemma_24, lemma_21])).
fof(lemma_27, lemma, join(r1,n0,r1), inference(mp, [status(thm)], [c_61, lemma_21])).
fof(lemma_28, lemma, meet(r1,a2,r1), inference(mp, [status(thm)], [c_62, c_78])).
fof(s14, plain, meet(a,c2,a), inference(mp, [status(thm)], [c_62, c_74])).
fof(s15, plain, meet(d,c2,d), inference(mp, [status(thm)], [lemma_20, s14, c_77])).
fof(lemma_29, lemma, meet(d,a2,n0), inference(mp, [status(thm)], [c_63, s15, lemma_25, lemma_26])).
fof(goal_1, theorem, meet(a2,b2,r1), inference(mp, [status(thm)], [c_68, c_79, lemma_27, lemma_28, lemma_29])).
% SZS output end Proof
