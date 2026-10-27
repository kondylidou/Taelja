% SZS output start Proof
cnf(rule1, axiom, p(X6, X2, X3, X4, X5) | ~ p(X1, X2, X3, X4, X5), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', rule1)).
cnf(rule2, axiom, p(X1, X6, X3, X4, X5) | ~ p(X1, X2, X3, X4, X5) | ~ neq(X1, X2) | ~ neq(X1, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', rule2)).
cnf(init, axiom, p(s0, s0, s0, s0, s0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', init)).
cnf(rule3, axiom, p(X1, X2, X6, X4, X5) | ~ p(X1, X2, X3, X4, X5) | ~ neq(X1, X3) | ~ neq(X1, X6) | ~ neq(X2, X3) | ~ neq(X2, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', rule3)).
cnf(neq7, axiom, neq(s2, s0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq7)).
cnf(neq4, axiom, neq(s1, s0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq4)).
cnf(neq8, axiom, neq(s2, s1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq8)).
cnf(rule4, axiom, p(X1, X2, X3, X6, X5) | ~ p(X1, X2, X3, X4, X5) | ~ neq(X1, X4) | ~ neq(X1, X6) | ~ neq(X2, X4) | ~ neq(X2, X6) | ~ neq(X3, X4) | ~ neq(X3, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', rule4)).
cnf(neq2, axiom, neq(s0, s1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq2)).
cnf(neq3, axiom, neq(s0, s2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq3)).
cnf(neq6, axiom, neq(s1, s2), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', neq6)).
cnf(rule5, axiom, p(X1, X2, X3, X4, X6) | ~ p(X1, X2, X3, X4, X5) | ~ neq(X1, X5) | ~ neq(X1, X6) | ~ neq(X2, X5) | ~ neq(X2, X6) | ~ neq(X3, X5) | ~ neq(X3, X6) | ~ neq(X4, X5) | ~ neq(X4, X6), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/PUZ/PUZ056-2.005.p', rule5)).
fof(s1, plain, p(s2,s0,s0,s0,s0), inference(mp, [status(thm)], [rule1, init])).
fof(s2, plain, p(s2,s1,s0,s0,s0), inference(mp, [status(thm)], [rule2, s1, neq7, neq8])).
fof(s3, plain, p(s1,s1,s0,s0,s0), inference(mp, [status(thm)], [rule1, s2])).
fof(s4, plain, p(s1,s1,s2,s0,s0), inference(mp, [status(thm)], [rule3, s3, neq4, neq6, neq4, neq6])).
fof(s5, plain, p(s0,s1,s2,s0,s0), inference(mp, [status(thm)], [rule1, s4])).
fof(s6, plain, p(s0,s2,s2,s0,s0), inference(mp, [status(thm)], [rule2, s5, neq2, neq3])).
fof(s7, plain, p(s2,s2,s2,s0,s0), inference(mp, [status(thm)], [rule1, s6])).
fof(s8, plain, p(s2,s2,s2,s1,s0), inference(mp, [status(thm)], [rule4, s7, neq7, neq8, neq7, neq8, neq7, neq8])).
fof(s9, plain, p(s1,s2,s2,s1,s0), inference(mp, [status(thm)], [rule1, s8])).
fof(s10, plain, p(s1,s0,s2,s1,s0), inference(mp, [status(thm)], [rule2, s9, neq6, neq4])).
fof(s11, plain, p(s0,s0,s2,s1,s0), inference(mp, [status(thm)], [rule1, s10])).
fof(s12, plain, p(s0,s0,s1,s1,s0), inference(mp, [status(thm)], [rule3, s11, neq3, neq2, neq3, neq2])).
fof(s13, plain, p(s2,s0,s1,s1,s0), inference(mp, [status(thm)], [rule1, s12])).
fof(s14, plain, p(s2,s1,s1,s1,s0), inference(mp, [status(thm)], [rule2, s13, neq7, neq8])).
fof(s15, plain, p(s1,s1,s1,s1,s0), inference(mp, [status(thm)], [rule1, s14])).
fof(s16, plain, p(s1,s1,s1,s1,s2), inference(mp, [status(thm)], [rule5, s15, neq4, neq6, neq4, neq6, neq4, neq6, neq4, neq6])).
fof(s17, plain, p(s0,s1,s1,s1,s2), inference(mp, [status(thm)], [rule1, s16])).
fof(s18, plain, p(s0,s2,s1,s1,s2), inference(mp, [status(thm)], [rule2, s17, neq2, neq3])).
fof(s19, plain, p(s2,s2,s1,s1,s2), inference(mp, [status(thm)], [rule1, s18])).
fof(s20, plain, p(s2,s2,s0,s1,s2), inference(mp, [status(thm)], [rule3, s19, neq8, neq7, neq8, neq7])).
fof(s21, plain, p(s1,s2,s0,s1,s2), inference(mp, [status(thm)], [rule1, s20])).
fof(s22, plain, p(s1,s0,s0,s1,s2), inference(mp, [status(thm)], [rule2, s21, neq6, neq4])).
fof(s23, plain, p(s0,s0,s0,s1,s2), inference(mp, [status(thm)], [rule1, s22])).
fof(s24, plain, p(s0,s0,s0,s2,s2), inference(mp, [status(thm)], [rule4, s23, neq2, neq3, neq2, neq3, neq2, neq3])).
fof(s25, plain, p(s2,s0,s0,s2,s2), inference(mp, [status(thm)], [rule1, s24])).
fof(s26, plain, p(s2,s1,s0,s2,s2), inference(mp, [status(thm)], [rule2, s25, neq7, neq8])).
fof(s27, plain, p(s1,s1,s0,s2,s2), inference(mp, [status(thm)], [rule1, s26])).
fof(s28, plain, p(s1,s1,s2,s2,s2), inference(mp, [status(thm)], [rule3, s27, neq4, neq6, neq4, neq6])).
fof(s29, plain, p(s0,s1,s2,s2,s2), inference(mp, [status(thm)], [rule1, s28])).
fof(s30, plain, p(s0,s2,s2,s2,s2), inference(mp, [status(thm)], [rule2, s29, neq2, neq3])).
fof(goal_1, theorem, p(s2,s2,s2,s2,s2), inference(mp, [status(thm)], [rule1, s30])).
% SZS output end Proof
