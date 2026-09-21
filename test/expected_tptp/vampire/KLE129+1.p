% SZS output start Proof
fof(f4, axiom, ! [X0]: addition(X0, X0) = X0, file('Problems/KLE/KLE129+1.p')).
fof(f16, axiom, ! [X0]: domain(X0) = antidomain(antidomain(X0)), file('Problems/KLE/KLE129+1.p')).
fof(f23, axiom, ! [X0, X1]: forward_diamond(X0, X1) = domain(multiplication(X0, domain(X1))), file('Problems/KLE/KLE129+1.p')).
fof(f27, axiom, ! [X0]: forward_diamond(X0, divergence(X0)) = divergence(X0), file('Problems/KLE/KLE129+1.p')).
fof(f33, definition, ? [X0]: (zero != divergence(X0) & ! [X1]: (domain(X1) = zero | forward_diamond(X0, domain(X1)) != addition(domain(X1), forward_diamond(X0, domain(X1))))) => (zero != divergence(sK0) & ! [X1]: (domain(X1) = zero | forward_diamond(sK0, domain(X1)) != addition(domain(X1), forward_diamond(sK0, domain(X1))))), introduced(definition, [new_symbols(definition, [sK0])], [])).
fof(f62, assumption, ! [Y] : (forward_diamond(sK0,domain(Y)) = addition(domain(Y),forward_diamond(sK0,domain(Y))) => zero = domain(Y)), introduced(assumption, [], [])).
fof(s1, plain, ! [X,Y] : forward_diamond(X,Y) = antidomain(antidomain(multiplication(X,domain(Y)))), inference(rewrite, [status(thm)], [f16, f23])).
fof(lemma_6, lemma, ! [X,Y] : forward_diamond(X,Y) = antidomain(antidomain(multiplication(X,antidomain(antidomain(Y))))), inference(rewrite, [status(thm)], [f16, s1])).
fof(s2, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = forward_diamond(sK0,antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))))), inference(instantiate, [status(thm)], [f16])).
fof(s3, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = forward_diamond(sK0,forward_diamond(sK0,divergence(sK0))), inference(rewrite, [status(thm)], [lemma_6, s2])).
fof(s4, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = forward_diamond(sK0,divergence(sK0)), inference(rewrite, [status(thm)], [f27, s3])).
fof(s5, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = divergence(sK0), inference(rewrite, [status(thm)], [f27, s4])).
fof(s6, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(divergence(sK0),divergence(sK0)), inference(rewrite, [status(thm)], [f4, s5])).
fof(s7, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(divergence(sK0),forward_diamond(sK0,divergence(sK0))), inference(rewrite, [status(thm)], [f27, s6])).
fof(s8, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(forward_diamond(sK0,divergence(sK0)),forward_diamond(sK0,divergence(sK0))), inference(rewrite, [status(thm)], [f27, s7])).
fof(s9, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(forward_diamond(sK0,divergence(sK0)),forward_diamond(sK0,forward_diamond(sK0,divergence(sK0)))), inference(rewrite, [status(thm)], [f27, s8])).
fof(s10, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))),forward_diamond(sK0,forward_diamond(sK0,divergence(sK0)))), inference(rewrite, [status(thm)], [lemma_6, s9])).
fof(s11, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))),forward_diamond(sK0,antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))))), inference(rewrite, [status(thm)], [lemma_6, s10])).
fof(s12, plain, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(domain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))),forward_diamond(sK0,antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))))), inference(rewrite, [status(thm)], [f16, s11])).
fof(lemma_7, lemma, forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))) = addition(domain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))),forward_diamond(sK0,domain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))))), inference(rewrite, [status(thm)], [f16, s12])).
fof(lemma_8, lemma, zero = domain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))), inference(mp, [status(thm), assumptions([f62])], [f62, lemma_7])).
fof(s13, plain, divergence(sK0) = forward_diamond(sK0,divergence(sK0)), inference(instantiate, [status(thm)], [f27])).
fof(s14, plain, divergence(sK0) = antidomain(antidomain(multiplication(sK0,antidomain(antidomain(divergence(sK0)))))), inference(rewrite, [status(thm)], [lemma_6, s13])).
fof(s15, plain, divergence(sK0) = domain(multiplication(sK0,antidomain(antidomain(divergence(sK0))))), inference(rewrite, [status(thm)], [f16, s14])).
fof(s16, plain, divergence(sK0) = zero, inference(rewrite, [status(thm), assumptions([f62])], [lemma_8, s15])).
fof(f29, theorem, ! [X0]: (! [X1]: (addition(domain(X1), forward_diamond(X0, domain(X1))) = forward_diamond(X0, domain(X1)) => domain(X1) = zero) => divergence(X0) = zero), inference(implies, [status(thm), discharge(implies, [f62])], [s16, f62])).
% SZS output end Proof
