% SZS output start Proof
cnf(c2, axiom, apply(apply(apply(b, X), Y), Z) = apply(X, apply(Y, Z)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL003-4.p', b_definition)).
cnf(c4, axiom, apply(apply(w, X2), Y2) = apply(apply(X2, Y2), Y2), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL003-4.p', w_definition)).
cnf(c14, axiom, apply(Strong_fixed_point, fixed_pt) != apply(fixed_pt, apply(Strong_fixed_point, fixed_pt)) | fixed_point(Strong_fixed_point), file('/home/user/Desktop/TPTP-v9.2.1/Problems/COL/COL003-4.p', strong_fixed_point)).
fof(s1, plain, ! [X] : apply(apply(w,w),X) = apply(apply(w,X),X), inference(instantiate, [status(thm)], [c4])).
fof(lemma_4, lemma, ! [X] : apply(apply(w,w),X) = apply(apply(X,X),X), inference(rewrite, [status(thm)], [c4, s1])).
fof(s2, plain, ! [X,Y] : apply(apply(apply(apply(b,w),b),X),Y) = apply(apply(w,apply(b,X)),Y), inference(instantiate, [status(thm)], [c2])).
fof(s3, plain, ! [X,Y] : apply(apply(apply(apply(b,w),b),X),Y) = apply(apply(apply(b,X),Y),Y), inference(rewrite, [status(thm)], [c4, s2])).
fof(lemma_5, lemma, ! [X,Y] : apply(apply(apply(apply(b,w),b),X),Y) = apply(X,apply(Y,Y)), inference(rewrite, [status(thm)], [c2, s3])).
fof(s4, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt)), inference(instantiate, [status(thm)], [c2])).
fof(s5, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [c2, s4])).
fof(s6, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(apply(apply(b,w),b),apply(b,fixed_pt)),apply(apply(apply(b,w),b),apply(b,fixed_pt))),apply(apply(apply(b,w),b),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [lemma_4, s5])).
fof(s7, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(b,fixed_pt),apply(apply(apply(apply(b,w),b),apply(b,fixed_pt)),apply(apply(apply(b,w),b),apply(b,fixed_pt)))),apply(apply(apply(b,w),b),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [lemma_5, s6])).
fof(s8, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(apply(apply(b,w),b),apply(b,fixed_pt)),apply(apply(apply(b,w),b),apply(b,fixed_pt))),apply(apply(apply(b,w),b),apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [c2, s7])).
fof(s9, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [lemma_4, s8])).
fof(s10, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [c2, s9])).
fof(lemma_6, lemma, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)), inference(rewrite, [status(thm)], [c2, s10])).
fof(goal_1, theorem, fixed_point(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b)), inference(mp, [status(thm)], [c14, lemma_6])).
% SZS output end Proof
