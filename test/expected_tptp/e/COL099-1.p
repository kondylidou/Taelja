% SZS output start Proof
cnf(diamond_trancl_1h2, hypothesis, member(pair(y, ya), r), file('Problems/COL/COL099-1.p', diamond_trancl_1h2)).
cnf(diamond_trancl_1c1, negated_conjecture, member(pair(y, yp), trancl(r)), file('Problems/COL/COL099-1.p', diamond_trancl_1c1)).
cnf(diamond_trancl_1h1, hypothesis, diamond(r), file('Problems/COL/COL099-1.p', diamond_trancl_1h1)).
cnf(diamond_strip_lemmaD2, axiom, member(pair(X3, diamond_strip_lemmaD_sk1(X2, X3, X4, X1)), X1) | ~ diamond(X1) | ~ member(pair(X2, X3), trancl(X1)) | ~ member(pair(X2, X4), X1), file('Problems/COL/COL099-1.p', diamond_strip_lemmaD2)).
cnf(diamond_strip_lemmaD1, axiom, member(pair(X4, diamond_strip_lemmaD_sk1(X2, X3, X4, X1)), trancl(X1)) | ~ diamond(X1) | ~ member(pair(X2, X3), trancl(X1)) | ~ member(pair(X2, X4), X1), file('Problems/COL/COL099-1.p', diamond_strip_lemmaD1)).
cnf(r_into_trancl, axiom, member(pair(X1, X2), trancl(X3)) | ~ member(pair(X1, X2), X3), file('Problems/COL/COL099-1.p', r_into_trancl)).
fof(goal_1, theorem, member(pair(ya,diamond_strip_lemmaD_sk1(y,yp,ya,r)),trancl(r)), inference(mp, [status(thm)], [diamond_strip_lemmaD1, diamond_trancl_1h1, diamond_trancl_1c1, diamond_trancl_1h2])).
fof(s1, plain, member(pair(yp,diamond_strip_lemmaD_sk1(y,yp,ya,r)),r), inference(mp, [status(thm)], [diamond_strip_lemmaD2, diamond_trancl_1h1, diamond_trancl_1c1, diamond_trancl_1h2])).
fof(goal_2, theorem, member(pair(yp,diamond_strip_lemmaD_sk1(y,yp,ya,r)),trancl(r)), inference(mp, [status(thm)], [r_into_trancl, s1])).
% SZS output end Proof
