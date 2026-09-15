tff(person_type, type, person: $tType).
tff(city_type, type, city: $tType).
tff(a_type, type, a: person).
tff(f_type, type, f: person > person).
tff(g_type, type, g: person > person).
tff(home_type, type, home: person > city).
tff(q_type, type, q: person > $o).
tff(s_type, type, s: person > $o).
tff(p_type, type, p: (person * city) > $o).
tff(ax1, axiom, ! [X: person]: f(X) = X).
tff(ax2, axiom, ! [X: person]: g(X) = f(X)).
tff(ax3, axiom, ! [X: person]: (g(X) = X => q(X))).
tff(ax4, axiom, s(a)).
tff(ax5, axiom, ! [X: person, C: city]: ((s(X) & q(X) & C = home(X)) => p(X, C))).
tff(goal, conjecture, p(a, home(a))).
