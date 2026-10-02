tff(country_type,type, country: $tType ).
tff(sweden_type,type, sweden: country ).
tff(germany_type,type, germany: country ).
tff(liechtenstein_type,type, liechtenstein: country ).
tff(nato_type,type, nato: country > $o ).
tff(attacked_type,type, attacked: ( country * country ) > $o ).
tff(protects_type,type, protects: ( country * country ) > $o ).
tff(nato_protection,axiom, ! [Country: country,Member: country,Attacker: country] : ( ( nato(Country) & nato(Member) & attacked(Attacker,Member) ) => protects(Country,Member) ) ).
tff(sweden_nato,axiom, nato(sweden) ).
tff(germany_nato,axiom, nato(germany) ).
tff(liechtenstein_attacked_germany,axiom, attacked(liechtenstein,germany) ).
tff(sweden_protects_germany,conjecture, protects(sweden,germany) ).
