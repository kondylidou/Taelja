% SZS output start Proof
fof(f5, axiom, ! [X0]: join(X0, n0, X0), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f30, negated_conjecture, join(r1, e, a2), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f31, negated_conjecture, join(r1, d, b2), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f14, axiom, ! [X2, X0, X1]: (~ join(X0, X1, X2) | meet(X0, X2, X0)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f25, negated_conjecture, meet(r2, b, e), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f11, axiom, ! [X2, X0, X1]: (~ meet(X0, X1, X2) | meet(X1, X0, X2)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f26, negated_conjecture, join(a, b, c2), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f12, axiom, ! [X2, X0, X1]: (~ join(X0, X1, X2) | join(X1, X0, X2)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f16, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ meet(X2, X3, X5) | ~ meet(X1, X3, X4) | ~ meet(X0, X1, X2) | meet(X0, X4, X5)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f29, negated_conjecture, meet(r2, a, d), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f28, negated_conjecture, meet(c2, r1, n0), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f20, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ meet(X2, X1, X4) | ~ join(X0, X2, X3) | ~ meet(X0, X1, X0) | ~ join(X0, X4, X5) | meet(X1, X3, X5)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f13, axiom, ! [X2, X0, X1]: (~ meet(X0, X1, X2) | join(X0, X2, X0)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f24, negated_conjecture, meet(c, r2, n0), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f22, negated_conjecture, meet(a, b, c), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f15, axiom, ! [X2, X3, X0, X1, X4, X5]: (~ meet(X1, X3, X4) | ~ meet(X0, X1, X2) | ~ meet(X0, X4, X5) | meet(X2, X3, X5)), file('Problems/LAT/LAT005-2.p', unknown)).
fof(f6, axiom, ! [X0]: meet(n0, X0, n0), file('Problems/LAT/LAT005-2.p', unknown)).
fof(lemma_18, lemma, meet(b,r2,e), inference(mp, [status(thm)], [f11, f25])).
fof(s1, plain, join(b,a,c2), inference(mp, [status(thm)], [f12, f26])).
fof(s2, plain, meet(b,c2,b), inference(mp, [status(thm)], [f14, s1])).
fof(lemma_19, lemma, meet(c2,b,b), inference(mp, [status(thm)], [f11, s2])).
fof(lemma_20, lemma, meet(a,r2,d), inference(mp, [status(thm)], [f11, f29])).
fof(s3, plain, meet(a,c2,a), inference(mp, [status(thm)], [f14, f26])).
fof(lemma_21, lemma, meet(c2,a,a), inference(mp, [status(thm)], [f11, s3])).
fof(lemma_22, lemma, join(d,r1,b2), inference(mp, [status(thm)], [f12, f31])).
fof(s4, plain, meet(a,r2,d), inference(mp, [status(thm)], [f11, f29])).
fof(s5, plain, meet(c2,d,d), inference(mp, [status(thm)], [f16, s4, lemma_20, lemma_21])).
fof(lemma_23, lemma, meet(d,c2,d), inference(mp, [status(thm)], [f11, s5])).
fof(s6, plain, meet(b,r2,e), inference(mp, [status(thm)], [f11, f25])).
fof(lemma_24, lemma, meet(c2,e,e), inference(mp, [status(thm)], [f16, s6, lemma_18, lemma_19])).
fof(lemma_25, lemma, meet(r2,c,n0), inference(mp, [status(thm)], [f11, f24])).
fof(s7, plain, meet(b,r2,e), inference(mp, [status(thm)], [f11, f25])).
fof(s8, plain, join(b,e,b), inference(mp, [status(thm)], [f13, s7])).
fof(s9, plain, join(e,b,b), inference(mp, [status(thm)], [f12, s8])).
fof(s10, plain, meet(e,b,e), inference(mp, [status(thm)], [f14, s9])).
fof(lemma_26, lemma, meet(b,e,e), inference(mp, [status(thm)], [f11, s10])).
fof(lemma_27, lemma, meet(d,b,n0), inference(mp, [status(thm)], [f15, f22, f29, lemma_25])).
fof(s11, plain, meet(r1,c2,n0), inference(mp, [status(thm)], [f11, f28])).
fof(s12, plain, join(d,n0,d), inference(instantiate, [status(thm)], [f5])).
fof(s13, plain, meet(c2,b2,d), inference(mp, [status(thm)], [f20, s11, lemma_22, lemma_23, s12])).
fof(lemma_28, lemma, meet(b2,c2,d), inference(mp, [status(thm)], [f11, s13])).
fof(lemma_29, lemma, meet(r1,b2,r1), inference(mp, [status(thm)], [f14, f31])).
fof(s14, plain, meet(n0,e,n0), inference(instantiate, [status(thm)], [f6])).
fof(s15, plain, meet(d,e,n0), inference(mp, [status(thm)], [f16, s14, lemma_26, lemma_27])).
fof(s16, plain, meet(b2,e,n0), inference(mp, [status(thm)], [f16, s15, lemma_24, lemma_28])).
fof(s17, plain, meet(e,b2,n0), inference(mp, [status(thm)], [f11, s16])).
fof(s18, plain, join(r1,n0,r1), inference(instantiate, [status(thm)], [f5])).
fof(s19, plain, meet(b2,a2,r1), inference(mp, [status(thm)], [f20, s17, f30, lemma_29, s18])).
fof(goal_1, theorem, meet(a2,b2,r1), inference(mp, [status(thm)], [f11, s19])).
% SZS output end Proof
