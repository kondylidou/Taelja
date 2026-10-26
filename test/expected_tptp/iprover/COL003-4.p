% SZS output start Proof
fof(c_49, plain, ! [X0, X1, X2]: apply(apply(apply(b, X0), X1), X2) = apply(X0, apply(X1, X2)), file('Problems/COL/COL003-4.p', b_definition)).
fof(c_50, plain, ! [X0, X1]: apply(apply(X0, X1), X1) = apply(apply(w, X0), X1), file('Problems/COL/COL003-4.p', w_definition)).
fof(c_51, plain, ! [X0]: (apply(fixed_pt, apply(X0, fixed_pt)) != apply(X0, fixed_pt) | fixed_point(X0)), file('Problems/COL/COL003-4.p', strong_fixed_point)).
fof(s1, plain, ! [X] : apply(apply(X,X),X) = apply(apply(w,X),X), inference(instantiate, [status(thm)], [c_50])).
fof(lemma_4, lemma, ! [X] : apply(apply(X,X),X) = apply(apply(w,w),X), inference(rewrite, [status(thm)], [c_50, s1])).
fof(s2, plain, ! [X] : apply(apply(b,fixed_pt),apply(X,X)) = apply(apply(apply(b,apply(b,fixed_pt)),X),X), inference(instantiate, [status(thm)], [c_49])).
fof(lemma_5, lemma, ! [X] : apply(apply(b,fixed_pt),apply(X,X)) = apply(apply(w,apply(b,apply(b,fixed_pt))),X), inference(rewrite, [status(thm)], [c_50, s2])).
fof(s3, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(fixed_pt,apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt))), inference(instantiate, [status(thm)], [c_49])).
fof(s4, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(fixed_pt,apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [c_49, s3])).
fof(s5, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(fixed_pt,apply(apply(w,w),apply(w,apply(b,apply(b,fixed_pt))))), inference(rewrite, [status(thm)], [c_49, s4])).
fof(s6, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(fixed_pt,apply(apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt)))),apply(w,apply(b,apply(b,fixed_pt))))), inference(rewrite, [status(thm)], [lemma_4, s5])).
fof(s7, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(apply(b,fixed_pt),apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt))))),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [c_49, s6])).
fof(s8, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt)))),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [lemma_5, s7])).
fof(s9, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(w,w),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [lemma_4, s8])).
fof(s10, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [c_49, s9])).
fof(s11, plain, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt)), inference(rewrite, [status(thm)], [c_49, s10])).
fof(lemma_6, lemma, apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)) = apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt), inference(rewrite, [status(thm)], [c_49, s11])).
fof(goal_1, theorem, fixed_point(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b)), inference(mp, [status(thm)], [c_51, lemma_6])).
% SZS output end Proof
