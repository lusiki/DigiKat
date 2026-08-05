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

TABDIR <- file.path(ME_OUT, "tables"); dir.create(TABDIR, showWarnings = FALSE, recursive = TRUE)

# The corpus count is the one constant that does not live in this study's output/: it is the master
# manifest (data/merged_comprehensive.rds, 710 307 rows) recorded in MEMORY.md and CLAUDE.local.md.
CORPUS_N <- 710307L

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

g  <- grad[grad$code == "ax1_link_genuine", ]
base <- summ[summ$variant == "baseline", ]
bd   <- det[det$variant == "baseline", ]

# The doctrinal population size is read from the gated core table rather than restated.
CORE_CACHE <- file.path(ME_PRIVATE, "cst_core.rds")
CORE_POSTS <- if (file.exists(CORE_CACHE)) nrow(readRDS(CORE_CACHE)) else NA_integer_
if (is.na(CORE_POSTS)) stop("output/private/cst_core.rds is missing; run 14_cst_core_profile.R first.")

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
SRC <- function(x) paste0("*Source: authors' calculation on the DigiKat corpus of 710 307 Croatian ",
                          "digital media posts, 2021–2026. ", x, "*")

derived <- list()   # every scalar the manuscript's prose quotes, re-derivable by 25_paper_checks.R
put <- function(name, value) derived[[name]] <<- value

## ---- TABLE 1 — construction of the analysis population ---------------------------------------
LINKED_POSTS <- base$posts; LINKED_PAIRS <- base$pairs
T1_CORPUS <- cens$n_corpus[cens$group == "tier1_strict"]
T1_LAYER  <- cens$n_linked_econ[cens$group == "tier1_strict"]
ANY_LAYER <- cens$n_linked_econ[cens$group == "any_tier"]
CORE_PAIRS <- sum(g$doctrinal)

pc <- function(n, d) rsp_num(100 * n / d, 2)
write_tab("tab1_population.md",
  "**Table 1.** How we get from the whole corpus down to the posts we analyse.",
  c("Group of posts", "Posts", "% of corpus", "% of meeting posts", "Pairs"),
  c("l", "r", "r", "r", "r"),
  list(
    c("All posts in the corpus", rsp_int(CORPUS_N), "100,00", "—", "—"),
    c("Posts using a teaching word anywhere", rsp_int(T1_CORPUS), pc(T1_CORPUS, CORPUS_N), "—", "—"),
    c("**Posts where religion and economics meet**", paste0("**", rsp_int(LINKED_POSTS), "**"),
      paste0("**", pc(LINKED_POSTS, CORPUS_N), "**"), "**100,00**",
      paste0("**", rsp_int(LINKED_PAIRS), "**")),
    c("… of these, posts using a teaching word", rsp_int(T1_LAYER), pc(T1_LAYER, CORPUS_N),
      pc(T1_LAYER, LINKED_POSTS), "—"),
    c("… **using it nearby, the teaching posts**", paste0("**", rsp_int(CORE_POSTS), "**"),
      paste0("**", pc(CORE_POSTS, CORPUS_N), "**"), paste0("**", pc(CORE_POSTS, LINKED_POSTS), "**"),
      paste0("**", rsp_int(CORE_PAIRS), "**")),
    c("*Memo.* Everyday political words counted too", rsp_int(ANY_LAYER), pc(ANY_LAYER, CORPUS_N),
      pc(ANY_LAYER, LINKED_POSTS), "—")),
  SRC(paste0("Religion and economics count as meeting when a religious term falls within 220 ",
             "characters of an economic term. A post becomes a teaching post when one of the ",
             "Tier-1 teaching words listed in Table A1 is within 220 characters as well; that ",
             "last condition ",
             "removes ", rsp_int(T1_LAYER - CORE_POSTS), " posts. A pair is one post counted on one ",
             "economic subject. The memo row adds the Tier-2 words, which are everyday political ",
             "words we never count as teaching, and shows how high the count could possibly go.")))
put("adjacency_cost", T1_LAYER - CORE_POSTS)
put("linked_posts", LINKED_POSTS); put("linked_pairs", LINKED_PAIRS)
put("core_posts", CORE_POSTS);     put("core_pairs", CORE_PAIRS)
put("raw_rate_pairs", 100 * CORE_PAIRS / LINKED_PAIRS)
put("raw_rate_posts", 100 * CORE_POSTS / LINKED_POSTS)
put("tier2_ceiling", 100 * ANY_LAYER / LINKED_POSTS)

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
write_tab("tab2_audits.md",
  "**Table 2.** What we found when we read posts by hand to check the search.",
  c("What we checked", "What was read", "n", "Rate (%)", "95% CI or range", "Set in advance"),
  c("l", "l", "r", "r", "r", "r"),
  list(
    c("**Check 1.** The teaching is genuinely used", "teaching posts", rsp_int(r1("r1_genuine")$n),
      paste0("**", rsp_num(r1("r1_genuine")$rate, 1), "**"),
      rsp_ci(r1("r1_genuine")$lo, r1("r1_genuine")$hi, 1), "≥ 80"),
    c("Check 1b. The teaching word is really there", "same 150 posts", rsp_int(r1("r1_not_false")$n),
      rsp_num(r1("r1_not_false")$rate, 1), rsp_ci(r1("r1_not_false")$lo, r1("r1_not_false")$hi, 1), "—"),
    c("Check 2. The economic word is really economic", "same 150 posts", rsp_int(r1("r2_econ_true")$n),
      rsp_num(r1("r2_econ_true")$rate, 1), rsp_ci(r1("r2_econ_true")$lo, r1("r2_econ_true")$hi, 1), "—"),
    c("Checks 1 and 2 both passed", "same 150 posts", rsp_int(r1("r1_and_r2")$n),
      rsp_num(r1("r1_and_r2")$rate, 1), rsp_ci(r1("r1_and_r2")$lo, r1("r1_and_r2")$hi, 1), "—"),
    c("**Check 3.** Religion and economics really meet", "60 pairs per subject", rsp_int(sum(n4)),
      paste0("**", rsp_num(W_GEN, 1), "**"), band(min(p_gen), max(p_gen)), "—"),
    c("Check 3 under the strict reading", "the same 660 pairs", rsp_int(sum(n4)), rsp_num(W_STR, 1),
      band(min(p_str), max(p_str)), "—")),
  SRC(paste0("Each rate is the share of the posts or pairs read that passed the check, and the ",
             "last column shows a threshold fixed before any coding began. Check 3 is ",
             "weighted by how large each economic subject is, and subjects differ from one another ",
             "(χ²(10) = ", rsp_num(CHISQ, 1), "). The strict reading also requires the economic ",
             "word to carry a plainly economic sense. Intervals are Wilson intervals; they express ",
             "how well the search rules match a human reading, not sampling uncertainty.")))
put("w_gen", W_GEN); put("w_str", W_STR); put("chisq", as.numeric(CHISQ))
put("prec_min", min(p_gen)); put("prec_max", max(p_gen))
put("corrected_headline", 100 * CORE_PAIRS / (LINKED_PAIRS * W_GEN / 100))
put("corrected_headline_strict", 100 * CORE_PAIRS / (LINKED_PAIRS * W_STR / 100))

## ---- TABLE 3 — the gradient, as measured and corrected ---------------------------------------
o <- order(-g$adj_rate, -g$raw_rate)
rows3 <- lapply(o, function(i) {
  d <- g$domain[i]; b <- bd[bd$domain == d, ]
  c(DOM[[d]], rsp_int(g$linked[i]), rsp_int(g$doctrinal[i]),
    rsp_num(g$raw_rate[i], 2), rsp_ci(b$lo, b$hi, 2), rsp_num(g$precision[i], 1),
    rsp_num(g$adj_rate[i], 2), rsp_ci(g$adj_lo[i], g$adj_hi[i], 2))
})
rows3[[length(rows3) + 1]] <- c("**All subjects**", paste0("**", rsp_int(sum(g$linked)), "**"),
  paste0("**", rsp_int(sum(g$doctrinal)), "**"),
  paste0("**", rsp_num(100 * sum(g$doctrinal) / sum(g$linked), 2), "**"), "—",
  paste0("**", rsp_num(W_GEN, 1), "**"),
  paste0("**", rsp_num(100 * sum(g$doctrinal) / (sum(g$linked) * W_GEN / 100), 2), "**"), "—")
write_tab("tab3_gradient.md",
  "**Table 3.** How often Church teaching is named, by economic subject, before and after correction.",
  c("Economic subject", "Pairs", "With teaching", "Measured rate (%)", "95% CI",
    "Genuine meetings (%)", "Corrected rate (%)", "95% CI"),
  c("l", "r", "r", "r", "r", "r", "r", "r"), rows3,
  SRC(paste0("Ordered by the corrected rate. A pair is one post counted on one economic subject. ",
             "The measured rate is the share of a subject's pairs that name teaching. The corrected ",
             "rate divides instead by the pairs that hand coding found to be genuine meetings ",
             "(Table 2, Check 3, 60 pairs per subject), and carries that coding interval through.")))
sortadj <- sort(g$adj_rate, decreasing = TRUE)
put("climate_raw", g$raw_rate[g$domain == "green_energy"])
put("climate_adj", g$adj_rate[g$domain == "green_energy"])
put("adj_ratio", sortadj[1] / sortadj[2])
put("raw_ratio", base$ratio)
put("rank_cor", suppressWarnings(cor(g$raw_rate, g$adj_rate, method = "spearman")))
put("poverty_linked", g$linked[g$domain == "poverty_social"])
put("poverty_share_pairs", 100 * g$doctrinal[g$domain == "poverty_social"] / CORE_PAIRS)
put("poverty_prec", g$precision[g$domain == "poverty_social"])
put("euro_hi", bd$hi[bd$domain == "euro_changeover"])

## ---- TABLE 4 — vintage composition ------------------------------------------------------------
tot <- tapply(core_era$Freq, core_era$domain, sum)
eras <- c("classical", "conciliar", "benedict", "francis", "mixed", "marker_only")
dom_ord <- names(sort(tot, decreasing = TRUE))
rows4 <- lapply(dom_ord, function(d) {
  x <- core_era[core_era$domain == d, ]
  sh <- vapply(eras, function(e) 100 * sum(x$Freq[x$era == e]) / tot[[d]], numeric(1))
  c(DOM[[d]], rsp_int(tot[[d]]), rsp_num(sh[1], 1), rsp_num(sh[2], 1), rsp_num(sh[3], 1),
    rsp_num(sh[4], 1), rsp_num(sh[5], 1), rsp_num(sh[6], 1))
})
write_tab("tab4_era.md",
  "**Table 4.** How old the documents named are, by economic subject (% of that subject's teaching pairs).",
  c("Economic subject", "Pairs with teaching", "1891–1991", "Conciliar (1961–1971)", "Benedict XVI",
    "Francis era", "Mixed eras", "No document named"),
  c("l", "r", "r", "r", "r", "r", "r", "r"), rows4,
  SRC(paste0("Rows sum to 100. “Mixed eras” marks a post that names documents from more than one ",
             "era, and “no document named” a post that names a principle of the teaching but no ",
             "document title. The euro changeover names no teaching at all and is left out.")))
era_share <- function(d, e) 100 * sum(core_era$Freq[core_era$domain == d & core_era$era == e]) / tot[[d]]
put("classical_green", era_share("green_energy", "classical"))
put("classical_housing", era_share("housing", "classical"))
put("classical_business", era_share("business_comp", "classical"))
put("classical_wages", era_share("wages_income", "classical"))
put("francis_green", era_share("green_energy", "francis"))

## ---- TABLE 5 — the Church-media / secular-media boundary --------------------------------------
sub_row <- function(variant, label) {
  s <- summ[summ$variant == variant, ]; dd <- det[det$variant == variant, ]
  c(label, rsp_int(s$pairs), rsp_num(100 * s$pairs / LINKED_PAIRS, 1),
    rsp_int(sum(dd$doctrinal)), rsp_num(100 * sum(dd$doctrinal) / CORE_PAIRS, 1),
    rsp_num(s$green_rate, 2), paste0(DOM[[s$next_domain]], " ", rsp_num(s$next_rate, 2)),
    paste0(rsp_num(s$ratio, 2), "×"))
}
CONF_L <- summ$pairs[summ$variant == "confessional_only"]
SECN_L <- summ$pairs[summ$variant == "secular_min"]
CONF_D <- sum(det$doctrinal[det$variant == "confessional_only"])
SECN_D <- sum(det$doctrinal[det$variant == "secular_min"])
write_tab("tab5_boundary.md",
  "**Table 5.** How often teaching is named inside Church media and inside secular media.",
  c("Group of outlets", "Pairs", "% of all pairs", "With teaching", "% of teaching pairs",
    "Climate rate (%)", "Next highest subject (%)", "Ratio"),
  c("l", "r", "r", "r", "r", "r", "l", "r"),
  list(sub_row("baseline", "All outlets together"),
       sub_row("confessional_only", "Church outlets"),
       sub_row("secular_min", "Secular outlets, labelled only"),
       sub_row("secular_max", "Secular outlets, widest reading")),
  SRC(paste0("Each rate is the share of that group's pairs which name teaching, so the climate ",
             "column can be read against the next highest subject beside it. “Widest reading” ",
             "counts every outlet we could not label as secular. Among pairs whose outlet carries ",
             "either label, Church outlets ",
             "supply ", rsp_num(100 * CONF_L / (CONF_L + SECN_L), 1), "% of the pairs but ",
             rsp_num(100 * CONF_D / (CONF_D + SECN_D), 1), "% of the pairs that name teaching.")))
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
  "**Table 6.** What the meeting between religion and economics is about (% of hand-coded links).",
  c("Economic subject", "Coded links", "Church as economic actor", "Charity, the language of help",
    "Justice, the language of rights", "Devotional or other"),
  c("l", "r", "r", "r", "r", "r"),
  lapply(seq_len(nrow(r)), function(i)
    c(DOM[[r$domain[i]]], rsp_int(r$n[i]), rsp_num(r$object[i], 1), rsp_num(r$charity[i], 1),
      rsp_num(r$justice[i], 1), rsp_num(r$remainder[i], 1))),
  SRC(paste0("Rows sum to 100. “Church as economic actor” means the Church itself is the economic ",
             "party in the story, such as a parish building or a diocesan sale, rather than a voice ",
             "about the economy. “Devotional or other” covers economic words used in a spiritual ",
             "sense and links that fit no other class. Subjects with fewer than ten coded links are ",
             "left out. These links come from a stratified gold set rather than a random draw, and ",
             "one model did the coding, so the table is convergent evidence, not a population ",
             "estimate.")))
put("poverty_charity", reg$charity[reg$domain == "poverty_social"])
put("poverty_justice", reg$justice[reg$domain == "poverty_social"])
put("poverty_remainder", reg$remainder[reg$domain == "poverty_social"])
put("poverty_reg_n", reg$n[reg$domain == "poverty_social"])
put("green_justice", reg$justice[reg$domain == "green_energy"])
put("gold_links_n", sum(reg$n))

## ---- TABLE A1 (appendix) — Tier-1 vocabulary inventory ------------------------------------------
# Three counts per term, because they answer three different questions: how much of the vocabulary
# exists in Croatian digital media at all, how much of it reaches an economic context, and how much
# survives the adjacency condition into the analysis population.
ct <- core_terms[order(-core_terms$n), ]
kindlab <- c(document = "document", marker = "principle")
write_tab("tab7_terms.md",
  "**Table A1.** Every Tier-1 teaching word we detect, counted at the three stages of Table 1.",
  c("Teaching word", "Type of word", "Era of the document", "In the corpus", "In meeting posts",
    "In teaching posts", "% of all uses"),
  c("l", "l", "l", "r", "r", "r", "r"),
  lapply(seq_len(nrow(ct)), function(i) {
    e <- ct$era[i]; e <- if (e %in% names(ERA)) ERA[[e]] else "—"
    cw <- cterm[match(ct$term[i], cterm$term), ]
    c(TERM[[ct$term[i]]], kindlab[[ct$kind[i]]], e, rsp_int(cw$n_corpus),
      rsp_int(cw$n_linked_econ), rsp_int(ct$n[i]), rsp_num(ct$pct[i], 2))
  }),
  SRC(paste0("Counts are posts carrying the word. “Type of word” separates the titles of Church ",
             "documents from the names of principles, and a principle belongs to no single era. The ",
             "teaching posts hold ", rsp_int(sum(ct$n)), " uses of these words across ",
             rsp_int(CORE_POSTS), " posts, since one post can carry several. The last column is the ",
             "share of those uses, which is what Figure 4 plots.")))
put("opcija_core", core_terms$n[core_terms$term == "opcija_za_siromasne"])
put("opcija_pct", core_terms$pct[core_terms$term == "opcija_za_siromasne"])
put("opcija_corpus", cterm$n_corpus[cterm$term == "opcija_za_siromasne"])
put("opcija_linked", cterm$n_linked_econ[cterm$term == "opcija_za_siromasne"])
put("socnauk_core", core_terms$n[core_terms$term == "socijalni_nauk"])
put("term_occurrences", sum(ct$n))
put("titles_above_opcija", sum(core_terms$n > core_terms$n[core_terms$term == "opcija_za_siromasne"] &
                                core_terms$kind == "document"))

## ---- derived scalars, for 25_paper_checks.R ----------------------------------------------------
out <- data.frame(name = names(derived), value = round(unlist(derived), 4), row.names = NULL)
write.csv(out, file.path(TABDIR, "rsp_derived.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("wrote", length(list.files(TABDIR, pattern = "^tab.*\\.md$")), "table fragments and",
    nrow(out), "derived scalars to output/tables/\n")
