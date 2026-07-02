#!/usr/bin/env Rscript
# Study slice: catholic-education — Catholic lieux de mémoire, education-first
# Stage-A PRELIMINARY DETECTION probe: materialize the study slice + score the four
# site-of-memory signals (recurrence x temporal-peak x affect x past-anchoring).
#
# Reads the corpus READ-ONLY; writes ONLY into this study's output/ folder. NEVER writes data/.
# Does NOT touch the global >=2-match religion filter — it only sub-selects + scores.
#
# Run where R + the master live (see CLAUDE.local.md):
#   Rscript studies/catholic-education/slice.R            # full corpus if present, else the sample
# The sample path is the default fallback so this is safe on a clone without the master.
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })
set.seed(20260630)  # study start date YYYYMMDD

USE_SAMPLE <- !file.exists(here::here("data/merged_comprehensive.rds"))
src <- if (USE_SAMPLE) here::here("data/sample/merged_sample.rds") else here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("No corpus found (need the master or data/sample/). See CLAUDE.local.md.")

corpus <- readRDS(src)

# --- GUARD: refuse the synthetic disclosure sample (FULL_TEXT redacted -> all-zero probe) ------
# data/sample/merged_sample.rds has FULL_TEXT replaced by a redaction placeholder (R/make_sample.R),
# which contains NONE of the probe entities -> a plausible-looking but meaningless empty table.
# Stage-A detection needs REAL text: run where the master lives, or against a real stratified sample.
if (USE_SAMPLE && mean(grepl("REDACTED", corpus$FULL_TEXT, fixed = TRUE)) > 0.5)
  stop("Sample FULL_TEXT is redacted (synthetic placeholder) — the entity probe needs real text.\n",
       "  Run Stage A where the master lives (data/merged_comprehensive.rds), or against a REAL\n",
       "  stratified 2-5% sample — NOT the disclosure sample in data/sample/. (PROPOSAL §5/§11.)")

# --- 0. normalize text once (lowercase BEFORE matching — MEMORY.md lesson) -------------------
# stri_trans_tolower handles Croatian diacritics correctly; tolower() can mishandle locale.
txt <- stringr::str_to_lower(corpus$FULL_TEXT, locale = "hr")

# --- 1. the study-local ENTITY PROBE (NOT a global-filter change) -----------------------------
# Roots are intentionally loose for DETECTION; precision is fixed later by hand-validation (PROPOSAL §6).
# HOMONYM WARNING (audit before reporting any number): skola->autoskola, red->red voznje,
#   Petkovic = common surname (disambiguate Marija Petkovic), mladi is ubiquitous.
probe <- list(
  # --- spine: education / transmission ---
  vjeronauk        = "vjeronauk|vjerou[čc]itelj",
  # m8: allow ONE intervening word ("katoličke osnovne škole") + hyphen between katolič* and škol
  katolicka_skola  = "katoli[čc]k\\w*[\\s-]+(\\w+\\s+)?[šs]kol|katoli[čc]ko\\s+u[čc]ili[šs]t|katoli[čc]k\\w*\\s+sveu[čc]ili[šs]t|\\bhks\\b|sjemeni[šs]t|u[čc]iteljsk\\w*\\s+[šs]kol",
  odgoj_vrijednosti= "odgoj|kurikul|kr[šs][čc]ansk\\w*\\s+korijen|\\bvrijednost",
  # --- carriers: symbolic figures / orders ---
  stepinac         = "stepinac",
  strossmayer      = "strossmayer|strosmajer",
  stadler          = "\\bstadler\\b",  # HOMONYM: Stadler Rail (HŽ contracts) — disambiguate in hand-validation
  petkovic_marija  = "marij\\w*\\s+petkovi[ćc]|bla[žz]en\\w*\\s+marij\\w*\\s+petkovi[ćc]|petkovi[ćc]\\w*\\s+(redovnic|sestr|milosrdnic)",  # disambiguated
  redovi_orders    = "isusov|jezuit|franjev|dominikan|salezijan|[čc]asn\\w*\\s+sestr|samostan",  # top hand-validation priority (samostan/isusov/franjev leak)
  # --- past-anchoring tokens (signal #4, the falsifiable core of Q2) ---
  # HONEST SCOPE: this is a FOCUSED past-reference probe ALIGNED WITH (a subset of) the existing
  # POVIJEST_I_NACIONALNI_IDENTITET 16-cat category — NOT that category re-run. The full-category
  # version is computed downstream in /data-analysis from the shared dictionary; here we use this
  # transparent probe so Stage A is self-contained. (Avoids the "claims category-reuse but hand-rolls
  # a regex" contradiction flagged in review — both are reported and compared in /data-analysis.)
  # M3/M4/M5: cover inflections + ASCII fallbacks — recall matters most for the core signal.
  past_anchor      = "komunist|komuniz|sekular|jugoslavij|\\b1991\\b|domovinsk|[žz]rtv\\w*|\\brat\\w*|po?slijeratn|predratn|poratn",
  # --- secondary: rituals (NOT the spine; kept as a signal) ---
  rituali          = "hod za [žz]ivot|\\bshkm\\b|progledaj srcem|antunovsk\\w*\\s+hod|procesij|hodo[čc]a[šs]"
)

flags <- as.data.frame(lapply(probe, function(rx) stringr::str_detect(txt, rx)))
names(flags) <- paste0("probe_", names(probe))
corpus <- dplyr::bind_cols(corpus, flags)

# spine hit = any education-spine probe; past_anchor handled separately for the 4th signal
spine_cols <- c("probe_vjeronauk", "probe_katolicka_skola", "probe_odgoj_vrijednosti",
                "probe_stepinac", "probe_strossmayer", "probe_stadler",
                "probe_petkovic_marija", "probe_redovi_orders")
corpus$spine_hit   <- rowSums(corpus[spine_cols]) > 0
corpus$past_anchor <- corpus$probe_past_anchor

# --- 2. the slice = education-spine posts only -----------------------------------------------
# C1: parse DATE as a real Date (matching R/03_aggregate.R & R/04_nlp.R) and make the date-drop
# VISIBLE — string %Y comparison silently drops NA/unparseable dates and biases recurrence counts.
corpus$.date <- as.Date(corpus$DATE)
n_bad_date   <- sum(is.na(corpus$.date) & corpus$spine_hit)
if (n_bad_date > 0)
  cat("WARNING:", n_bad_date, "education-spine rows have NA/unparseable DATE — dropped from the window.\n")
slice <- dplyr::filter(corpus, spine_hit,
                       !is.na(.date),
                       .date >= as.Date("2021-01-01"),
                       .date <= as.Date("2025-12-31"))

# --- 3. four-signal candidate table (PROPOSAL §3) --------------------------------------------
# This script emits 2 of the 4 signals (recurrence + past-anchoring, doc-level AND windowed).
# Temporal-peaking and affective-charge are computed in /data-analysis (they need DATE-peakedness
# stats and the CroSentilex/lilaHR lemma join, which is NOT a function over FULL_TEXT). The Stage-A
# table is therefore a PARTIAL screen — see PROPOSAL §3/§5 for the full four-signal decision rule.
#
# WINDOWED past-anchoring (review fix): a raw "does a past token appear ANYWHERE in this post" share
# is whole-document co-occurrence — the sister study showed that is ~68% INCIDENTAL. So we also test
# whether a past token sits within +/- WINDOW chars of an education-spine hit (genuine linkage), and
# report BOTH so the incidental inflation is visible at the point of candidate selection.
WINDOW <- 160L
spine_keys <- sub("^probe_", "", spine_cols)            # the education-spine probe entities
spine_rx   <- paste0("(?:", paste(unlist(probe[spine_keys]), collapse = "|"), ")")
past_rx    <- probe$past_anchor
txt_slice  <- stringr::str_to_lower(slice$FULL_TEXT, locale = "hr")

near_past <- function(s) {                               # TRUE iff a past token is within WINDOW of a spine hit
  sp <- stringr::str_locate_all(s, spine_rx)[[1]]
  pa <- stringr::str_locate_all(s, past_rx)[[1]]
  if (nrow(sp) == 0L || nrow(pa) == 0L) return(FALSE)
  any(abs(outer(sp[, "start"], pa[, "start"], `-`)) <= WINDOW)
}
slice$past_anchor_doc    <- slice$past_anchor                       # document-level (likely inflated)
slice$past_anchor_genuine <- vapply(txt_slice, near_past, logical(1)) # windowed (genuine linkage)

entity_cols <- setdiff(names(flags), "probe_past_anchor")
candidates <- do.call(rbind, lapply(entity_cols, function(col) {
  hit <- slice[[col]]; n <- sum(hit)
  data.frame(
    entity                 = sub("^probe_", "", col),
    recurrence_n           = n,                          # NOTE: per-BUNDLE post count (some bundles group
                                                         # several roots, e.g. redovi_orders) — not a single
                                                         # lemma; refine in /data-analysis before ranking strongly.
    past_anchor_doc        = if (n > 0) round(mean(slice$past_anchor_doc[hit]), 3)     else NA_real_,
    past_anchor_genuine    = if (n > 0) round(mean(slice$past_anchor_genuine[hit]), 3) else NA_real_,
    incidental_share       = if (n > 0) round(mean(slice$past_anchor_doc[hit]) -
                                              mean(slice$past_anchor_genuine[hit]), 3) else NA_real_,
    stringsAsFactors       = FALSE)
}))
candidates <- candidates[order(-candidates$recurrence_n), ]

# --- 3b. construct-validity controls (PROPOSAL §3): the screen MUST separate a known lieu from a
#         known policy dispute, else the construct (not the data) is suspect. Print, don't gate. -----
ctrl <- function(e) candidates[candidates$entity == e, , drop = FALSE]
cat("\n-- construct-validity controls (genuine past-anchoring share) --\n")
cat("  positive control stepinac :", ctrl("stepinac")$past_anchor_genuine, "(expect HIGH)\n")
cat("  policy-dispute foil       :", ctrl("odgoj_vrijednosti")$past_anchor_genuine,
    "(expect LOW — odgoj/kurikul/vrijednost bundle)\n")
cat("  => if positive <= foil, the four-signal construct does NOT separate memory from policy talk;\n",
    "     revisit the construct (PROPOSAL §3) BEFORE any substantive Stage-B selection.\n")

# --- 4. write ONLY into output/ --------------------------------------------------------------
out_dir <- here::here("studies/catholic-education/output")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
slice$.date <- NULL  # drop the internal date helper before persisting
saveRDS(slice,           file.path(out_dir, "slice.rds"))
write.csv(candidates,    file.path(out_dir, "candidate_sites_of_memory.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("Education-spine slice:", nrow(slice), "rows ->", file.path(out_dir, "slice.rds"),
    if (USE_SAMPLE) "(FROM SAMPLE — not the full corpus)" else "(full corpus)", "\n")
cat("Candidate table (recurrence + doc/windowed past-anchor + incidental share) ->",
    file.path(out_dir, "candidate_sites_of_memory.csv"), "\n")
cat("NOTE: this is a PARTIAL screen — 2 of 4 signals. /data-analysis adds temporal-peaking",
    "(commemorative-vs-newscycle test) + affect (report lexicon coverage %); then HAND-VALIDATE",
    "(PROPOSAL §6) the genuine-linkage labels before reporting ANY number.\n")
