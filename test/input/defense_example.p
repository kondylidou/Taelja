% The running example of the PhD defense slides. James is a cat, he brings
% home what he catches, and he catches a mouse. A cat that brings home a
% mouse is happy.
fof(brings_home_catch, axiom, brings_home(james) = catch(james)).
fof(catches_mouse, axiom, catch(james) = mouse).
fof(james_is_cat, axiom, cat(james)).
fof(happy, axiom, ! [X] : ((brings_home(X) = mouse & cat(X)) => happy(X))).
fof(goal, conjecture, happy(james)).
