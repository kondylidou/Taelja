tff(country_type,type, country: $tType ).
tff(sweden_type,type, sweden: country ).
tff(germany_type,type, germany: country ).
tff(russia_type,type, russia: country ).
tff(nato_member_type,type, nato_member: country > $o ).
tff(attacked_type,type, attacked: ( country * country ) > $o ).
tff(protects_type,type, protects: ( country * country ) > $o ).
tff(nato_protection,axiom, ! [Country: country,Member: country,Attacker: country] : ( ( nato_member(Country) & nato_member(Member) & attacked(Attacker,Member) ) => protects(Country,Member) ) ).
tff(sweden_nato_member,axiom, nato_member(sweden) ).
tff(germany_nato_member,axiom, nato_member(germany) ).
tff(russia_attacked_germany,axiom, attacked(russia,germany) ).
tff(sweden_protects_germany,conjecture, protects(sweden,germany) ).
