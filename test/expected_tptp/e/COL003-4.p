% SZS output start Proof
cnf(b_definition, axiom, apply(apply(apply(b, X1), X2), X3) = apply(X1, apply(X2, X3)), file('Problems/COL/COL003-4.p', b_definition)).
cnf(w_definition, axiom, apply(apply(w, X1), X2) = apply(apply(X1, X2), X2), file('Problems/COL/COL003-4.p', w_definition)).
cnf(strong_fixed_point, axiom, fixed_point(X1) | apply(X1, fixed_pt) != apply(fixed_pt, apply(X1, fixed_pt)), file('Problems/COL/COL003-4.p', strong_fixed_point)).
fof(s1, plain, ! [X,Y] : apply(apply(w,apply(b,X)),Y) = apply(apply(apply(b,X),Y),Y), inference(instantiate, [status(thm)], [w_definition])).
fof(lemma_4, lemma, ! [X,Y] : apply(apply(w,apply(b,X)),Y) = apply(X,apply(Y,Y)), inference(rewrite, [status(thm)], [b_definition, s1])).
fof(s2, plain, ! [X] : apply(apply(w,w),X) = apply(apply(w,X),X), inference(instantiate, [status(thm)], [w_definition])).
fof(lemma_5, lemma, ! [X] : apply(apply(w,w),X) = apply(apply(X,X),X), inference(rewrite, [status(thm)], [w_definition, s2])).
fof(s3, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt)), inference(instantiate, [status(thm)], [b_definition])).
fof(s4, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [b_definition, s3])).
fof(s5, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(w,w),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [b_definition, s4])).
fof(s6, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(w,apply(w,apply(b,apply(b,fixed_pt)))),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [w_definition, s5])).
fof(s7, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt)))),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [w_definition, s6])).
fof(s8, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(apply(apply(b,fixed_pt),apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt))))),apply(w,apply(b,apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [lemma_4, s7])).
fof(s9, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(w,apply(b,apply(b,fixed_pt))),apply(w,apply(b,apply(b,fixed_pt)))),apply(w,apply(b,apply(b,fixed_pt))))), inference(rewrite, [status(thm)], [b_definition, s8])).
fof(s10, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(w,w),apply(w,apply(b,apply(b,fixed_pt))))), inference(rewrite, [status(thm)], [lemma_5, s9])).
fof(s11, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(w,w),apply(apply(apply(b,w),b),apply(b,fixed_pt)))), inference(rewrite, [status(thm)], [b_definition, s10])).
fof(s12, plain, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(b,apply(w,w)),apply(apply(b,w),b)),apply(b,fixed_pt))), inference(rewrite, [status(thm)], [b_definition, s11])).
fof(lemma_6, lemma, apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt) = apply(fixed_pt,apply(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b),fixed_pt)), inference(rewrite, [status(thm)], [b_definition, s12])).
fof(goal_1, theorem, fixed_point(apply(apply(b,apply(apply(b,apply(w,w)),apply(apply(b,w),b))),b)), inference(mp, [status(thm)], [strong_fixed_point, lemma_6])).
% SZS output end Proof
