# CANDIDATE rule v4 — the improved gate 1, as measured in RESULTS.md section 10.
#
# STUDY-LOCAL AND NOT PROMOTED. Nothing in R/ reads this. It changes what would be in the corpus,
# so promoting it to `R/religious_terms_v4.R` + `R/lib/religious_filter_v4.R` is a HARD GATE under
# .claude/rules/plan-first-workflow.md and waits on the two PI decisions in
# quality_reports/plans/2026-08-10_filter-rule-v4-window-and-denomination.md.
#
# v4 = v3's 119 patterns, unchanged, plus three rule-level changes:
#
#   1. WINDOW      match inside the first `cap` characters only, the same text gate 2 and the human
#                  coder see. Measured: 9,7% of v3 accepts pass only on evidence past char 3000 and
#                  0 of 18 such posts read were genuinely Catholic (0,0% [0,0-17,6]).
#   2. BOŽJI       `božji` moves decisive -> ambiguous. It fires on pious formulas that carry no
#                  religious content ("počivao u miru Božjem", "za ime Božje").
#   3. VETO        reject when a non-Catholic religious marker is present AND no Catholic-specific
#                  term is. 87,0% of coded genuine posts carry a Catholic-specific term against
#                  11,1% of `religious_other`. Costs 0 genuine posts of the 50 read.
#
# The inclusion test itself is untouched: >= 1 decisive AND >= 2 distinct patterns in total.
#
# Deliberately NOT included, because each was measured and added nothing:
#   - a 26-phrase formulaic-Bog stoplist (subsumed by change 2)
#   - restricting `blaženi` to "bl. <Name>" / "Blažena Djevica" (subsumed)
#   - dropping `duša` and `kaptol` (3 junk removed, 1 genuine lost across 1040 coded posts) —
#     available as `drop_marginal = TRUE`, off by default, PI's call.

DIGIKAT_V4_CAP <- 3000L

# The 54 v3 terms that are specific to Catholic (and partly Orthodox) institutional life. The shared
# Christian core — Bog, Isus, Krist, vjera, molitva, evanđelje — is deliberately EXCLUDED: it is
# exactly what fails to discriminate denomination.
DIGIKAT_V4_CATHOLIC <- c(
  "papa","papinstvo","vatikan","vatikanski","sveta stolica","biskup","biskupija","nadbiskup",
  "nadbiskupija","kardinal","župa","župnik","kapelan","svećenik","misa","euharistija","sakrament",
  "krizma","ispovijed","krunica","franjevac","franjevci","isusovac","dominikanac","redovnik",
  "redovnica","časna sestra","časne sestre","samostan","katedrala","bazilika","kaptol","hodočasnik",
  "hodočašće","procesija","katolička crkva","zaređenje","đakon","sveti red","vjeronauk",
  "vjeroučitelj","liturgija","homilija","oltar","relikvija","monsinjor","kapitul","svetkovina",
  "gospa","djevica marija","srce isusovo","pobožnost","klanjanje","križni put")

# Markers of a religion other than Catholicism. Not a filter on their own — only the second half of
# the veto. Kept as one regex because these are not corpus terms and never need tier accounting.
DIGIKAT_V4_OTHER <- paste(c(
  "džamij","imam[ai]?\\b","hafiz","kur'?an","ramazan","medres","džemat","mukabel","muslimansk",
  "islamsk","allah","bajram","efendij",
  "pravoslavn","patrijarh","eparhij","protojerej","mitropolit","ikonostas",
  "pastor[aiu]?\\b","evanđeosk","baptist","adventist","jehovin","pentekost","protestantsk",
  "biblijska škola"), collapse = "|")

# Returns a data frame, one row per input text: the verdict and every intermediate quantity, so a
# rejection can always be explained. `terms` is the v3 data frame from
# digikat_load_religious_terms_v2("R/religious_terms_v3.R").
digikat_rule_v4 <- function(text, terms, cap = DIGIKAT_V4_CAP, drop_marginal = FALSE,
                            veto = TRUE, progress = FALSE) {
  stopifnot(all(c("term", "regex", "tier") %in% names(terms)))
  win <- substr(as.character(text), 1L, cap)                        # change 1
  H <- digikat_hit_matrix(win, terms, progress = progress)

  tier <- terms$tier; names(tier) <- terms$term
  tier["božji"] <- "ambiguous"                                      # change 2
  if (drop_marginal) H[, terms$term %in% c("duša", "kaptol")] <- FALSE

  n_dec <- rowSums(H[, tier[terms$term] == "decisive", drop = FALSE])
  n_tot <- rowSums(H)
  gate1 <- n_dec >= 1L & n_tot >= 2L

  cath <- rowSums(H[, terms$term %in% DIGIKAT_V4_CATHOLIC, drop = FALSE]) > 0
  oth  <- stringi::stri_detect_regex(win, DIGIKAT_V4_OTHER, case_insensitive = TRUE)
  vetoed <- if (isTRUE(veto)) oth & !cath else rep(FALSE, length(win))  # change 3

  data.frame(keep = gate1 & !vetoed, gate1 = gate1, vetoed = vetoed,
             n_decisive = n_dec, n_total = n_tot,
             has_catholic_term = cath, has_other_religion_marker = oth,
             chars = nchar(as.character(text)), truncated = nchar(as.character(text)) > cap)
}
