# Croatian Religious Terms — v3 (repaired + tiered + vocabulary expansion)
#
# SEPARATE FILE BY DESIGN, like v2. `R/religious_terms.R` (v1) stays frozen for the moral-economy
# census and the inflation-salience/EMIP pipeline; `R/religious_terms_v2.R` stays frozen as the
# repair-only baseline the 440-item study measured. Only code that names THIS file uses v3.
#
# v3 = v2 (94 terms) + 25 curated terms filling vocabulary holes the coded sample exposed.
# The v1/v2 lists contain *župnik* but not *župa*, *pobožnost* but not *molitva*, and nothing at
# all for Bog, Isus, Krist, vjernik, samostan, propovijed, apostol or krštenje.
#
# Measured on the 440 hand-coded items (studies/filter-validation/08_expanded_terms.R):
#   v1  any 2 of 95    precision 59,2  recall 93,2
#   v2  tiered, 94     precision 81,2  recall 81,2
#   v3  tiered, 119    precision 80,1  recall 91,5   <- recovers the recall, keeps the precision
# FITTED, NOT VALIDATED — these terms were written after seeing the coded data. The held-out
# 300-item sample (09_draw_holdout.R) exists to replace these numbers with honest ones.
# Corroboration: fully automatic term selection done INSIDE cross-validation folds reaches
# precision 80,1 / recall 90,0 — within noise of the curated list.
#
# Inclusion rule, unchanged from v2: >= 1 DECISIVE term AND >= 2 terms in total.

digikat_v3_path_v2 <- file.path("R", "religious_terms_v2.R")
if (!file.exists(digikat_v3_path_v2)) stop("v3 requires ", digikat_v3_path_v2, call. = FALSE)
digikat_v3_base <- source(digikat_v3_path_v2,
                          local = new.env(parent = baseenv()), encoding = "UTF-8")$value

# --- the 25 curated additions -----------------------------------------------------------------
# Each pattern is word-anchored wherever an ordinary Croatian word could otherwise swallow it.
# The comment after a pattern names the secular word it must NOT match; 08_expanded_terms.R
# asserts every one of those, so a future edit that re-opens a homonym fails loudly.
digikat_v3_add <- data.frame(
    term = c(
      "molitva", "vjernik", "župa", "krist", "isus",
      "božji", "propovijed", "homilija", "samostan", "svetkovina",
      "krštenje", "apostol", "prorok", "oltar", "procesija",
      "spasenje", "milosrđe", "vjeroučitelj", "klanjanje", "djevica marija",
      "bog", "vjera", "blaženi", "kapela", "duša"
    ),
    root = c(
      "molitv", "vjernik", "žup", "krist", "isus",
      "božj", "propovijed", "homilij", "samostan", "svetkovin",
      "kršten", "apostol", "prorok", "oltar", "procesij",
      "spasenj", "milosrđ", "vjerouč", "klanjanj", "djevic",
      "bog", "vjer", "blažen", "kapel", "duš"
    ),
    regex = c(
      "\\bmolitv[aeiou][jmz]*\\b",                        # molitva; not "molim"
      "\\bvjerni[ck][aeiou]?[jmz]*\\b",                   # vjernik/vjernici; not "vjerojatno"
      "\\bžup[aeiou]\\b|\\bžupn[aeiou]",                  # župa/župni; not "županija"
      "\\bkrist[aeou]?[mv]*\\b|\\bkristov",               # Krist; not "kristal"
      "\\bisus[aeou]?[mv]*\\b|\\bisusov",                 # Isus; not "isušiti"
      "\\bbožj[aeiou][mg]*[aeiou]*\\b",                   # božji/božje; not "božićni"
      "\\bpropovijed[aeiou]?[jmiz]*\\b|\\bpropovjedni",
      "\\bhomilij[aeiou][jmz]*\\b",
      "\\bsamostan[aeiou]?[mz]*\\b|\\bsamostansk[aeiou]",
      "\\bsvetkovin[aeiou][jmz]*\\b",
      "\\bkršten[aeiou]?[jmz]*\\b",
      "\\bapostol[aeiou]?[mz]*\\b|\\bapostolsk[aeiou]",
      "\\bprorok[aeiou]?[mz]*\\b|\\bproro[cč][aeiou]",
      "\\boltar[aeiou]?[mz]*\\b|\\boltarsk[aeiou]",
      "\\bprocesij[aeiou][jmz]*\\b",
      "\\bspasenj[aeu]\\b",                               # spasenje; not "spasilac"
      "\\bmilosrđ[aeu]\\b|\\bmilosrdn[aeiou]",
      "\\bvjerouč[aeiou]?[a-zšđčćž]*",
      "\\bklanjanj[aeu]\\b",
      "\\bdjevic[aeiou]\\s+marij[aeiou]|\\bblažen[aeiou][jmz]*\\s+djevic",
      "\\bbog[au]?\\b|\\bbogom\\b|\\bbogu\\b",            # Bog; not "bogatstvo"
      "\\bvjer[aeiou]\\b|\\bvjerom\\b",                   # vjera; not "vjerojatno"
      "\\bblažen[aeiou][jmz]*\\b",
      "\\bkapel[aeiou][mz]*\\b",                          # kapela; not "kapelan"
      "\\bduš[aeiou]\\b|\\bdušom\\b"                      # duša; not "dušik"
    ),
  tier = c(
    rep("decisive", 20),                                  # molitva ... djevica marija
    rep("ambiguous", 5)                                   # bog, vjera, blaženi, kapela, duša
  ),
  stringsAsFactors = FALSE
)

religious_terms <- rbind(
  digikat_v3_base[, c("term", "root", "regex", "tier")],
  digikat_v3_add
)
rm(digikat_v3_path_v2, digikat_v3_base, digikat_v3_add)

# Fail loud rather than silently shipping a mis-sized or mis-tiered list.
stopifnot(
  nrow(religious_terms) == 119L,
  !anyDuplicated(religious_terms$term),
  sum(religious_terms$tier == "decisive") == 100L,
  sum(religious_terms$tier == "ambiguous") == 19L
)

religious_terms_version <- "v3-2026-08-07"

# Export the data frame (last expression, so source(...)$value also works)
religious_terms
