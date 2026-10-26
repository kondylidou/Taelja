% SZS output start Proof
fof(skolem_definition, definition, ? [X0, X1]: ~ f(f(X0)) = f(g(X1)) => ~ f(f(sK0)) = f(g(sK1)), introduced(definition, [new_symbols(definition, [sK0,sK1])], [])).
fof(f1, axiom, ! [X0, X1]: f(X0) = g(X1), file('/home/tptp/TPTP-v9.3.1/Problems/SYN/SYN080+1.p', pel58_1)).
fof(s1, plain, ! [X] : f(g(sK1)) = g(X), inference(instantiate, [status(thm)], [f1])).
fof(s2, plain, f(g(sK1)) = f(g(sK1)), inference(rewrite, [status(thm)], [f1, s1])).
fof(s3, plain, f(f(sK0)) = f(g(sK1)), inference(rewrite, [status(thm)], [f1, s2])).
fof(discharged, plain, f(f(sK0)) = f(g(sK1)), inference(conclude, [status(thm)], [s3])).
fof(f2, theorem, ! [X0, X1]: f(f(X0)) = f(g(X1)), inference(generalization, [status(thm)], [discharged, skolem_definition])).
% SZS output end Proof
