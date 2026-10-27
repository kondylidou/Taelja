% SZS output start Proof
cnf(sos_04, axiom, eq(f(X1), a0), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYO/SYO611-1.p', sos_04)).
cnf(sos_02, axiom, le(X1, X3) | ~ le(max(X1, X2), X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYO/SYO611-1.p', sos_02)).
cnf(sos_03, axiom, le(X2, X3) | ~ le(max(X1, X2), X3), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYO/SYO611-1.p', sos_03)).
cnf(sos_01, axiom, le(X1, X1), file('/Users/kondylidou/Desktop/TPTP-v9.2.1/Problems/SYO/SYO611-1.p', sos_01)).
fof(goal_1, theorem, ! [X] : eq(f(X),a0), inference(instantiate, [status(thm)], [sos_04])).
fof(goal_2, theorem, ! [X,Y,Z] : eq(f(max(max(X,s(Y)),Z)),a0), inference(instantiate, [status(thm)], [sos_04])).
fof(s1, plain, ! [Y,X,Z] : le(max(max(Y,s(X)),Z),max(max(Y,s(X)),Z)), inference(instantiate, [status(thm)], [sos_01])).
fof(s2, plain, ! [Y,X,Z] : le(max(Y,s(X)),max(max(Y,s(X)),Z)), inference(mp, [status(thm)], [sos_02, s1])).
fof(goal_3, theorem, ! [X,Y,Z] : le(s(X),max(max(Y,s(X)),Z)), inference(mp, [status(thm)], [sos_03, s2])).
% SZS output end Proof
