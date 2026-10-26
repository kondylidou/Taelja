% SZS output start Proof
fof(c_86, plain, ! [X0]: p14(X0, X0), file('Problems/SYN/SYN719-1.p', p14_38)).
fof(c_89, plain, p66(f12(c78, c77), c79), file('Problems/SYN/SYN719-1.p', p66_41)).
fof(c_90, plain, p67(f16(c80, c81), c82), file('Problems/SYN/SYN719-1.p', p67_42)).
fof(c_91, plain, ! [X0, X1]: p70(f30(c88, X0), f38(c85, X1)), file('Problems/SYN/SYN719-1.p', p70_43)).
fof(c_93, plain, ! [X0]: p14(f23(f26(c84, c85), X0), X0), file('Problems/SYN/SYN719-1.p', p14_45)).
fof(c_100, plain, ! [X0, X1]: (~ p70(X0, X1) | p69(f36(c86, X1), X0)), file('Problems/SYN/SYN719-1.p', p69_52)).
fof(c_138, plain, ! [X0, X1, X2]: (~ p14(X0, X1) | ~ p14(X0, X2) | p14(X1, X2)), file('Problems/SYN/SYN719-1.p', p14_90)).
fof(c_174, plain, ! [X0, X1, X2, X3]: (~ p69(f36(c86, f38(X0, f40(f42(f44(f46(c87, X1), X2), X0), X3))), f30(c88, f32(c89, f8(c75, c76)))) | ~ p14(X2, f23(f26(c84, X0), X3)) | ~ p66(f12(c78, c77), X1) | ~ p67(f16(c80, X3), c82) | p68(f19(f21(c83, c77), X1), X2)), file('Problems/SYN/SYN719-1.p', p68_126)).
fof(s1, plain, p14(f23(f26(c84,c85),c81),c81), inference(instantiate, [status(thm)], [c_93])).
fof(s2, plain, p14(f23(f26(c84,c85),c81),f23(f26(c84,c85),c81)), inference(instantiate, [status(thm)], [c_86])).
fof(lemma_9, lemma, p14(c81,f23(f26(c84,c85),c81)), inference(mp, [status(thm)], [c_138, s1, s2])).
fof(s3, plain, p70(f30(c88,f32(c89,f8(c75,c76))),f38(c85,f40(f42(f44(f46(c87,c79),c81),c85),c81))), inference(instantiate, [status(thm)], [c_91])).
fof(s4, plain, p69(f36(c86,f38(c85,f40(f42(f44(f46(c87,c79),c81),c85),c81))),f30(c88,f32(c89,f8(c75,c76)))), inference(mp, [status(thm)], [c_100, s3])).
fof(goal_1, theorem, p68(f19(f21(c83,c77),c79),c81), inference(mp, [status(thm)], [c_174, s4, lemma_9, c_89, c_90])).
% SZS output end Proof
