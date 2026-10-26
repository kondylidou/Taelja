% SZS output start Proof
fof(c_50, plain, ssP(t), file('Problems/SYN/SYN982-1.p', clause2)).
fof(c_51, plain, ssBf(na), file('Problems/SYN/SYN982-1.p', clause3)).
fof(c_52, plain, ssP(b), file('Problems/SYN/SYN982-1.p', clause4)).
fof(c_53, plain, ssP(a), file('Problems/SYN/SYN982-1.p', clause5)).
fof(c_62, plain, ! [X0, X1]: (~ ssIm(pair(X0, X1)) | ssIm(X1)), file('Problems/SYN/SYN982-1.p', clause14)).
fof(c_64, plain, ssM(sent(a, b, pair(a, na))), file('Problems/SYN/SYN982-1.p', clause16)).
fof(c_65, plain, ! [X0, X1, X2]: (~ ssIm(triple(X0, X1, X2)) | ssIm(X2)), file('Problems/SYN/SYN982-1.p', clause17)).
fof(c_66, plain, ! [X0, X1, X2]: (~ ssIm(triple(X0, X1, X2)) | ssIm(X1)), file('Problems/SYN/SYN982-1.p', clause18)).
fof(c_68, plain, ! [X0, X1, X2]: (~ ssM(sent(X0, X1, X2)) | ssIm(X2)), file('Problems/SYN/SYN982-1.p', clause20)).
fof(c_73, plain, ! [X0, X1]: (~ ssP(X0) | ~ ssIm(X1) | ssIk(key(X1, X0))), file('Problems/SYN/SYN982-1.p', clause25)).
fof(c_74, plain, ! [X0, X1]: (~ ssIm(X0) | ~ ssIm(X1) | ssIm(pair(X0, X1))), file('Problems/SYN/SYN982-1.p', clause26)).
fof(c_75, plain, ! [X0, X1, X2]: (~ ssP(X0) | ~ ssP(X1) | ~ ssIm(X2) | ssM(sent(X0, X1, X2))), file('Problems/SYN/SYN982-1.p', clause27)).
fof(c_77, plain, ! [X0, X1, X2]: (~ ssIk(key(X0, X1)) | ~ ssP(X1) | ~ ssIm(X2) | ssIm(encr(X2, X0))), file('Problems/SYN/SYN982-1.p', clause29)).
fof(c_78, plain, ! [X0, X1]: (~ ssM(sent(X0, b, pair(X0, X1))) | ~ ssBf(X1) | ssSb(pair(X0, X1))), file('Problems/SYN/SYN982-1.p', clause30)).
fof(c_81, plain, ! [X0, X1]: (~ ssM(sent(X0, b, pair(X0, X1))) | ~ ssBf(X1) | ssM(sent(b, t, triple(b, nb(X1), encr(triple(X0, X1, tb(X1)), bt))))), file('Problems/SYN/SYN982-1.p', clause33)).
fof(c_82, plain, ! [X0, X1, X2]: (~ ssM(sent(X0, b, pair(encr(triple(X0, X1, tb(X2)), bt), encr(nb(X2), X1)))) | ~ ssSb(pair(X0, X2)) | ssBk(key(X1, X0))), file('Problems/SYN/SYN982-1.p', clause34)).
fof(s1, plain, ssM(sent(b,t,triple(b,nb(na),encr(triple(a,na,tb(na)),bt)))), inference(mp, [status(thm)], [c_81, c_64, c_51])).
fof(lemma_17, lemma, ssIm(triple(b,nb(na),encr(triple(a,na,tb(na)),bt))), inference(mp, [status(thm)], [c_68, s1])).
fof(s2, plain, ssIm(pair(a,na)), inference(mp, [status(thm)], [c_68, c_64])).
fof(lemma_18, lemma, ssIm(na), inference(mp, [status(thm)], [c_62, s2])).
fof(lemma_19, lemma, ssIm(nb(na)), inference(mp, [status(thm)], [c_66, lemma_17])).
fof(s3, plain, ssIk(key(na,t)), inference(mp, [status(thm)], [c_73, c_50, lemma_18])).
fof(lemma_20, lemma, ssIm(encr(nb(na),na)), inference(mp, [status(thm)], [c_77, s3, c_50, lemma_19])).
fof(s4, plain, ssIm(encr(triple(a,na,tb(na)),bt)), inference(mp, [status(thm)], [c_65, lemma_17])).
fof(lemma_21, lemma, ssIm(pair(encr(triple(a,na,tb(na)),bt),encr(nb(na),na))), inference(mp, [status(thm)], [c_74, s4, lemma_20])).
fof(lemma_22, lemma, ssSb(pair(a,na)), inference(mp, [status(thm)], [c_78, c_64, c_51])).
fof(s5, plain, ssM(sent(a,b,pair(encr(triple(a,na,tb(na)),bt),encr(nb(na),na)))), inference(mp, [status(thm)], [c_75, c_53, c_52, lemma_21])).
fof(goal_1, theorem, ssBk(key(na,a)), inference(mp, [status(thm)], [c_82, s5, lemma_22])).
fof(goal_2, theorem, ssIk(key(na,b)), inference(mp, [status(thm)], [c_73, c_52, lemma_18])).
% SZS output end Proof
