% SZS output start Proof
cnf(c2, hypothesis, there_exists(codomain(a)), file('TPTP/Problems/CAT/CAT014-4.p', assume_codomain_exists)).
cnf(c3, axiom, ~ there_exists(compose(X, Y)) | domain(X) = codomain(Y), file('TPTP/Problems/CAT/CAT014-4.p', domain_codomain_composition1)).
cnf(c4, axiom, ~ there_exists(codomain(X2)) | there_exists(X2), file('TPTP/Problems/CAT/CAT014-4.p', codomain_has_elements)).
cnf(c6, axiom, compose(codomain(X2), X2) = X2, file('TPTP/Problems/CAT/CAT014-4.p', compose_codomain)).
cnf(c10, axiom, compose(X2, domain(X2)) = X2, file('TPTP/Problems/CAT/CAT014-4.p', compose_domain)).
fof(s1, plain, there_exists(a), inference(mp, [status(thm)], [c4, c2])).
fof(s2, plain, there_exists(compose(codomain(a),a)), inference(rewrite, [status(thm)], [c6, s1])).
fof(lemma_6, lemma, domain(codomain(a)) = codomain(a), inference(mp, [status(thm)], [c3, s2])).
fof(s3, plain, there_exists(compose(codomain(a),domain(codomain(a)))), inference(rewrite, [status(thm)], [c10, c2])).
fof(s4, plain, domain(codomain(a)) = codomain(domain(codomain(a))), inference(mp, [status(thm)], [c3, s3])).
fof(s5, plain, domain(codomain(a)) = codomain(codomain(a)), inference(rewrite, [status(thm)], [lemma_6, s4])).
fof(goal_1, theorem, codomain(codomain(a)) = codomain(a), inference(rewrite, [status(thm)], [lemma_6, s5])).
% SZS output end Proof
