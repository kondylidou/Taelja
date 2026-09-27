% SZS output start Proof
fof(c38, assumption, grocer(s), introduced(assumption, [], [])).
fof(c13, assumption, s = t, introduced(assumption, [], [])).
fof(c9, assumption, cyclist(t), introduced(assumption, [], [])).
fof(c18, assumption, ! [X] : (cyclist(X) => property1(h(X),industrious,pos)), introduced(assumption, [], [])).
fof(c30, assumption, ! [X] : (cyclist(X) => X = h(X)), introduced(assumption, [], [])).
fof(c24, assumption, ! [Y] : (cyclist(Y) => person(r(Y))), introduced(assumption, [], [])).
fof(c64, assumption, ! [Y] : (cyclist(Y) => Y = r(Y)), introduced(assumption, [], [])).
fof(c42, assumption, ! [Z] : ((property1(Z,industrious,pos) & grocer(Z)) => property1(f(Z),honest,pos)), introduced(assumption, [], [])).
fof(c55, assumption, ! [Z] : ((property1(Z,industrious,pos) & grocer(Z)) => Z = f(Z)), introduced(assumption, [], [])).
fof(c48, assumption, ! [A] : ((person(A) & property1(A,honest,pos) & property1(A,industrious,pos)) => A = b(A)), introduced(assumption, [], [])).
fof(c86, assumption, ! [A] : ((person(A) & property1(A,honest,pos) & property1(A,industrious,pos)) => property1(b(A),healthy,pos)), introduced(assumption, [], [])).
fof(c4, assumption, ! [B] : ((property1(B,healthy,pos) & grocer(B)) => $false), introduced(assumption, [], [])).
fof(s1, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(lemma_13, lemma, r(s) = s, inference(mp, [status(thm), assumptions([c64, c13, c9])], [c64, s1])).
fof(s2, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(lemma_14, lemma, h(s) = s, inference(mp, [status(thm), assumptions([c30, c13, c9])], [c30, s2])).
fof(s3, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s4, plain, property1(h(s),industrious,pos), inference(mp, [status(thm), assumptions([c18, c13, c9])], [c18, s3])).
fof(s5, plain, property1(s,industrious,pos), inference(rewrite, [status(thm), assumptions([c30, c13, c9, c18])], [lemma_14, s4])).
fof(lemma_15, lemma, f(s) = s, inference(mp, [status(thm), assumptions([c55, c30, c13, c9, c18, c38])], [c55, s5, c38])).
fof(s6, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s7, plain, property1(h(s),industrious,pos), inference(mp, [status(thm), assumptions([c18, c13, c9])], [c18, s6])).
fof(s8, plain, property1(s,industrious,pos), inference(rewrite, [status(thm), assumptions([c30, c13, c9, c18])], [lemma_14, s7])).
fof(s9, plain, property1(f(s),honest,pos), inference(mp, [status(thm), assumptions([c42, c30, c13, c9, c18, c38])], [c42, s8, c38])).
fof(lemma_16, lemma, property1(s,honest,pos), inference(rewrite, [status(thm), assumptions([c55, c30, c13, c9, c18, c38, c42])], [lemma_15, s9])).
fof(s10, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s11, plain, property1(h(s),industrious,pos), inference(mp, [status(thm), assumptions([c18, c13, c9])], [c18, s10])).
fof(lemma_17, lemma, property1(s,industrious,pos), inference(rewrite, [status(thm), assumptions([c30, c13, c9, c18])], [lemma_14, s11])).
fof(s12, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s13, plain, person(r(s)), inference(mp, [status(thm), assumptions([c24, c13, c9])], [c24, s12])).
fof(s14, plain, person(s), inference(rewrite, [status(thm), assumptions([c64, c13, c9, c24])], [lemma_13, s13])).
fof(lemma_18, lemma, b(s) = s, inference(mp, [status(thm), assumptions([c48, c64, c13, c9, c24, c55, c30, c18, c38, c42])], [c48, s14, lemma_16, lemma_17])).
fof(s15, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s16, plain, property1(h(s),industrious,pos), inference(mp, [status(thm), assumptions([c18, c13, c9])], [c18, s15])).
fof(s17, plain, property1(s,industrious,pos), inference(rewrite, [status(thm), assumptions([c30, c13, c9, c18])], [lemma_14, s16])).
fof(s18, plain, property1(f(s),honest,pos), inference(mp, [status(thm), assumptions([c42, c30, c13, c9, c18, c38])], [c42, s17, c38])).
fof(lemma_19, lemma, property1(s,honest,pos), inference(rewrite, [status(thm), assumptions([c55, c30, c13, c9, c18, c38, c42])], [lemma_15, s18])).
fof(s19, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s20, plain, property1(h(s),industrious,pos), inference(mp, [status(thm), assumptions([c18, c13, c9])], [c18, s19])).
fof(lemma_20, lemma, property1(s,industrious,pos), inference(rewrite, [status(thm), assumptions([c30, c13, c9, c18])], [lemma_14, s20])).
fof(s21, plain, cyclist(s), inference(rewrite, [status(thm), assumptions([c13, c9])], [c13, c9])).
fof(s22, plain, person(r(s)), inference(mp, [status(thm), assumptions([c24, c13, c9])], [c24, s21])).
fof(s23, plain, person(s), inference(rewrite, [status(thm), assumptions([c64, c13, c9, c24])], [lemma_13, s22])).
fof(s24, plain, property1(b(s),healthy,pos), inference(mp, [status(thm), assumptions([c86, c64, c13, c9, c24, c55, c30, c18, c38, c42])], [c86, s23, lemma_19, lemma_20])).
fof(s25, plain, property1(s,healthy,pos), inference(rewrite, [status(thm), assumptions([c48, c64, c13, c9, c24, c55, c30, c18, c38, c42, c86])], [lemma_18, s24])).
fof(s26, plain, $false, inference(mp, [status(thm), assumptions([c4, c48, c64, c13, c9, c24, c55, c30, c18, c38, c42, c86])], [c4, s25, c38])).
fof(c1, theorem, (! [A]: ((person(A) & property1(A, honest, pos) & property1(A, industrious, pos)) => ? [B]: (property1(B, healthy, pos) & A = B)) & ! [C]: (grocer(C) => ~ ? [D]: (property1(D, healthy, pos) & C = D)) & ! [E]: ((grocer(E) & property1(E, industrious, pos)) => ? [F]: (property1(F, honest, pos) & E = F)) & ! [G]: (cyclist(G) => ? [H]: (property1(H, industrious, pos) & G = H)) & ! [I]: ((cyclist(I) & property1(I, unhealthy, pos)) => ? [J]: (property1(J, dishonest, pos) & I = J)) & ! [K]: ((person(K) & property1(K, healthy, pos)) => ~ ? [L]: (property1(L, unhealthy, pos) & K = L)) & ! [M]: ((person(M) & property1(M, honest, pos)) => ~ ? [N]: (property1(N, dishonest, pos) & M = N)) & ! [O]: (grocer(O) => ? [P]: (person(P) & O = P)) & ! [Q]: (cyclist(Q) => ? [R]: (person(R) & Q = R))) => ! [S]: (grocer(S) => ~ ? [T]: (cyclist(T) & S = T)), inference(implies, [status(thm), discharge(implies, [c38, c13, c9, c18, c30, c24, c64, c42, c55, c48, c86, c4])], [s26, c38, c13, c9, c18, c30, c24, c64, c42, c55, c48, c86, c4])).
% SZS output end Proof
