% SZS output start Proof
fof(skolem_definition, definition, ? [X0]: ~ leq(X0, strong_iteration(one)) => ~ leq(x0, strong_iteration(one)), introduced(definition, [new_symbols(definition, [x0])], [])).
cnf(c4, axiom, multiplication(A, one) = A, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', multiplicative_right_identity)).
cnf(c5, axiom, addition(A2, A2) = A2, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', idempotence)).
fof(c7, axiom, ! [B, A2]: (leq(A2, B) <=> addition(A2, B) = B), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', order)).
cnf(c10, axiom, addition(A2, addition(B2, C)) = addition(addition(A2, B2), C), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', additive_associativity)).
cnf(c14, axiom, multiplication(one, A2) = A2, file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', multiplicative_left_identity)).
cnf(c16, axiom, multiplication(addition(A2, B2), C2) = addition(multiplication(A2, C2), multiplication(B2, C2)), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', distributivity2)).
fof(c18, axiom, ! [A2, B2, C2]: (leq(C2, addition(multiplication(A2, C2), B2)) => leq(C2, multiplication(strong_iteration(A2), B2))), file('/home/user/Desktop/TPTP-v9.2.1/Problems/KLE/KLE137+1.p', infty_coinduction)).
fof(axiom_6, plain, ! [Y,Z] : (addition(Y,Z) = Z => leq(Y,Z)), inference(clausify, [status(thm)], [c7])).
fof(s1, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(x0,addition(multiplication(one,multiplication(one,x0)),one))), inference(instantiate, [status(thm)], [c14])).
fof(s2, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(multiplication(one,x0),addition(multiplication(one,multiplication(one,x0)),one))), inference(rewrite, [status(thm)], [c14, s1])).
fof(s3, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(multiplication(one,x0),addition(multiplication(one,x0),addition(multiplication(one,multiplication(one,x0)),one))), inference(rewrite, [status(thm)], [c14, s2])).
fof(s4, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(multiplication(one,x0),addition(multiplication(one,x0),addition(multiplication(one,x0),one))), inference(rewrite, [status(thm)], [c14, s3])).
fof(s5, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(addition(multiplication(one,x0),multiplication(one,x0)),addition(multiplication(one,x0),one)), inference(rewrite, [status(thm)], [c10, s4])).
fof(s6, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(multiplication(one,x0),addition(multiplication(one,x0),one)), inference(rewrite, [status(thm)], [c5, s5])).
fof(s7, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(multiplication(one,x0),addition(multiplication(one,multiplication(one,x0)),one)), inference(rewrite, [status(thm)], [c14, s6])).
fof(s8, plain, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(multiplication(one,multiplication(one,x0)),one)), inference(rewrite, [status(thm)], [c14, s7])).
fof(lemma_8, lemma, addition(x0,addition(x0,addition(multiplication(one,x0),one))) = addition(x0,addition(multiplication(one,x0),one)), inference(rewrite, [status(thm)], [c14, s8])).
fof(lemma_9, lemma, leq(x0,addition(x0,addition(multiplication(one,x0),one))), inference(mp, [status(thm)], [axiom_6, lemma_8])).
fof(s9, plain, leq(x0,addition(x0,addition(multiplication(one,multiplication(one,x0)),one))), inference(rewrite, [status(thm)], [c14, lemma_9])).
fof(s10, plain, leq(x0,addition(x0,addition(multiplication(one,multiplication(addition(one,one),x0)),one))), inference(rewrite, [status(thm)], [c5, s9])).
fof(s11, plain, leq(x0,addition(multiplication(one,x0),addition(multiplication(one,multiplication(addition(one,one),x0)),one))), inference(rewrite, [status(thm)], [c14, s10])).
fof(s12, plain, leq(x0,addition(multiplication(addition(one,one),x0),addition(multiplication(one,multiplication(addition(one,one),x0)),one))), inference(rewrite, [status(thm)], [c5, s11])).
fof(s13, plain, leq(multiplication(one,x0),addition(multiplication(addition(one,one),x0),addition(multiplication(one,multiplication(addition(one,one),x0)),one))), inference(rewrite, [status(thm)], [c14, s12])).
fof(s14, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),addition(multiplication(one,multiplication(addition(one,one),x0)),one))), inference(rewrite, [status(thm)], [c5, s13])).
fof(s15, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),one))), inference(rewrite, [status(thm)], [c14, s14])).
fof(s16, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),addition(one,one)))), inference(rewrite, [status(thm)], [c5, s15])).
fof(s17, plain, leq(multiplication(addition(one,one),x0),addition(addition(multiplication(addition(one,one),x0),multiplication(addition(one,one),x0)),addition(one,one))), inference(rewrite, [status(thm)], [c10, s16])).
fof(s18, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),addition(one,one))), inference(rewrite, [status(thm)], [c5, s17])).
fof(s19, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),x0),one)), inference(rewrite, [status(thm)], [c5, s18])).
fof(s20, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(one,multiplication(addition(one,one),x0)),one)), inference(rewrite, [status(thm)], [c14, s19])).
fof(s21, plain, leq(multiplication(addition(one,one),x0),addition(multiplication(addition(one,one),multiplication(addition(one,one),x0)),one)), inference(rewrite, [status(thm)], [c5, s20])).
fof(s22, plain, leq(multiplication(one,x0),addition(multiplication(addition(one,one),multiplication(addition(one,one),x0)),one)), inference(rewrite, [status(thm)], [c5, s21])).
fof(s23, plain, leq(x0,addition(multiplication(addition(one,one),multiplication(addition(one,one),x0)),one)), inference(rewrite, [status(thm)], [c14, s22])).
fof(s24, plain, leq(x0,addition(multiplication(addition(one,one),multiplication(one,x0)),one)), inference(rewrite, [status(thm)], [c5, s23])).
fof(lemma_10, lemma, leq(x0,addition(multiplication(addition(one,one),x0),one)), inference(rewrite, [status(thm)], [c14, s24])).
fof(lemma_11, lemma, leq(x0,multiplication(strong_iteration(addition(one,one)),one)), inference(mp, [status(thm)], [c18, lemma_10])).
fof(s25, plain, leq(x0,strong_iteration(addition(one,one))), inference(rewrite, [status(thm)], [c4, lemma_11])).
fof(s26, plain, leq(x0,strong_iteration(one)), inference(rewrite, [status(thm)], [c5, s25])).
fof(discharged, plain, leq(x0,strong_iteration(one)), inference(conclude, [status(thm)], [s26])).
fof(c1, theorem, ! [X0]: leq(X0, strong_iteration(one)), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
