% SZS output start Proof
fof(skolem_definition, definition, ? [X0]: ~ leq(X0, strong_iteration(one)) => ~ leq(x0, strong_iteration(one)), introduced(definition, [new_symbols(definition, [x0])], [])).
cnf(c4, axiom, multiplication(A, one) = A, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', multiplicative_right_identity)).
cnf(c5, axiom, addition(A2, A2) = A2, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', idempotence)).
fof(c7, axiom, ! [B, A2]: (leq(A2, B) <=> addition(A2, B) = B), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', order)).
cnf(c10, axiom, addition(A2, addition(B2, C)) = addition(addition(A2, B2), C), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', additive_associativity)).
cnf(c14, axiom, multiplication(one, A2) = A2, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', multiplicative_left_identity)).
cnf(c16, axiom, multiplication(addition(A2, B2), C2) = addition(multiplication(A2, C2), multiplication(B2, C2)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', distributivity2)).
fof(c18, axiom, ! [A2, B2, C2]: (leq(C2, addition(multiplication(A2, C2), B2)) => leq(C2, multiplication(strong_iteration(A2), B2))), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', infty_coinduction)).
fof(axiom_5, plain, ! [X,Y] : (addition(X,Y) = Y => leq(X,Y)), inference(clausify, [status(thm)], [c7])).
fof(s1, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(addition(x0,x0),addition(multiplication(one,x0),one)), inference(instantiate, [status(thm)], [c10])).
fof(lemma_8, lemma, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(multiplication(one,x0),one)), inference(rewrite, [status(thm)], [c5, s1])).
fof(s2, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(multiplication(one,x0),one)), inference(instantiate, [status(thm)], [lemma_8])).
fof(s3, plain, leq(x0,addition(x0,addition(multiplication(one,x0),one))), inference(mp, [status(thm)], [axiom_5, s2])).
fof(s4, plain, leq(x0,addition(addition(x0,multiplication(one,x0)),one)), inference(rewrite, [status(thm)], [c10, s3])).
fof(s5, plain, leq(x0,addition(addition(multiplication(one,x0),multiplication(one,x0)),one)), inference(rewrite, [status(thm)], [c14, s4])).
fof(s6, plain, leq(x0,addition(multiplication(addition(one,one),x0),one)), inference(rewrite, [status(thm)], [c16, s5])).
fof(s7, plain, leq(x0,multiplication(strong_iteration(addition(one,one)),one)), inference(mp, [status(thm)], [c18, s6])).
fof(s8, plain, leq(x0,strong_iteration(addition(one,one))), inference(rewrite, [status(thm)], [c4, s7])).
fof(s9, plain, leq(x0,strong_iteration(one)), inference(rewrite, [status(thm)], [c5, s8])).
fof(discharged, plain, leq(x0,strong_iteration(one)), inference(conclude, [status(thm)], [s9])).
fof(c1, theorem, ! [X0]: leq(X0, strong_iteration(one)), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
