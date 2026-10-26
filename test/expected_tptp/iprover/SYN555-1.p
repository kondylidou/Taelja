% SZS output start Proof
fof(c_50, plain, ! [X0]: p4(X0, X0), file('Problems/SYN/SYN555-1.p', p4_2)).
fof(c_52, plain, p4(f5(c7, c10, c9), c9), file('Problems/SYN/SYN555-1.p', p4_4)).
fof(c_54, plain, ! [X0]: p4(f5(c7, X0, c8), f5(c7, X0, c9)), file('Problems/SYN/SYN555-1.p', p4_6)).
fof(c_56, plain, ! [X0, X1, X2]: (~ p4(X0, X1) | ~ p4(X0, X2) | p4(X1, X2)), file('Problems/SYN/SYN555-1.p', p4_8)).
fof(c_60, plain, ! [X0, X1, X2]: (~ p4(f5(c7, f6(X0, X1, X2), X1), f5(c7, f6(X0, X1, X2), X2)) | ~ p4(f5(c7, X0, X1), X1) | p4(f5(c7, X0, X2), X2)), file('Problems/SYN/SYN555-1.p', p4_12)).
fof(s1, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c9)), inference(instantiate, [status(thm)], [c_54])).
fof(s2, plain, p4(f5(c7,f6(c10,c9,c8),c8),f5(c7,f6(c10,c9,c8),c8)), inference(instantiate, [status(thm)], [c_50])).
fof(s3, plain, p4(f5(c7,f6(c10,c9,c8),c9),f5(c7,f6(c10,c9,c8),c8)), inference(mp, [status(thm)], [c_56, s1, s2])).
fof(goal_1, theorem, p4(f5(c7,c10,c8),c8), inference(mp, [status(thm)], [c_60, s3, c_52])).
% SZS output end Proof
