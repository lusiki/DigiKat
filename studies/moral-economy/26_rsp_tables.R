#!/usr/bin/env Rscript
# moral-economy — THE SEVEN TABLES FOR THE RSP SUBMISSION, GENERATED FROM output/.
#
# House rule 3 (CLAUDE.md): no hand-typed numbers in prose. A table is prose with a grid around it,
# so the manuscript's tables are BUILT here from the same CSVs the figures are built from, written
# as markdown fragments to output/tables/, and pasted into PAPER_RSP_v1.md verbatim.
# 25_paper_checks.R then asserts that every fragment still appears in the manuscript byte-for-byte,
# so a table cannot silently drift from the file that produced it.
#
# Cells are PADDED to a common column width. Markdown does not need the padding, but the manuscript
# is read as plain text in an editor far more often than it is rendered, and an unpadded table is
# unreadable there. Row labels are kept short for the same reason: anything that needs a sentence
# belongs in the source line under the table, not in a cell.
#
# Formatting follows RSP Part II: decimal comma, space thousands separator, a source line beneath
# every table. Fragments are UTF-8 (Croatian diacritics appear in the term column of Table A1).
#
#   Rscript studies/moral-economy/26_rsp_tables.R
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_labels.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/cst_core.R"))
rsp_assert_official_inputs()

TABDIR <- file.path(ME_OUT, "tables"); dir.create(TABDIR, showWarnings = FALSE, recursive = TRUE)

# Corpus size, span and provenance come from the official input manifest created by step 29.
INPUT_MANIFEST <- rsp_read_input_manifest()
CORPUS_MANIFEST <- digikat_read_corpus_manifest()
CORPUS_N <- as.integer(INPUT_MANIFEST$database$rows)
DATE_SPAN <- paste0(substr(INPUT_MANIFEST$database$date_min, 1, 4), "–",
                    substr(INPUT_MANIFEST$database$date_max, 1, 4))

rd <- function(f) read.csv(file.path(ME_OUT, f), fileEncoding = "UTF-8")
cens  <- rd("cst_census_summary.csv")
cterm <- rd("cst_census_terms.csv")
core_terms <- rd("cst_core_terms.csv")
core_era   <- rd("cst_core_domain_era.csv")
grad  <- rd("cst_gradient_adjusted.csv")
prec1 <- rd("r1_numerator_precision.csv")
prec4 <- rd("r4_linkage_precision.csv")
det   <- rd("cst_robustness_detail.csv")
summ  <- rd("cst_robustness_summary.csv")
reg   <- rd("gold_register_by_domain.csv")
gold_summary <- rd("gold_reanalysis_summary.csv")
stab  <- rd("rsp_annotation_stability.csv")
prov  <- rd("rsp_annotation_provenance.csv")
r1dom <- rd("r1_precision_by_domain.csv")
frame <- rd("cst_frame_sensitivity.csv")
lex_raw <- rd("cst_lexicon_sensitivity_summary.csv")
lex_adj <- rd("cst_lexicon_sensitivity_adjusted_summary.csv")
r4_manifest <- jsonlite::fromJSON(file.path(ME_SEM, "r4_recompute_manifest.json"), simplifyVector = TRUE)
frame_manifest <- jsonlite::fromJSON(file.path(ME_OUT, "cst_frame_sensitivity_manifest.json"), simplifyVector = TRUE)

g  <- grad[grad$code == "ax1_link_genuine", ]
gs <- grad[grad$code == "ax1_strict", ]
base <- summ[summ$variant == "baseline", ]
bd   <- det[det$variant == "baseline", ]

# Read the canonical corrected core and assert its post-pair representation before making tables.
core <- cst_build_core(verbose = FALSE)
core_pairs <- cst_core_pairs(core)
CORE_POSTS <- nrow(core)
CORE_PAIRS <- nrow(core_pairs)
if (sum(g$doctrinal) != CORE_PAIRS || sum(core_era$Freq) != CORE_PAIRS)
  stop("Core post-pair totals do not reconcile across outputs.", call. = FALSE)

## ---- markdown table writer with aligned columns ------------------------------------------------
pad <- function(x, w, right) {
  k <- max(w - nchar(x), 0)
  if (right) paste0(strrep(" ", k), x) else paste0(x, strrep(" ", k))
}
write_tab <- function(file, caption, header, align, rows, source_line) {
  m <- rbind(header, do.call(rbind, rows))
  w <- apply(m, 2, function(col) max(nchar(col)))
  line <- function(cells) paste0("| ", paste(mapply(pad, cells, w, align == "r"), collapse = " | "), " |")
  sep <- paste0("|", paste(mapply(function(wi, a)
    if (a == "r") paste0(strrep("-", wi + 1), ":") else paste0(":", strrep("-", wi + 1)),
    w, align), collapse = "|"), "|")
  # The source line is wrapped for the same plain-text readability as the cells. Numbers written
  # with a space thousands separator are protected so no wrap can fall inside "710 307".
  src <- gsub("(?<=[0-9]) (?=[0-9])", "\001", source_line, perl = TRUE)
  src <- gsub("\001", " ", strwrap(src, width = 100))
  lines <- c(caption, "", line(header), sep, vapply(rows, line, character(1)), "", src)
  con <- file(file.path(TABDIR, file), open = "wt", encoding = "UTF-8")
  on.exit(close(con)); writeLines(lines, con)
  invisible(NULL)
}
SRC <- function(x) paste0("*Source: authors' calculation on the official DigiKat corpus of ",
                          rsp_int(CORPUS_N), " Croatian digital media posts, ", DATE_SPAN, ". ", x, "*")

derived <- list()   # every scalar the manuscript's prose quotes, re-derivable by 25_paper_checks.R
put <- function(name, value) derived[[name]] <<- value

## ---- TABLE 1 — construction of the analysis population ---------------------------------------
LINKED_POSTS <- base$posts; LINKED_PAIRS <- base$pairs
T1_CORPUS <- cens$n_corpus[cens$group == "tier1_strict"]
T1_LAYER  <- cens$n_linked_econ[cens$group == "tier1_strict"]
ANY_LAYER <- cens$n_linked_econ[cens$group == "any_tier"]
INC_POSTS <- as.integer(frame_manifest$inclusive$core_posts)
INC_PAIRS <- as.integer(frame_manifest$inclusive$core_pairs)
INC_FRAME_POSTS <- as.integer(frame_manifest$inclusive$linked_posts)
INC_FRAME_PAIRS <- as.integer(frame_manifest$inclusive$linked_pairs)

pc <- function(n, d) rsp_num(100 * n / d, 2)
write_tab("tab1_population.md",
  "**Table 1.** The nested official-corpus populations.",
  c("Population", "Posts", "Post–subject pairs"),
  c("l", "r", "r"),
  list(
    c("Official Catholic-topic corpus", rsp_int(CORPUS_N), "—"),
    c("Main generic-religion Stage-A frame", rsp_int(LINKED_POSTS), rsp_int(LINKED_PAIRS)),
    c("Same-domain adjacent Tier-1 core", rsp_int(CORE_POSTS), rsp_int(CORE_PAIRS)),
    c("Inclusive Tier-1-as-religion frame sensitivity", rsp_int(INC_FRAME_POSTS), rsp_int(INC_FRAME_PAIRS)),
    c("Inclusive adjacent Tier-1 core sensitivity", rsp_int(INC_POSTS), rsp_int(INC_PAIRS))),
  SRC(paste0("Stage A requires a generic religion term within 220 characters of an economic expression. ",
             "Core pairs additionally require a Tier-1 marker within 220 characters of an expression from ",
             "that same economic subject. The inclusive rows are a frame sensitivity in which Tier 1 may ",
             "also satisfy religion entry.")))
put("adjacency_cost", T1_LAYER - CORE_POSTS)
put("linked_posts", LINKED_POSTS); put("linked_pairs", LINKED_PAIRS)
put("core_posts", CORE_POSTS);     put("core_pairs", CORE_PAIRS)
put("raw_rate_pairs", 100 * CORE_PAIRS / LINKED_PAIRS)
put("raw_rate_posts", 100 * CORE_POSTS / LINKED_POSTS)
put("tier2_ceiling", 100 * ANY_LAYER / LINKED_POSTS)
put("inclusive_core_posts", INC_POSTS); put("inclusive_core_pairs", INC_PAIRS)
put("inclusive_frame_posts", INC_FRAME_POSTS); put("inclusive_frame_pairs", INC_FRAME_PAIRS)

## ---- TABLE 2 — the validation audits ----------------------------------------------------------
den <- g$linked[match(prec4$domain[prec4$code == "ax1_link_genuine"], g$domain)]
p_gen <- prec4$precision[prec4$code == "ax1_link_genuine"]
p_str <- prec4$precision[prec4$code == "ax1_strict"][match(
  prec4$domain[prec4$code == "ax1_link_genuine"], prec4$domain[prec4$code == "ax1_strict"])]
W_GEN <- sum(p_gen * den) / sum(den)
W_STR <- sum(p_str * den) / sum(den)
k4 <- prec4$k[prec4$code == "ax1_link_genuine"]; n4 <- prec4$n[prec4$code == "ax1_link_genuine"]
CHISQ <- suppressWarnings(chisq.test(cbind(k4, n4 - k4))$statistic)

r1 <- function(a) prec1[prec1$axis == a, ]
band <- function(lo, hi) paste0(rsp_num(lo, 1), "–", rsp_num(hi, 1), " by subject")
R1_N <- r1("r1_genuine")$n
R4_N <- sum(n4)
R4_PER_DOMAIN <- paste0(min(n4), if (length(unique(n4)) == 1L) " pairs per subject" else "–",
                        if (length(unique(n4)) == 1L) "" else paste0(max(n4), " pairs per subject"))
st <- function(audit, axis) stab[stab$audit == audit & stab$axis == axis, ]
R2_SAMPLED <- sum(!is.na(r1dom$rate))
R2_UNSAMPLED <- sum(is.na(r1dom$rate))
R2_FAIL <- any(r1dom$rate[!is.na(r1dom$rate) & r1dom$domain != "green_energy"] < 70) ||
  r1dom$rate[r1dom$domain == "green_energy"] < 80 || R2_UNSAMPLED > 0
R2_DECISION <- if (isTRUE(R2_FAIL)) "**fail / unevaluable**" else "met"
POST_RAW <- 100 * CORE_POSTS / LINKED_POSTS
POST_INV_SENS <- POST_RAW * r1("r1_genuine")$rate / 100
POST_JOINT_SENS <- POST_RAW * r1("r1_and_r2")$rate / 100
write_tab("tab2_audits.md",
  "**Table 2.** Fresh blind Codex audits and predeclared decision rules.",
  c("Audit quantity", "n", "Estimate or agreement", "Decision"),
  c("l", "r", "r", "l"),
  list(
    c("R1 genuine CST invocation", rsp_int(r1("r1_genuine")$n),
      paste0(rsp_num(r1("r1_genuine")$rate, 1), "% ", rsp_ci(r1("r1_genuine")$lo, r1("r1_genuine")$hi, 1)),
      "Below 80%; conditional"),
    c("R1 marker present", rsp_int(r1("r1_not_false")$n),
      paste0(rsp_num(r1("r1_not_false")$rate, 1), "% ", rsp_ci(r1("r1_not_false")$lo, r1("r1_not_false")$hi, 1)),
      "Diagnostic"),
    c("R2 genuine economic referent", rsp_int(r1("r2_econ_true")$n),
      paste0(rsp_num(r1("r2_econ_true")$rate, 1), "% ", rsp_ci(r1("r2_econ_true")$lo, r1("r2_econ_true")$hi, 1)),
      "Domain gate fails/is unevaluable"),
    c("R1 and R2 jointly", rsp_int(r1("r1_and_r2")$n),
      paste0(rsp_num(r1("r1_and_r2")$rate, 1), "% ", rsp_ci(r1("r1_and_r2")$lo, r1("r1_and_r2")$hi, 1)),
      "Diagnostic"),
    c("R4 codebook linkage, layer-weighted", rsp_int(R4_N), paste0(rsp_num(W_GEN, 1), "%"),
      "Denominator sensitivity only"),
    c("R4 strict linkage, layer-weighted", rsp_int(R4_N), paste0(rsp_num(W_STR, 1), "%"),
      "Denominator sensitivity only"),
    c("Repeat R1 economic-referent axis", rsp_int(st("R1", "r2_econ_true")$n),
      paste0(rsp_num(100 * st("R1", "r2_econ_true")$agreement, 1), "%; κ = ",
             rsp_num(st("R1", "r2_econ_true")$kappa, 3)), "Below 80%; repeatability gate fails")),
  SRC(paste0("Fresh probability samples from the corrected official-corpus layers. Brackets are ",
             "audit-sample intervals conditional on Codex classifications, not uncertainty intervals ",
             "for census marker rates. R4 contains ", rsp_int(min(n4)), " pairs per subject. The exact ",
             "backend model version and decoding settings were unavailable.")))
put("w_gen", W_GEN); put("w_str", W_STR); put("chisq", as.numeric(CHISQ))
put("prec_min", min(p_gen)); put("prec_max", max(p_gen))
put("stability_agreement_min", 100 * min(stab$agreement))
put("stability_agreement_max", 100 * max(stab$agreement))
put("stability_kappa_min", min(stab$kappa)); put("stability_kappa_max", max(stab$kappa))
put("corrected_headline", 100 * CORE_PAIRS / (LINKED_PAIRS * W_GEN / 100))
put("corrected_headline_strict", 100 * CORE_PAIRS / (LINKED_PAIRS * W_STR / 100))
put("r1_genuine", r1("r1_genuine")$rate); put("r1_joint", r1("r1_and_r2")$rate)
put("post_raw", POST_RAW); put("post_invocation_sensitivity", POST_INV_SENS)
put("post_joint_sensitivity", POST_JOINT_SENS)

## ---- TABLE 3 — detected gradient and denominator-only sensitivity ------------------------------
o <- order(-g$raw_rate, -g$adj_rate)
rows3 <- lapply(o, function(i) {
  d <- g$domain[i]
  c(DOM[[d]], rsp_int(g$linked[i]), rsp_int(g$doctrinal[i]),
    rsp_num(g$raw_rate[i], 2), rsp_num(g$adj_rate[i], 2))
})
write_tab("tab3_gradient.md",
  "**Table 3.** Detected Tier-1 marker rates and denominator-only sensitivities by economic subject.",
  c("Economic subject", "Stage-A pairs", "Marked pairs", "Detected rate (%)",
    "Denominator-only sensitivity (%)"),
  c("l", "r", "r", "r", "r"), rows3,
  SRC(paste0("The detected rate is a census ratio for the observed corpus and has no sampling interval. ",
             "The sensitivity divides the detected numerator by an R4-estimated genuine-link denominator ",
             "and assumes every numerator pair qualifies; because R1/R2 do not pass, it is not corrected prevalence.")))
sortadj <- sort(g$adj_rate, decreasing = TRUE)
put("climate_raw", g$raw_rate[g$domain == "green_energy"])
put("climate_adj", g$adj_rate[g$domain == "green_energy"])
put("adj_ratio", sortadj[1] / sortadj[2])
put("raw_ratio", base$ratio)
put("rank_cor", suppressWarnings(cor(g$raw_rate, g$adj_rate, method = "spearman")))
put("green_first_prob", 100 * g$rank_first_prob[g$domain == "green_energy"])
put("strict_green_first_prob", 100 * gs$rank_first_prob[gs$domain == "green_energy"])
put("strict_macro", gs$adj_rate[gs$domain == "macro_aggregates"])
put("strict_taxes", gs$adj_rate[gs$domain == "taxes_fiscal"])
put("mc_draws", r4_manifest$draws)
put("r4_reused", sum(prov$reused[prov$audit == "R4"]))
put("r1_reused", sum(prov$reused[prov$audit == "R1"]))
put("poverty_linked", g$linked[g$domain == "poverty_social"])
put("poverty_share_pairs", 100 * g$doctrinal[g$domain == "poverty_social"] / CORE_PAIRS)
put("poverty_prec", g$precision[g$domain == "poverty_social"])
put("euro_hi", bd$hi[bd$domain == "euro_changeover"])
pick_lex <- function(spec, adjusted = FALSE) {
  z <- if (adjusted) lex_adj else lex_raw
  keep <- z$specification == spec
  if (adjusted) keep <- keep & z$code == "ax1_link_genuine"
  z[keep, ][1, ]
}
lx0 <- pick_lex("baseline")
lx1 <- pick_lex("leave_out_laudato_si")
lx2 <- pick_lex("leave_out_ecology_markers")
lxa1 <- pick_lex("leave_out_laudato_si", TRUE)
lxa2 <- pick_lex("leave_out_ecology_markers", TRUE)
put("no_laudato_climate_raw", lx1$green_rate)
put("no_laudato_top_raw", lx1$top_rate)
put("no_ecology_climate_raw", lx2$green_rate)
put("no_ecology_top_raw", lx2$top_rate)
put("no_laudato_climate_denom", lxa1$adjusted_green_rate)
put("no_laudato_top_denom", lxa1$adjusted_top_rate)
put("no_ecology_climate_denom", lxa2$adjusted_green_rate)
put("no_ecology_top_denom", lxa2$adjusted_top_rate)

## ---- TABLE 4 — vintage composition ------------------------------------------------------------
tot <- tapply(core_era$Freq, core_era$domain, sum)
eras <- c("classical", "conciliar", "benedict", "francis", "mixed", "marker_only")
dom_ord <- names(sort(tot[tot >= 10], decreasing = TRUE))
rows4 <- lapply(dom_ord, function(d) {
  x <- core_era[core_era$domain == d, ]
  nn <- vapply(c("benedict", "classical", "conciliar", "francis", "marker_only", "mixed"),
               function(e) sum(x$Freq[x$era == e]), numeric(1))
  c(DOM[[d]], vapply(nn, rsp_int, character(1)), rsp_int(tot[[d]]))
})
write_tab("tab4_era.md",
  "**Table 4.** Pair-specific adjacent document-title categories by economic subject.",
  c("Economic subject", "Benedict", "Non-conciliar classical line", "Conciliar/development",
    "Francis era", "No era-assigned document", "Mixed", "Total"),
  c("l", "r", "r", "r", "r", "r", "r", "r"), rows4,
  SRC(paste0("Categories are assigned separately for each post–subject pair from its adjacent terms. ",
             "They are mutually exclusive document-title sets, not contiguous calendar eras; doctrine-specific ",
             "markers, including the Compendium convention, appear under “No era-assigned document.” ",
             "Subjects with fewer than ten marked pairs are retained in the aggregate total but omitted from display.")))
era_share <- function(d, e) 100 * sum(core_era$Freq[core_era$domain == d & core_era$era == e]) / tot[[d]]
put("classical_green", era_share("green_energy", "classical"))
put("classical_housing", era_share("housing", "classical"))
put("classical_business", era_share("business_comp", "classical"))
put("classical_wages", era_share("wages_income", "classical"))
put("francis_green", era_share("green_energy", "francis"))

## ---- TABLE 5 — proposal-based outlet sensitivity -----------------------------------------------
sub_row <- function(variant, label) {
  s <- summ[summ$variant == variant, ]
  c(label, rsp_num(s$green_rate, 2), rsp_num(s$next_rate, 2), rsp_num(s$ratio, 2))
}
CONF_L <- summ$pairs[summ$variant == "confessional_only"]
SECN_L <- summ$pairs[summ$variant == "secular_min"]
CONF_D <- sum(det$doctrinal[det$variant == "confessional_only"])
SECN_D <- sum(det$doctrinal[det$variant == "secular_min"])
write_tab("tab5_boundary.md",
  "**Table 5.** Proposal-based outlet-group sensitivity for the two leading domains.",
  c("Proposed outlet group", "Climate and energy (%)", "Macroeconomics (%)", "Climate/macro ratio"),
  c("l", "r", "r", "r"),
  list(sub_row("confessional_only", "Confessional"),
       sub_row("secular_min", "Secular minimum"),
       sub_row("secular_max", "Secular maximum")),
  SRC(paste0("Automated, unratified outlet-label proposals. “Secular minimum” includes explicitly ",
             "proposed secular sources; “secular maximum” also includes unlabelled sources. Values are ",
             "descriptive detected-marker rates, not causal effects or validated outlet classifications.")))
put("conf_share_linked", 100 * CONF_L / LINKED_PAIRS)
put("conf_share_doctrinal", 100 * CONF_D / CORE_PAIRS)
put("conf_share_linked_labelled", 100 * CONF_L / (CONF_L + SECN_L))
put("conf_share_doctrinal_labelled", 100 * CONF_D / (CONF_D + SECN_D))
put("conf_climate", summ$green_rate[summ$variant == "confessional_only"])
put("conf_next", summ$next_rate[summ$variant == "confessional_only"])
put("conf_ratio", summ$ratio[summ$variant == "confessional_only"])
put("secmin_climate", summ$green_rate[summ$variant == "secular_min"])
put("secmin_next", summ$next_rate[summ$variant == "secular_min"])
put("secmin_ratio", summ$ratio[summ$variant == "secular_min"])
put("secmax_climate", summ$green_rate[summ$variant == "secular_max"])
put("secmax_next", summ$next_rate[summ$variant == "secular_max"])
put("secmax_ratio", summ$ratio[summ$variant == "secular_max"])
put("variants_first", sum(summ$green_first)); put("variants_n", nrow(summ))
put("variants_disjoint", sum(summ$intervals_disjoint))

## ---- TABLE 6 — register probe ------------------------------------------------------------------
r <- reg[reg$n >= 10, ]; r <- r[order(-r$n), ]
write_tab("tab6_register.md",
  "**Table 6.** Exploratory legacy register classifications in domains with at least ten genuine links (%).",
  c("Economic subject", "n", "Church as economic actor", "Relief/action",
    "Structural critique or CST principles", "Devotional/residual"),
  c("l", "r", "r", "r", "r", "r"),
  lapply(seq_len(nrow(r)), function(i)
    c(DOM[[r$domain[i]]], rsp_int(r$n[i]), rsp_num(r$object[i], 1), rsp_num(r$charity[i], 1),
      rsp_num(r$justice[i], 1), rsp_num(r$remainder[i], 1))),
  SRC(paste0("Reanalysis of an earlier ",
             rsp_int(gold_summary$legacy_rows), "-row stratified set: ", rsp_int(gold_summary$official_database_rows),
             " survive in the official database, ", rsp_int(gold_summary$official_linked_rows),
             " remain in the corrected linked layer, ", rsp_int(gold_summary$genuine_links),
             " are genuine links and ", rsp_int(gold_summary$displayed_n_ge_10),
             " appear in displayed domains with n ≥ 10. Labels came from three blind passes by one LLM ",
             "family. The allocation was not designed to estimate register prevalence, and the codebook ",
             "does not measure rights or entitlements.")))
put("poverty_charity", reg$charity[reg$domain == "poverty_social"])
put("poverty_justice", reg$justice[reg$domain == "poverty_social"])
put("poverty_remainder", reg$remainder[reg$domain == "poverty_social"])
put("poverty_reg_n", reg$n[reg$domain == "poverty_social"])
put("green_justice", reg$justice[reg$domain == "green_energy"])
put("gold_links_n", sum(reg$n))
put("gold_display_n", sum(r$n))
put("gold_database_n", gold_summary$official_database_rows)
put("gold_linked_n", gold_summary$official_linked_rows)

## ---- TABLE A1 (appendix) — Tier-1 vocabulary inventory ------------------------------------------
# Three counts per term, because they answer three different questions: how much of the vocabulary
# exists in Croatian digital media at all, how much of it reaches an economic context, and how much
# survives the adjacency condition into the analysis population.
t1_ids <- names(CST_TERMS)[CST_TIER %in% c("1_document", "1_marker")]
ct <- data.frame(
  term = t1_ids,
  n = core_terms$n[match(t1_ids, core_terms$term)],
  pct = core_terms$pct[match(t1_ids, core_terms$term)],
  kind = ifelse(t1_ids %in% names(CST_DOCS), "document", "marker"),
  era = unname(CST_ERA[t1_ids]),
  stringsAsFactors = FALSE
)
ct$n[is.na(ct$n)] <- 0L
ct$pct[is.na(ct$pct)] <- 0
ct <- ct[order(-ct$n, ct$term), ]
kindlab <- c(document = "Document title", marker = "Doctrine-specific marker")
write_tab("tab7_terms.md",
  "**Table A1.** Tier-1 document titles and doctrine-specific markers at each detection stage.",
  c("Marker", "Type", "Pair-specific title category", "Corpus posts", "Stage-A posts",
    "Adjacent term–post presences"),
  c("l", "l", "l", "r", "r", "r"),
  lapply(seq_len(nrow(ct)), function(i) {
    e <- ct$era[i]; e <- if (e %in% names(ERA)) ERA[[e]] else "—"
    cw <- cterm[match(ct$term[i], cterm$term), ]
    c(TERM[[ct$term[i]]], kindlab[[ct$kind[i]]], e, rsp_int(cw$n_corpus),
      rsp_int(cw$n_linked_econ), rsp_int(ct$n[i]))
  }),
  SRC(paste0("Entries are numbers of posts carrying each term at the stated stage; the final column ",
             "comprises ", rsp_int(sum(ct$n)), " term–post presences across ", rsp_int(CORE_POSTS),
             " teaching posts because one post may carry several terms. Counts are not numbers of ",
             "quotations or repeated occurrences. The Compendium is treated as a doctrine-specific ",
             "marker with no era-assigned document.")))
put("opcija_core", core_terms$n[core_terms$term == "opcija_za_siromasne"])
put("opcija_pct", core_terms$pct[core_terms$term == "opcija_za_siromasne"])
put("opcija_corpus", cterm$n_corpus[cterm$term == "opcija_za_siromasne"])
put("opcija_linked", cterm$n_linked_econ[cterm$term == "opcija_za_siromasne"])
put("socnauk_core", core_terms$n[core_terms$term == "socijalni_nauk"])
put("term_occurrences", sum(ct$n))
put("titles_above_opcija", sum(core_terms$n > core_terms$n[core_terms$term == "opcija_za_siromasne"] &
                                core_terms$kind == "document"))
put("corpus_n", CORPUS_N)
put("platforms_n", CORPUS_MANIFEST$corpus$platforms)
put("web_posts", CORPUS_MANIFEST$corpus$platform_counts$web)
put("corpus_terms", CORPUS_MANIFEST$rule$terms_count)
put("corpus_window", CORPUS_MANIFEST$rule$window_chars)
put("corpus_threshold", CORPUS_MANIFEST$rule$threshold)

## ---- derived scalars, for 25_paper_checks.R ----------------------------------------------------
out <- data.frame(name = names(derived), value = round(unlist(derived), 4), row.names = NULL)
write.csv(out, file.path(TABDIR, "rsp_derived.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("wrote", length(list.files(TABDIR, pattern = "^tab.*\\.md$")), "table fragments and",
    nrow(out), "derived scalars to output/tables/\n")
