#!/usr/bin/env Rscript
# moral-economy — STEP 12: CORPUS-WIDE CATHOLIC SOCIAL TEACHING CENSUS.
#
# The spine of the "CST in the public sphere" paper. The 555-item gold set says CST doctrine is nearly
# absent (29/555 name a principle, 4/555 name a document). A referee will answer "your sample missed it."
# This script answers at n = 710,307: a direct lexical census over the FULL corpus, so the absence claim
# carries no sampling assumption at all.
#
# TWO TIERS, and the tiering is the whole methodological point:
#   Tier 1 — UNAMBIGUOUS. Magisterial document titles and doctrine-specific coinages that have no ordinary
#            Croatian sense ("supsidijarnost", "integralna ekologija", "socijalni nauk"). These are the
#            hard count: a Tier-1 hit is a genuine invocation of the teaching.
#   Tier 2 — AMBIGUOUS, deliberately over-broad. "solidarnost", "opće dobro", "dostojanstvo rada" are CST
#            principles that are ALSO ordinary secular political vocabulary. Tier 2 cannot show presence —
#            it can only bound it. It exists so the paper can say: even counting every generic echo as a
#            doctrinal invocation, the ceiling is still low.
# Reporting Tier 2 as if it were CST presence would be the central error this design exists to prevent.
#
# READ-ONLY. Never opens the master. Writes aggregate-only CSVs (no text, URL, rid) — shareable by
# construction, enforced by sem_lib.R's disclosure guard.
#
#   Rscript studies/moral-economy/12_cst_census.R
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_lexicon.R"))   # terms, tiers, periodization, cst_detect()
source(here::here("studies/moral-economy/rsp_input.R"))

CORPUS <- RSP_CORPUS_PREPARED
CAND   <- RSP_STAGEA_CANDIDATES
CHUNK  <- 50000L

# ---- 1. the census lexicon ---------------------------------------------------------------------
# Terms, tiers, periodization and cst_detect() all live in cst_lexicon.R so 12 and 13 cannot drift.
TERMS <- CST_TERMS; TIER <- CST_TIER; FIXED <- CST_FIXED
# ---- 2. inputs ---------------------------------------------------------------------------------
cat("Reading corpus...\n")
rsp_assert_official_inputs()
if (!file.exists(CORPUS)) stop("No prepared corpus at ", CORPUS, call. = FALSE)
corpus <- readRDS(CORPUS)
digikat_require_columns(corpus, c("doc_id", "text", "data_source", "platform"), "corpus_prepared")
N <- nrow(corpus)
cat(sprintf("  %s rows\n", digikat_format_integer(N)))

rid_all <- as.integer(sub("^dk_", "", corpus$doc_id))

cand <- readRDS(CAND)
cat("  stageA_candidates columns: ", paste(names(cand), collapse = ", "), "\n", sep = "")
if (!"rid" %in% names(cand)) stop("stageA_candidates has no rid column.", call. = FALSE)

# IMPORTANT DENOMINATOR NOTE. stageA_candidates is NOT "every domain-tagged post" — 01_stageA builds it
# from `li <- matched[lk]`, i.e. ONLY rows where religion falls inside the +/-220 window. So this layer is
# the RELIGION-LINKED ECONOMIC population: the posts where the Church actually meets the economy. That is
# the denominator the paper's CST-rate claims must use; using all domain-matched posts would understate it.
linked_rid <- unique(as.integer(cand$rid))
cat(sprintf("  religion-linked economic rids: %s (unique; rows carry domain overlap)\n",
            digikat_format_integer(length(linked_rid))))

is_link <- rid_all %in% linked_rid

# ---- 3. chunked scan ----------------------------------------------------------------------------
hits <- matrix(FALSE, nrow = N, ncol = length(TERMS), dimnames = list(NULL, names(TERMS)))
starts <- seq(1L, N, by = CHUNK)
cat(sprintf("Scanning %d terms over %d chunks...\n", length(TERMS), length(starts)))
for (k in seq_along(starts)) {
  a <- starts[k]; b <- min(a + CHUNK - 1L, N)
  txt <- stri_trans_tolower(corpus$text[a:b])   # lowercase BEFORE matching (MEMORY.md, Croatian casing)
  hits[a:b, ] <- cst_detect(txt)
  if (k %% 4 == 0 || k == length(starts)) cat(sprintf("  %d/%d\n", k, length(starts)))
}
rm(corpus); invisible(gc())

# ---- 4. per-term table --------------------------------------------------------------------------
wil <- function(k, n) { ci <- wilson(k, n); sprintf("[%.4f, %.4f]", ci[1], ci[2]) }

NL <- sum(is_link)
per_term <- data.frame(
  term            = names(TERMS),
  tier            = unname(TIER[names(TERMS)]),
  n_corpus        = colSums(hits),
  pct_corpus      = round(100 * colSums(hits) / N, 4),
  n_linked_econ   = colSums(hits & is_link),
  pct_of_linked   = round(100 * colSums(hits & is_link) / NL, 4),
  # Share of a term's own mentions that fall in the religion-linked economic layer. High = the document is
  # economically indexed when it is invoked at all; low = it is cited mostly about something else.
  econ_embedding  = round(colSums(hits & is_link) / pmax(colSums(hits), 1L), 3),
  stringsAsFactors = FALSE, row.names = NULL
)
per_term <- per_term[order(per_term$tier, -per_term$n_corpus), ]

# ---- 5. tier aggregates -------------------------------------------------------------------------
tier_any <- function(cols) if (!length(cols)) rep(FALSE, N) else
  if (length(cols) == 1L) hits[, cols] else rowSums(hits[, cols, drop = FALSE]) > 0

# PERIODIZATION (defined in cst_lexicon.R — the paper's second headline; see that file for the rationale).
grp <- list(
  tier1_strict      = names(TERMS)[TIER %in% c("1_document", "1_marker")],
  tier1_documents   = names(CST_DOCS),
  tier1_markers     = names(CST_MARKERS),
  tier1b_genre      = names(CST_GENRE),
  tier2_ambiguous   = names(CST_AMBIG),
  doc_francis_era   = CST_FRANCIS,
  doc_classical_lab = CST_CLASSICAL,
  doc_conciliar     = CST_CONCILIAR
)
grp$tier1_or_genre <- c(grp$tier1_strict, grp$tier1b_genre)
grp$any_tier       <- names(TERMS)

agg <- do.call(rbind, lapply(names(grp), function(g) {
  h <- tier_any(grp[[g]])
  data.frame(group = g,
             n_corpus = sum(h), pct_corpus = round(100 * sum(h) / N, 4),
             ci95_corpus = wil(sum(h), N),
             n_linked_econ = sum(h & is_link),
             pct_of_linked = round(100 * sum(h & is_link) / max(NL, 1), 4),
             ci95_linked = wil(sum(h & is_link), NL),
             stringsAsFactors = FALSE)
}))

# ---- 6. write -----------------------------------------------------------------------------------
p1 <- sem_write_shareable(per_term, file.path(ME_OUT, "cst_census_terms.csv"))
p2 <- sem_write_shareable(agg,      file.path(ME_OUT, "cst_census_summary.csv"))

cat("\n================ CST CENSUS ================\n")
cat(sprintf("corpus n = %s | religion-linked economic n = %s\n\n",
            digikat_format_integer(N), digikat_format_integer(NL)))
print(agg, row.names = FALSE)
cat("\n---- Tier 1 terms with any hit ----\n")
t1 <- per_term[per_term$tier %in% c("1_document", "1_marker") & per_term$n_corpus > 0, ]
print(t1, row.names = FALSE)
cat("\n---- Tier 1 terms with ZERO hits ----\n")
z <- per_term$term[per_term$tier %in% c("1_document", "1_marker") & per_term$n_corpus == 0]
cat(if (length(z)) paste(" ", paste(z, collapse = ", "), "\n") else "  (none)\n")
cat("\nWrote:\n  ", p1, "\n  ", p2, "\n", sep = "")
