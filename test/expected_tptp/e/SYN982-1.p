% SZS output start Proof
cnf(clause33, axiom, ssM(sent(b, t, triple(b, nb(X2), encr(triple(X1, X2, tb(X2)), bt)))) | ~ ssM(sent(X1, b, pair(X1, X2))) | ~ ssBf(X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause33)).
cnf(clause34, axiom, ssBk(key(X2, X1)) | ~ ssM(sent(X1, b, pair(encr(triple(X1, X2, tb(X3)), bt), encr(nb(X3), X2)))) | ~ ssSb(pair(X1, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause34)).
cnf(clause27, axiom, ssM(sent(X2, X3, X1)) | ~ ssIm(X1) | ~ ssP(X2) | ~ ssP(X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause27)).
cnf(clause16, axiom, ssM(sent(a, b, pair(a, na))), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause16)).
cnf(clause3, axiom, ssBf(na), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause3)).
cnf(clause4, axiom, ssP(b), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause4)).
cnf(clause20, axiom, ssIm(X3) | ~ ssM(sent(X1, X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause20)).
cnf(clause30, axiom, ssSb(pair(X1, X2)) | ~ ssM(sent(X1, b, pair(X1, X2))) | ~ ssBf(X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause30)).
cnf(clause26, axiom, ssIm(pair(X1, X2)) | ~ ssIm(X1) | ~ ssIm(X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause26)).
cnf(clause17, axiom, ssIm(X3) | ~ ssIm(triple(X1, X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause17)).
cnf(clause29, axiom, ssIm(encr(X1, X2)) | ~ ssIm(X1) | ~ ssIk(key(X2, X3)) | ~ ssP(X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause29)).
cnf(clause25, axiom, ssIk(key(X1, X2)) | ~ ssIm(X1) | ~ ssP(X2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause25)).
cnf(clause5, axiom, ssP(a), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause5)).
cnf(clause18, axiom, ssIm(X2) | ~ ssIm(triple(X1, X2, X3)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause18)).
cnf(clause14, axiom, ssIm(X2) | ~ ssIm(pair(X1, X2)), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYN/SYN982-1.p', clause14)).
fof(s1, plain, ssIm(pair(a,na)), inference(mp, [status(thm)], [clause20, clause16])).
fof(lemma_16, lemma, ssIm(na), inference(mp, [status(thm)], [clause14, s1])).
fof(s2, plain, ssM(sent(b,t,triple(b,nb(na),encr(triple(a,na,tb(na)),bt)))), inference(mp, [status(thm)], [clause33, clause16, clause3])).
fof(lemma_17, lemma, ssIm(triple(b,nb(na),encr(triple(a,na,tb(na)),bt))), inference(mp, [status(thm)], [clause20, s2])).
fof(lemma_18, lemma, ssIk(key(na,a)), inference(mp, [status(thm)], [clause25, lemma_16, clause5])).
fof(s3, plain, ssIm(nb(na)), inference(mp, [status(thm)], [clause18, lemma_17])).
fof(lemma_19, lemma, ssIm(encr(nb(na),na)), inference(mp, [status(thm)], [clause29, s3, lemma_18, clause5])).
fof(lemma_20, lemma, ssSb(pair(a,na)), inference(mp, [status(thm)], [clause30, clause16, clause3])).
fof(goal_1, theorem, ssIk(key(na,b)), inference(mp, [status(thm)], [clause25, lemma_16, clause4])).
fof(s4, plain, ssIm(encr(triple(a,na,tb(na)),bt)), inference(mp, [status(thm)], [clause17, lemma_17])).
fof(s5, plain, ssIm(pair(encr(triple(a,na,tb(na)),bt),encr(nb(na),na))), inference(mp, [status(thm)], [clause26, s4, lemma_19])).
fof(s6, plain, ssM(sent(a,b,pair(encr(triple(a,na,tb(na)),bt),encr(nb(na),na)))), inference(mp, [status(thm)], [clause27, s5, clause5, clause4])).
fof(goal_2, theorem, ssBk(key(na,a)), inference(mp, [status(thm)], [clause34, s6, lemma_20])).
% SZS output end Proof
