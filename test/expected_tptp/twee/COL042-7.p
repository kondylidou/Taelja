% SZS output start Proof
cnf(c2, axiom, apply(apply(w1, X), Y) = apply(apply(Y, X), X), file('TPTP/Problems/COL/COL042-7.p', w1_definition)).
cnf(c3, axiom, apply(apply(apply(b, X2), Y2), Z) = apply(X2, apply(Y2, Z)), file('TPTP/Problems/COL/COL042-7.p', b_definition)).
cnf(c12, axiom, strong_fixed_point = apply(apply(b, apply(apply(b, apply(w1, w1)), apply(b, w1))), apply(apply(b, b), b)), file('TPTP/Problems/COL/COL042-7.p', strong_fixed_point)).
fof(s1, plain, ! [X,Y,Z] : apply(apply(w1,X),apply(apply(b,Y),Z)) = apply(apply(apply(apply(b,Y),Z),X),X), inference(instantiate, [status(thm)], [c2])).
fof(lemma_4, lemma, ! [X,Y,Z] : apply(apply(w1,X),apply(apply(b,Y),Z)) = apply(apply(Y,apply(Z,X)),X), inference(rewrite, [status(thm)], [c3, s1])).
fof(s2, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(w1,apply(apply(apply(apply(b,b),b),X),w1)),w1), inference(instantiate, [status(thm)], [c3])).
fof(s3, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(w1,w1),apply(apply(b,w1),apply(apply(apply(b,b),b),X))), inference(rewrite, [status(thm)], [lemma_4, s2])).
fof(s4, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(w1,w1),apply(apply(b,w1),apply(apply(apply(w1,b),b),X))), inference(rewrite, [status(thm)], [c2, s3])).
fof(s5, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(w1,w1),apply(apply(b,w1),apply(apply(apply(w1,b),w1),X))), inference(rewrite, [status(thm)], [c2, s4])).
fof(s6, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(apply(b,apply(w1,w1)),apply(b,w1)),apply(apply(apply(w1,b),w1),X)), inference(rewrite, [status(thm)], [c3, s5])).
fof(s7, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(apply(b,apply(apply(b,apply(w1,w1)),apply(b,w1))),apply(apply(w1,b),w1)),X), inference(rewrite, [status(thm)], [c3, s6])).
fof(s8, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(apply(b,apply(apply(b,apply(w1,w1)),apply(b,w1))),apply(apply(w1,b),b)),X), inference(rewrite, [status(thm)], [c2, s7])).
fof(s9, plain, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(apply(apply(b,apply(apply(b,apply(w1,w1)),apply(b,w1))),apply(apply(b,b),b)),X), inference(rewrite, [status(thm)], [c2, s8])).
fof(lemma_5, lemma, ! [X] : apply(apply(w1,apply(apply(b,apply(b,X)),w1)),w1) = apply(strong_fixed_point,X), inference(rewrite, [status(thm)], [c12, s9])).
fof(s10, plain, apply(strong_fixed_point,fixed_pt) = apply(apply(w1,apply(apply(b,apply(b,fixed_pt)),w1)),w1), inference(instantiate, [status(thm)], [lemma_5])).
fof(s11, plain, apply(strong_fixed_point,fixed_pt) = apply(apply(w1,apply(apply(b,apply(b,fixed_pt)),w1)),apply(apply(b,apply(b,fixed_pt)),w1)), inference(rewrite, [status(thm)], [c2, s10])).
fof(s12, plain, apply(strong_fixed_point,fixed_pt) = apply(apply(apply(b,fixed_pt),apply(w1,apply(apply(b,apply(b,fixed_pt)),w1))),apply(apply(b,apply(b,fixed_pt)),w1)), inference(rewrite, [status(thm)], [lemma_4, s11])).
fof(s13, plain, apply(strong_fixed_point,fixed_pt) = apply(fixed_pt,apply(apply(w1,apply(apply(b,apply(b,fixed_pt)),w1)),apply(apply(b,apply(b,fixed_pt)),w1))), inference(rewrite, [status(thm)], [c3, s12])).
fof(s14, plain, apply(strong_fixed_point,fixed_pt) = apply(fixed_pt,apply(apply(w1,apply(apply(b,apply(b,fixed_pt)),w1)),w1)), inference(rewrite, [status(thm)], [c2, s13])).
fof(goal_1, theorem, apply(strong_fixed_point,fixed_pt) = apply(fixed_pt,apply(strong_fixed_point,fixed_pt)), inference(rewrite, [status(thm)], [lemma_5, s14])).
% SZS output end Proof
