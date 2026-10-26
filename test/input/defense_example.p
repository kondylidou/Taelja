% The running example of the PhD defense slides. James is a cat, he catches
% a mouse, and he brings home what he catches. A cat that brings home a mouse
% is happy.
fof(james_is_cat, axiom, cat(james)).
fof(james_catches_mouse, axiom, catches(james, mouse)).
fof(brings_home_catch, axiom, ! [Y] : (catches(james, Y) => brings(james, Y))).
fof(happy, axiom, ! [X] : ((brings(X, mouse) & cat(X)) => happy(X))).
fof(goal, conjecture, happy(james)).
