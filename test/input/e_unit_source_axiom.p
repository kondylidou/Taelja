% The problem of the E proof whose copies of axioms are bare unit sources.
cnf(ax1,axiom,less_equal(X,top)).
cnf(ax2,axiom,member(X,Y)|~less_equal(X,Y)).
cnf(neg,negated_conjecture,~member(a,top)).
