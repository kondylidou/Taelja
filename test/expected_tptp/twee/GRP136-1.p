% SZS output start Proof
cnf(c2, hypothesis, least_upper_bound(a, b) = a, file('TPTP/Problems/GRP/GRP136-1.p', ax_antisyma_2)).
cnf(c3, hypothesis, least_upper_bound(a, b) = b, file('TPTP/Problems/GRP/GRP136-1.p', ax_antisyma_1)).
fof(s1, plain, a = least_upper_bound(a,b), inference(instantiate, [status(thm)], [c2])).
fof(goal_1, theorem, a = b, inference(rewrite, [status(thm)], [c3, s1])).
% SZS output end Proof
