# _lib.R — shared definitions for the inflation-salience study pipeline
#
# Reconstruction note (2026-08-05). The original scratchpad scripts named in PAPER_v1
# Appendix A (10_rerun_fixed.R ... 17_h1_hicp.R) exist nowhere in the repo or in git
# history. This file and scripts 01-03 rebuild that pipeline from the specification in
# PAPER_v1.md section 3 and VALIDATION.md section v3. The lexicons below were recovered by
# fitting against three surviving fixtures: the 1,450-row candidate pool
# (output/private/coding_pool_index.csv), the 39-month attention series
# (output/h1_attention_hicp_series.csv), and the published funnel counts. Residual
# disagreement with the June 2026 run is reported by each script and recorded in
# RECONSTRUCTION.md. Do not silently retune these patterns to close a gap: rerun the
# fixture reports and document what moved.

suppressWarnings(suppressMessages({
  library(data.table)
  library(stringi)
}))

STUDY   <- "studies/inflation-salience"
OUT     <- file.path(STUDY, "output")
PRIVATE <- file.path(OUT, "private")
TABLES  <- file.path(OUT, "tables")

for (d in c(OUT, PRIVATE, TABLES)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

stopifnot(dir.exists("data"), file.exists("R/religious_terms.R"))

MASTER <- "data/merged_comprehensive.rds"

## ---------------------------------------------------------------- text -----

# One normalization for every stage, so character offsets are comparable across scripts.
dk_text <- function(title, body) {
  t <- ifelse(is.na(title), "", as.character(title))
  b <- ifelse(is.na(body),  "", as.character(body))
  s <- paste0(t, " ", b)
  s <- stri_replace_all_regex(s, "[\\p{Zs}\\t\\r\\n]+", " ")
  stri_trans_tolower(stri_trim_both(s))
}

## ------------------------------------------------------- inflation lexicon -----

# Anchored cost-of-living vocabulary. The bare word `cijena` ("price") is deliberately
# absent: on its own it fires on devotional text ("the price of salvation").
INFL_CORE <- "(in|de|hiperin)flacij[a-zšđčćž]*"

INFL_OTHER <- c(
  poskup       = "poskup",
  rast_cijena  = "(rast|porast|skok)\\s+cijen",
  cijene_rastu = "cijen[a-zšđčćž]*\\s+(rast|raste|rastu|porasl|sko[cč])",
  trosak_zivot = "tro[sš]a?k[a-zšđčćž]*\\s+[zž]ivota|[zž]ivot[a-zšđčćž]*\\s+tro[sš]k",
  kupovna_moc  = "kupovn[a-zšđčćž]*\\s+mo[cć]"
)

# Metaphor guard (VALIDATION.md fix 1): "inflacija riječi / vrednota / superlativa".
# It voids the individual match, not the post — a post that also talks about real prices
# stays in.
INFL_METAPHOR_NOUNS <- paste(
  "rije[cč]", "vrednot", "pojm", "superlativ", "mu[cč]enik", "osje[cć]aj", "nad[ae]\\b",
  "titul", "nagrad", "zvanj", "diplom", "informacij", "sadr[zž]aj", "emocij", "smisl",
  "zna[cč]enj", "ideolog", "obe[cć]anj", "pridjev", "epitet", "floskul", "patriotizm",
  "moral", "pohlep", "[cč]ovjek", "dobrote", "ljubav", "straha?\\b", "mr[zž]nj", "gluposti",
  sep = "|"
)
INFL_METAPHOR <- paste0(INFL_CORE, "\\s+(", INFL_METAPHOR_NOUNS, ")")

# Returns a logical vector: does this text carry a literal cost-of-living mention?
tag_inflation <- function(txt) {
  n_all  <- stri_count_regex(txt, INFL_CORE)
  n_meta <- stri_count_regex(txt, INFL_METAPHOR)
  literal <- n_all > n_meta
  for (p in INFL_OTHER) literal <- literal | stri_detect_regex(txt, p)
  literal
}

# Raw (pre-guard) tag, for reporting how much the metaphor guard removes.
tag_inflation_raw <- function(txt) {
  hit <- stri_detect_regex(txt, INFL_CORE)
  for (p in INFL_OTHER) hit <- hit | stri_detect_regex(txt, p)
  hit
}

INFL_ANY <- paste0("(", paste(c(INFL_CORE, unname(INFL_OTHER)), collapse = ")|("), ")")

## ------------------------------------------------------ religious lexicon -----

# The project's 95-term lexicon, word-anchored and tightened for the homonyms the
# validation pass documented.
religious_regex <- function() {
  e <- new.env(parent = globalenv())
  sys.source("R/religious_terms.R", envir = e)
  rt <- get("religious_terms", envir = e)
  paste0("\\b(", paste(rt$regex, collapse = "|"), ")")
}

# Strings that make a religious-term match spurious. Blanked before matching so their
# character positions do not shift (offsets stay comparable with the raw text).
RELIG_HOMONYMS <- c(
  "crveni\\s+kri[zž][a-zšđčćž]*",        # Crveni križ = Red Cross, a secular charity
  "kri[zž]evc[a-zšđčćž]*",               # Križevci, a town
  "gospodarstv[a-zšđčćž]*",              # gospodarstvo = the economy, not Gospa
  "gospodarsk[a-zšđčćž]*",
  "gospodarstvenic?[a-zšđčćž]*",
  "papir[a-zšđčćž]*",                    # papir = paper, not papa
  "papa[- ]?test[a-zšđčćž]*",            # Papa-test = Pap smear
  "trapist[a-zšđčćž]*\\s+(sir|gaud|pivo)",  # trapist cheese/beer, not the order
  "(sir|gaud|pivo)[a-zšđčćž]*\\s+trapist[a-zšđčćž]*",
  "misa[oj][a-zšđčćž]*",                 # misao = thought, not misa
  "posve[cć]en[a-zšđčćž]*\\s+(ulaganj|pitanj|temi|problemu|analiz)",  # "dedicated to"
  "predsjedni[kč][a-zšđčćž]*"            # guards the bare `red` root
)

mask_homonyms <- function(txt) {
  for (p in RELIG_HOMONYMS) {
    loc <- stri_locate_all_regex(txt, p, omit_no_match = TRUE)
    for (i in which(vapply(loc, nrow, integer(1)) > 0L)) {
      li <- loc[[i]]
      for (k in seq_len(nrow(li))) {
        stri_sub(txt[i], li[k, 1], li[k, 2]) <- strrep(" ", li[k, 2] - li[k, 1] + 1L)
      }
    }
  }
  txt
}

## --------------------------------------------------------------- linkage -----

LINK_WINDOW <- 220L   # characters, either side (VALIDATION.md fix 4)

# For one text: the smallest character gap between an inflation match and a religious
# match. Inf when either side is absent.
min_gap <- function(txt, infl_pat, relig_pat) {
  a <- stri_locate_all_regex(txt, infl_pat, omit_no_match = TRUE)
  b <- stri_locate_all_regex(txt, relig_pat, omit_no_match = TRUE)
  vapply(seq_along(a), function(i) {
    ai <- a[[i]]; bi <- b[[i]]
    if (!nrow(ai) || !nrow(bi)) return(Inf)
    ac <- (ai[, 1] + ai[, 2]) / 2
    bc <- (bi[, 1] + bi[, 2]) / 2
    min(abs(outer(ac, bc, "-")))
  }, numeric(1))
}

## ----------------------------------------------------------------- misc -----

# Streams. The monitoring query effectively stops in mid-2024; the filter-based backfill
# takes over. They are never pooled in a temporal series.
STREAM_LABEL <- c(original_dta = "monitoring", filtered_religious = "backfill")

REGISTERS <- c("crl", "institution", "charity", "devotional", "justice", "other", "disputed")

REGISTER_LABEL <- c(
  crl         = "Cost of religious life",
  institution = "Church-as-institution",
  charity     = "Charity / relief",
  devotional  = "Devotional",
  justice     = "Structural / justice",
  other       = "Other",
  disputed    = "Disputed"
)

# Sector response mapping (EMIP_EXECUTION.md 2.1).
RESPONSE_OF_REGISTER <- c(
  institution = "Public voice",
  crl         = "Repricing",
  charity     = "Charitable response",
  justice     = "Normative response",
  devotional  = NA_character_,
  other       = NA_character_,
  disputed    = NA_character_
)

fixture_report <- function(label, observed, expected, tol = 0L) {
  d <- observed - expected
  status <- if (abs(d) <= tol) "MATCH" else "MISMATCH"
  cat(sprintf("  [%-8s] %-38s observed %7s | June 2026 run %7s | delta %+d\n",
              status, label, format(observed, big.mark = " "),
              format(expected, big.mark = " "), d))
  invisible(status == "MATCH")
}

msg <- function(...) cat(..., "\n", sep = "")
rule <- function(s = "") cat("\n", strrep("-", 78), "\n", s, "\n", sep = "")
