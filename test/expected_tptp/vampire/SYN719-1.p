% SZS output start Proof
fof(f22, negated_conjecture, ! [X0]: p35(X0, X0), file('Problems/SYN/SYN719-1.p')).
fof(f27, negated_conjecture, ! [X0]: p29(X0, X0), file('Problems/SYN/SYN719-1.p')).
fof(f38, negated_conjecture, ! [X0]: p14(X0, X0), file('Problems/SYN/SYN719-1.p')).
fof(f41, negated_conjecture, p66(f12(c78, c77), c79), file('Problems/SYN/SYN719-1.p')).
fof(f42, negated_conjecture, p67(f16(c80, c81), c82), file('Problems/SYN/SYN719-1.p')).
fof(f43, negated_conjecture, ! [X0, X1]: p70(f30(c88, X0), f38(c85, X1)), file('Problems/SYN/SYN719-1.p')).
fof(f45, negated_conjecture, ! [X0]: p14(f23(f26(c84, c85), X0), X0), file('Problems/SYN/SYN719-1.p')).
fof(f52, negated_conjecture, ! [X0, X1]: (p69(f36(c86, X0), X1) | ~ p70(X1, X0)), file('Problems/SYN/SYN719-1.p')).
fof(f90, negated_conjecture, ! [X2, X0, X1]: (~ p14(X2, X1) | ~ p14(X2, X0) | p14(X0, X1)), file('Problems/SYN/SYN719-1.p')).
fof(f98, negated_conjecture, ! [X2, X3, X0, X1]: (~ p69(X2, X3) | ~ p35(X2, X0) | p69(X0, X1) | ~ p29(X3, X1)), file('Problems/SYN/SYN719-1.p')).
fof(f126, negated_conjecture, ! [X2, X3, X0, X1]: (~ p69(f36(c86, f38(X3, f40(f42(f44(f46(c87, X0), X1), X3), X2))), f30(c88, f32(c89, f8(c75, c76)))) | ~ p67(f16(c80, X2), c82) | ~ p66(f12(c78, c77), X0) | ~ p14(X1, f23(f26(c84, X3), X2)) | p68(f19(f21(c83, c77), X0), X1)), file('Problems/SYN/SYN719-1.p')).
fof(s1, plain, p14(f23(f26(c84,c85),c81),f23(f26(c84,c85),c81)), inference(instantiate, [status(thm)], [f38])).
fof(s2, plain, p14(f23(f26(c84,c85),c81),c81), inference(instantiate, [status(thm)], [f45])).
fof(lemma_12, lemma, p14(c81,f23(f26(c84,c85),c81)), inference(mp, [status(thm)], [f90, s1, s2])).
fof(s3, plain, p70(f30(c88,f32(c89,f8(c75,c76))),f38(c85,f40(f42(f44(f46(c87,c79),c81),c85),c81))), inference(instantiate, [status(thm)], [f43])).
fof(s4, plain, p69(f36(c86,f38(c85,f40(f42(f44(f46(c87,c79),c81),c85),c81))),f30(c88,f32(c89,f8(c75,c76)))), inference(mp, [status(thm)], [f52, s3])).
fof(goal_1, theorem, p68(f19(f21(c83,c77),c79),c81), inference(mp, [status(thm)], [f126, s4, f42, f41, lemma_12])).
% SZS output end Proof
