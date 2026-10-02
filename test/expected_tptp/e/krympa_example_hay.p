% SZS output start Proof
fof(ax1, axiom, ! [X1]: h(a, X1) = c, file('/home/user/Developer/Taelja/test/input/krympa_example_hay.p', ax1)).
fof(ax2, axiom, ! [X2]: h(X2, b) = X2, file('/home/user/Developer/Taelja/test/input/krympa_example_hay.p', ax2)).
fof(s1, plain, a = h(a,b), inference(instantiate, [status(thm)], [ax2])).
fof(goal, theorem, a = c, inference(rewrite, [status(thm)], [ax1, s1])).
% SZS output end Proof
