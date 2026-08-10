# Croatian Religious Terms — v4
#
# SEPARATE FILE, like v2 and v3. v1 (R/religious_terms.R) stays frozen for the moral-economy and
# inflation-salience pipelines; v2 and v3 stay frozen as the versions their measurements refer to.
#
# v4 = v3 with four corrections found by reading the patterns against real Croatian (2026-08-10):
#
#   1. `sveti otac` matched ONLY the nominative. "svetog oca" and "svetom ocu" — the Pope in the
#      genitive and dative, both very common — scored zero. Now all cases match.
#   2. `bog` missed the vocative "Bože", which is everywhere in devotional writing.
#   3. `križ` missed "križevima" and "križeve". Still refuses "Križevci" and "križanje".
#   4. `crkveni` DEMOTED from decisive to ambiguous. The pattern `crkv...` matches "crkva" of any
#      denomination — `srpska pravoslavna crkva` cleared the whole gate on it. Measured on the 740
#      hand-coded posts: where crkv is the ONLY decisive match, just 37% are genuinely Catholic,
#      against 78% where something else fires. Demoting costs 7 genuine posts and removes 12 junk.
#      A blanket Orthodox/Islamic block was considered and REJECTED: 69% of accepted posts that
#      mention those markers are genuine Catholic articles discussing other faiths.
#
# Counts: 99 decisive, 20 ambiguous, 119 terms. Rule unchanged: >=1 decisive AND >=2 total.

digikat_v4_path_v3 <- file.path("R", "religious_terms_v3.R")
if (!file.exists(digikat_v4_path_v3)) stop("v4 requires ", digikat_v4_path_v3, call. = FALSE)
religious_terms <- source(digikat_v4_path_v3,
                          local = new.env(parent = baseenv()), encoding = "UTF-8")$value

digikat_v4_fix <- function(tab, term, regex = NULL, tier = NULL) {
  i <- which(tab$term == term)
  if (length(i) != 1L) stop("v4: expected exactly one '", term, "'", call. = FALSE)
  if (!is.null(regex)) tab$regex[i] <- regex
  if (!is.null(tier))  tab$tier[i]  <- tier
  tab
}

# 1. the Pope in every case: sveti otac / svetog oca / svetom ocu / sveti oče
religious_terms <- digikat_v4_fix(religious_terms, "sveti otac",
  regex = "\\bsvet(i|og|oga|om|omu|ome)?\\s+o(tac|ca|cu|če|cem)\\b")

# 2. Bože
religious_terms <- digikat_v4_fix(religious_terms, "bog",
  regex = "\\bbog[au]?\\b|\\bbogom\\b|\\bbogu\\b|\\bbože\\b")

# 3. križevima / križeve, still not Križevci or križanje
religious_terms <- digikat_v4_fix(religious_terms, "križ",
  regex = "\\bkriž(a|u|em|evi|eva|evima|eve)?\\b")

# 4. "church" alone is not evidence of WHICH church
religious_terms <- digikat_v4_fix(religious_terms, "crkveni", tier = "ambiguous")

rm(digikat_v4_path_v3, digikat_v4_fix)

stopifnot(
  nrow(religious_terms) == 119L,
  !anyDuplicated(religious_terms$term),
  sum(religious_terms$tier == "decisive")  == 99L,
  sum(religious_terms$tier == "ambiguous") == 20L
)

religious_terms_version <- "v4-2026-08-10"

religious_terms
