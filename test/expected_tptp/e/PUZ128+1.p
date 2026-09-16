% SZS output start Proof
fof(thersandros_not_patricidal, axiom, ~ patricide(thersandros), file('Problems/PUZ/PUZ128+1.p', thersandros_not_patricidal)).
fof(polyneikes_thersandros, axiom, parent_of(polyneikes, thersandros), file('Problems/PUZ/PUZ128+1.p', polyneikes_thersandros)).
fof(iokaste_polyneikes, axiom, parent_of(iokaste, polyneikes), file('Problems/PUZ/PUZ128+1.p', iokaste_polyneikes)).
fof(oedipus_polyneikes, axiom, parent_of(oedipus, polyneikes), file('Problems/PUZ/PUZ128+1.p', oedipus_polyneikes)).
fof(oedipus_patricidal, axiom, patricide(oedipus), file('Problems/PUZ/PUZ128+1.p', oedipus_patricidal)).
fof(iokaste_oedipus, axiom, parent_of(iokaste, oedipus), file('Problems/PUZ/PUZ128+1.p', iokaste_oedipus)).
fof(c_0_11, assumption, ! [X,Y] : ((parent_of(iokaste,X) & patricide(X) & parent_of(X,Y)) => patricide(Y)), introduced(assumption, [], [])).
fof(lemma_8, lemma, patricide(polyneikes), inference(mp, [status(thm), assumptions([c_0_11])], [c_0_11, iokaste_oedipus, oedipus_patricidal, oedipus_polyneikes])).
fof(s1, plain, patricide(thersandros), inference(mp, [status(thm), assumptions([c_0_11])], [c_0_11, iokaste_polyneikes, lemma_8, polyneikes_thersandros])).
fof(s2, plain, $false, inference(mp, [status(thm), assumptions([c_0_11])], [thersandros_not_patricidal, s1])).
fof(iokaste_parent_particide_parent_not_patricide, theorem, ? [X1, X2]: (parent_of(iokaste, X1) & patricide(X1) & parent_of(X1, X2) & ~ patricide(X2)), inference(implies, [status(thm), discharge(implies, [c_0_11])], [s2, c_0_11])).
% SZS output end Proof
