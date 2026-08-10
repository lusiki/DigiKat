# Croatian Religious Terms — v2 (repaired + tiered)
#
# SEPARATE FILE BY DESIGN. `R/religious_terms.R` (v1, 95 terms, unanchored) is FROZEN and is NOT
# modified: the moral-economy census and the inflation-salience/EMIP pipeline both rebuild their
# regexes from it and fail loud on drift. Nothing that reads v1 today is affected by this file.
# Only code that explicitly loads `R/religious_terms_v2.R` uses the repaired rule.
#
# Provenance: v1 (95 terms) with
#   (a) nine unanchored patterns anchored to whole words, and
#   (b) the standalone term "časna" dropped — "časna sestra" already covers it
#       -> 94 terms
#   (c) a `tier` column: 80 decisive terms (meaningless outside a religious context) and
#       14 ambiguous ones (need company).
#
# Measured on the 440 hand-coded items of studies/filter-validation (2026-08-07), under the rule
# ">=1 decisive AND >=2 total": precision 59,2% -> 81,2%, recall 93,2% -> 81,2%.
# Those figures are FITTED, NOT VALIDATED — the rule was tuned on the same items it is scored on.
# See studies/filter-validation/RESULTS.md §4 before quoting either number.
#
# The nine repairs, with the secular word each one stops matching:
#   misa       komisija, misija, misao        gospa       gospodin, gospođa, gospodarstvo
#   papa       papir, papar                   križ        križanje, Križevci
#   demon      demonstracije                  posvećenje  "posvećen radu"
#   ukazanje   ukazano                        kler        (unbounded suffix run)
#   kaptol     (unbounded suffix run)
# \b is Unicode-aware in ICU/stringi, so the anchors are safe with č ć ž š đ. Do NOT ASCII-fold.

religious_terms <- data.frame(
  term = c(
    "biskup", "đakon", "blagoslov", "kardinal", "nadbiskup", "sveti otac",
    "papa", "vatikan", "bazilika", "križ", "nadbiskupija", "misa",
    "sakrament", "pavlin", "demon", "kršćanstvo", "stepinac", "katedrala",
    "euharistija", "biskupija", "relikvija", "svećenik", "provincijal", "franjevac",
    "kršćanin", "kapelan", "kler", "franjevci", "kaptol", "crkveni",
    "krunica", "redovnik", "redovnica", "krizma", "gospa", "pobožnost",
    "pontifikat", "sveto pismo", "katolička crkva", "katekizam", "vjeronauk", "teologija",
    "pričest", "duhovnost", "časna sestra", "papinski", "benediktinac", "evanđelje",
    "hodočasnik", "ispovijed", "dominikanac", "gvardijan", "teološki", "došašće",
    "sveto trojstvo", "liturgija", "posvećenje", "križni put", "sveta stolica", "trapist",
    "hodočašće", "enciklika", "pontif", "bezgrešno začeće", "nuncij", "monsinjor",
    "sveti križ", "isusovac", "presveti oltarski sakrament", "vatikanski", "časne sestre", "ispovjedaonica",
    "srce isusovo", "karmelićanin", "kapitul", "salezijanac", "opus dei", "duhovnik",
    "celibat", "rimokatolička crkva", "sveti red", "ukazanje", "korizma", "bolesničko pomazanje",
    "jezuiti", "papinstvo", "hostija", "vazmeno trodnevlje", "sveta krunica", "neokaljano srce",
    "zaređenje", "apostolsko nasljeđe", "nicejsko vjerovanje", "župnik"
  ),

  root = c(
    "biskup", "đakon", "blagoslov", "kardinal", "biskup", "otac",
    "pap", "vatikan", "bazilik", "križ", "biskup", "mis",
    "sakrament", "pavlin", "demon", "kršćan", "stepinac", "katedra",
    "euharistij", "biskup", "relikvij", "svećen", "provincial", "franjev",
    "kršćan", "kapelan", "kler", "franjev", "kaptol", "crkv",
    "krunic", "redovn", "redovn", "krizm", "gosp", "pobožn",
    "pontifikat", "pism", "crkv", "katekizm", "vjeronauk", "teolog",
    "pričest", "duhov", "sestr", "pap", "benediktin", "evanđelj",
    "hodočasn", "ispovijed", "dominikan", "gvardijan", "teolog", "došašć",
    "trojstv", "liturgij", "posveć", "put", "stolic", "trapist",
    "hodočašć", "enciklik", "pontif", "začeć", "nuncij", "monsinjor",
    "križ", "isusov", "sakrament", "vatikan", "sestr", "ispovijed",
    "isusov", "karmelić", "kapitul", "salezijan", "opus", "duhov",
    "celibat", "crkv", "red", "ukazan", "koriz", "pomazan",
    "jezuit", "pap", "hostij", "trodnevlj", "krunic", "src",
    "zared", "nasljeđ", "vjerovan", "župnik"
  ),

  regex = c(
    "biskup[aeiou]?[mnjstz]*",
    "đakon[aeiou]?[mnstz]*",
    "blagoslov[aeiou]?[jlmnst]*",
    "kardinal[aeiou]?[mnstz]*",
    "nadbiskup[aeiou]?[jmnstz]*",
    "sv(et[ieo]g?|ij)[aeiou]?\\s+ot[acš][aeiou]?[cmz]*",
    "\\bpap[aeiou]\\b|\\bpapom\\b|\\bpapin[aeiou]*\\b",           # REPAIRED (was pap[aeiou][jmnstz]*)
    "vatikan[aeiou]?[smz]*",
    "bazilik[aeiou][jmz]*",
    "\\bkriž(a|u|em|evi|eva)?\\b",                                 # REPAIRED (was križ[aeou]?[jmnvz]*)
    "nadbiskupij[aeiou][jmz]*",
    "\\bmis[aeu]\\b|\\bmisi\\b|\\bmisom\\b|\\bmisama\\b|\\bmisn[aeiou]",  # REPAIRED (was mis[aeiou][jmz]*)
    "sakrament[aeiou]?[jmnstv]*",
    "pavlin[aeiou]?[cmz]*",
    "\\bdemon(a|i|u|om|ima)?\\b|\\bdemonsk[aeiou]",                # REPAIRED (was demon[aeiou]?[jmstz]*)
    "kršćan[aeiou]?[smstv]*",
    "stepinac[aeiou]?[cmz]*",
    "katedra[l][aeiou][jmz]*",
    "euharistij[aeiou][jmsz]*",
    "biskupij[aeiou][jmz]*",
    "relikvij[aeiou][jmz]*",
    "svećen[ijoš][kč][aeiou]?[jmnz]*",
    "provincial[aeiou]?[jmnstv]*",
    "franjev[acč][aeiou]?[cmz]*",
    "kršćan[ijaeo][nmz]*",
    "kapelan[aeiou]?[jmnstv]*",
    "\\bkler[aui]?\\b|\\bklerik",                                  # REPAIRED (was kler[aeiou]?[jmnstv]*)
    "franjev[acč][aeio][jz]*",
    "\\bkaptol[aeiou]?\\b",                                        # REPAIRED (was kaptol[aeiou]?[jmstz]*)
    "crkv[aeiou]?[njmstz]*",
    "krunic[aeiou][jmsz]*",
    "redovn[io][kč][aeiou]?[jmz]*",
    "redovni[cč][aeiou][jmsz]*",
    "krizm[aeiou][jmsz]*",
    "\\bgosp[aeiu]\\b|\\bgospom\\b|\\bgospin[aeiou]*\\b",          # REPAIRED (was gosp[aeiou][jmsz]*)
    "pobožn[io][jst][aeiou]?[jmstz]*",
    "pontifikat[aeiou]?[jmstz]*",
    "sv(et[ieo]g?|ij)[aeiou]?\\s+pism[aou][jmz]*",
    "katoli[čć][kč][aeiou]?[jmstz]*\\s+crkv[aeiou][jmsz]*",
    "katekizm[aeiou]?[jmstz]*",
    "vjeronauk[aeiou]?[jmstv]*",
    "teolog[ijoš][jk][aeiou]?[jmstz]*",
    "pričest[aeiou]?[jmstz]*",
    "duhov[nš][io][jst][aeiou]?[jmstz]*",
    "časn[aeiou]?[jmstz]*\\s+sestr[aeiou][jmsz]*",
    "papinsk[aeiou][jmstz]*",
    "benediktin[acč][aeiou]?[cmz]*",
    "evanđelj[aeiou][jmstz]*",
    "hodočasn[ijoš][kč][aeiou]?[jmz]*",
    "ispovijed[aeiou]?[jmstz]*",
    "dominikan[acč][aeiou]?[cmz]*",
    "gvardijan[aeiou]?[jmstz]*",
    "teološk[aeiou][jmstz]*",
    "došašć[aeiou][jmsz]*",
    "sv(et[ieo]g?|ij)[aeiou]?\\s+trojstv[aou][jmsz]*",
    "liturgij[aeiou][jmstz]*",
    "\\bposvećenj[aeu]\\b",                                        # REPAIRED (was posveć[aeioš][njv][aeiou]?[jmstz]*)
    "križn[aeiou][jmstz]*\\s+put[aeiou]?[jmstz]*",
    "sv(et[aeiou]g?|ij)[aeiou]?\\s+stolic[aeiou][jmsz]*",
    "trapist[aeiou]?[jmstz]*",
    "hodočašć[aeiou][jmsz]*",
    "enciklik[aeiou][jmsz]*",
    "pontif[aeiou]?[jmstz]*",
    "bezgrešn[io][jmstz]*\\s+začeć[aeiou][jmsz]*",
    "nuncij[aeiou][jmsz]*",
    "monsinjor[aeiou]?[jmstz]*",
    "sv(et[ieo]g?|ij)[aeiou]?\\s+križ[aeiou]?[jmnvz]*",
    "isusov[acč][aeiou]?[cmz]*",
    "presv(et[ieo]g?|ij)[aeiou]?\\s+oltarsk[aeiou][jmstz]*\\s+sakrament[aeiou]?[jmstz]*",
    "vatikansk[aeiou][jmstz]*",
    "časn[aeiou][jmstz]*\\s+sestr[aeiou][jmsz]*",
    "ispovijeda?oni[cč][aeiou][jmsz]*",
    "sr[cč][aeiou]\\s+isusov[aeiou][jmstz]*",
    "karmelić[aeiou]?[nz][aeiou]?[jmstz]*",
    "kapitul[aeiou]?[jmstz]*",
    "salezijan[acč][aeiou]?[cmz]*",
    "opus\\s+dei",
    "duhovn[io][kč][aeiou]?[jmstz]*",
    "celibat[aeiou]?[jmstz]*",
    "rimokatolič[kč][aeiou]?[jmstz]*\\s+crkv[aeiou][jmsz]*",
    "sv(et[ieo]g?|ij)[aeiou]?\\s+red[aeiou]?[jmnstv]*",
    "\\bukazanj[aeu]\\b",                                          # REPAIRED (was ukazan[aeiou]?[jmstz]*)
    "koriz[mš][aeiou][jmsz]*",
    "bolesnič[kč][aeiou]?[jmstz]*\\s+pomazan[aeiou]?[jmstz]*",
    "jezuit[aeiou]?[jmstz]*",
    "papinstv[aou][jmsz]*",
    "hostij[aeiou][jmsz]*",
    "vazmen[aeiou][jmstz]*\\s+trodnevlj[aeiou][jmsz]*",
    "sv(et[aeiou]g?|ij)[aeiou]?\\s+krunic[aeiou][jmsz]*",
    "neokaljano\\s+sr[cč][aeiou]",
    "zaređ[aeioš][njv][aeiou]?[jmstz]*",
    "apostolsk[aeiou][jmstz]*\\s+nasljeđ[aeiou][jmstz]*",
    "nicejsk[aeiou][jmstz]*\\s+vjerovan[aeiou]?[jmstz]*",
    "župn[io][kč][aeiou]?[jmstz]*"
  ),

  stringsAsFactors = FALSE
)

# --- tiers -----------------------------------------------------------------------------------
# Ambiguous = the term also occurs in ordinary secular Croatian, so on its own it is not evidence
# of religious content. Everything else is decisive.
DIGIKAT_AMBIGUOUS_TERMS <- c(
  "misa", "gospa", "papa", "križ", "demon", "posvećenje", "ukazanje", "kler", "kaptol",
  "kršćanin", "kršćanstvo", "vatikan", "duhovnost", "blagoslov"
)

religious_terms$tier <- ifelse(
  religious_terms$term %in% DIGIKAT_AMBIGUOUS_TERMS, "ambiguous", "decisive"
)

# Fail loud rather than silently shipping a mis-tiered list.
stopifnot(
  nrow(religious_terms) == 94L,
  !anyDuplicated(religious_terms$term),
  sum(religious_terms$tier == "ambiguous") == 14L,
  sum(religious_terms$tier == "decisive") == 80L,
  all(DIGIKAT_AMBIGUOUS_TERMS %in% religious_terms$term)
)

religious_terms_version <- "v2-2026-08-07"

# Export the data frame (last expression, so source(...)$value also works)
religious_terms
