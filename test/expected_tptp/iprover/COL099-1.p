% SZS output start Proof
fof(c_55, plain, ! [X0, X1, X2]: (~ member(pair(X0, X1), X2) | member(pair(X0, X1), trancl(X2))), file('Problems/COL/COL099-1.p', r_into_trancl)).
fof(c_58, plain, ! [X0, X1, X2, X3]: (~ member(pair(X0, X1), trancl(X2)) | ~ member(pair(X0, X3), X2) | ~ diamond(X2) | member(pair(X3, diamond_strip_lemmaD_sk1(X0, X1, X3, X2)), trancl(X2))), file('Problems/COL/COL099-1.p', diamond_strip_lemmaD1)).
fof(c_59, plain, ! [X0, X1, X2, X3]: (~ member(pair(X0, X1), trancl(X2)) | ~ member(pair(X0, X3), X2) | ~ diamond(X2) | member(pair(X1, diamond_strip_lemmaD_sk1(X0, X1, X3, X2)), X2)), file('Problems/COL/COL099-1.p', diamond_strip_lemmaD2)).
fof(c_60, plain, diamond(r), file('Problems/COL/COL099-1.p', diamond_trancl_1h1)).
fof(c_61, plain, member(pair(y, ya), r), file('Problems/COL/COL099-1.p', diamond_trancl_1h2)).
fof(c_62, plain, member(pair(y, yp), trancl(r)), file('Problems/COL/COL099-1.p', diamond_trancl_1c1)).
fof(goal_1, theorem, member(pair(ya,diamond_strip_lemmaD_sk1(y,yp,ya,r)),trancl(r)), inference(mp, [status(thm)], [c_58, c_62, c_61, c_60])).
fof(s1, plain, member(pair(yp,diamond_strip_lemmaD_sk1(y,yp,ya,r)),r), inference(mp, [status(thm)], [c_59, c_62, c_61, c_60])).
fof(goal_2, theorem, member(pair(yp,diamond_strip_lemmaD_sk1(y,yp,ya,r)),trancl(r)), inference(mp, [status(thm)], [c_55, s1])).
% SZS output end Proof
