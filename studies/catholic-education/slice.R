#!/usr/bin/env Rscript
# Study slice: catholic-education — Catholic lieux de mémoire, education-first
# Stage-A PRELIMINARY DETECTION probe: materialize the education-spine slice + score the
# site-of-memory signals it can (recurrence + doc/windowed past-anchoring). Peaking + affect
# are added in /data-analysis (they need DATE-peakedness stats + the CroSentilex/lilaHR join).
#
# Reads the corpus READ-ONLY; writes ONLY into this study's output/. NEVER writes data/.
# Does NOT touch the global >=2-match religion filter — it only sub-selects + scores.
#
# DESIGN NOTE (as-built): Stage A runs on the FULL corpus, not a 2–5% sample. Detection is
# recall-first and full-corpus scoring is what lets a RARE-but-real lieu survive (PROPOSAL §5
# rare-lieu rescue). The master read is EXPENSIVE (~8 min: 1.2 GB compressed RDS), so the
# filtered slice is CHECKPOINTED to output/_slice_raw.rds with a fingerprint of the probe;
# re-runs resume in seconds, and a probe edit auto-invalidates the checkpoint (no silent stale).
#
# Run where R + the master live (see CLAUDE.local.md):
#   Rscript studies/catholic-education/slice.R
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })

# PINNED to the accumulator (data/merged_comprehensive.rds), NOT the official corpus
# data/digikat_corpus.rds. This analysis is complete and its published numbers were computed
# from the accumulator; repointing it would silently change results a paper already reports.
# See quality_reports/plans/2026-08-10_official-corpus-v1.md §4.
USE_SAMPLE <- !file.exists(here::here("data/merged_comprehensive.rds"))
src <- if (USE_SAMPLE) here::here("data/sample/merged_sample.rds") else here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("No corpus found (need the master or data/sample/). See CLAUDE.local.md.")

# --- 1. the study-local ENTITY PROBE (constants; NOT a global-filter change) -------------------
# Roots are intentionally loose for DETECTION; precision is fixed later by hand-validation (PROPOSAL §6).
# HOMONYM WARNINGS (audit before reporting any number): skola->autoskola, red->red voznje,
#   Petkovic = surname (disambiguated below), mladi ubiquitous, rat->ratar/ratarstvo (farming).
probe <- list(
  # --- spine: education / transmission ---
  vjeronauk        = "vjeronauk|vjerou[čc]itelj",
  # m8: allow ONE intervening word ("katoličke osnovne škole") + hyphen between katolič* and škol
  katolicka_skola  = "katoli[čc]k\\w*[\\s-]+(\\w+\\s+)?[šs]kol|katoli[čc]ko\\s+u[čc]ili[šs]t|katoli[čc]k\\w*\\s+sveu[čc]ili[šs]t|\\bhks\\b|sjemeni[šs]t|u[čc]iteljsk\\w*\\s+[šs]kol",
  odgoj_vrijednosti= "odgoj|kurikul|kr[šs][čc]ansk\\w*\\s+korijen|\\bvrijednost",
  # --- carriers: symbolic figures / orders ---
  stepinac         = "stepinac",
  strossmayer      = "strossmayer|strosmajer",
  stadler          = "\\bstadler\\b",  # in THIS religion-filtered corpus mostly Abp. J. Stadler, not Stadler Rail
  petkovic_marija  = "marij\\w*\\s+petkovi[ćc]|bla[žz]en\\w*\\s+marij\\w*\\s+petkovi[ćc]|petkovi[ćc]\\w*\\s+(redovnic|sestr|milosrdnic)",  # disambiguated
  # isusov FIX (Stage-A finding 2026-07-06): bare "isusov" matched ~63k "Isusov dar"/"Isusova braća"
  # = OF-JESUS, NOT Jesuits — inflated this bundle ~2x. Restrict to ORDER forms + "Družba Isusova".
  redovi_orders    = "isusova[cč]\\w*|isusovc\\w*|dru[žz]b\\w*\\s+isusov|jezuit|franjev|dominikan|salezijan|[čc]asn\\w*\\s+sestr|samostan",  # samostan/franjev still hand-validation priorities
  # --- past-anchoring tokens (signal #4, the falsifiable core of Q2) ---
  # HONEST SCOPE: a FOCUSED past-reference probe ALIGNED WITH (a subset of) POVIJEST_I_NACIONALNI_IDENTITET,
  # NOT that 16-cat category re-run (that version is compared in /data-analysis). NB: this token set is
  # tuned to the 20c communist/1991 rupture, so it UNDER-detects 19c memory (e.g. Strossmayer) — a limit.
  past_anchor      = "komunist|komuniz|sekular|jugoslavij|\\b1991\\b|domovinsk|[žz]rtv\\w*|\\brat\\w*|(po)?slijeratn|predratn|poratn",
  # --- secondary: rituals (NOT the spine; reported as a signal, flagged 'secondary' in the table) ---
  rituali          = "hod za [žz]ivot|\\bshkm\\b|progledaj srcem|antunovsk\\w*\\s+hod|procesij|hodo[čc]a[šs]"
)
spine_keys <- c("vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "stepinac",
                "strossmayer", "stadler", "petkovic_marija", "redovi_orders")
spine_cols <- paste0("probe_", spine_keys)
past_rx    <- probe$past_anchor

# --- 2. build (or resume) the education-spine slice; checkpoint is probe-fingerprinted ---------
raw_path <- here::here("studies/catholic-education/output/_slice_raw.rds")
if (file.exists(raw_path)) {
  cached <- readRDS(raw_path)
  if (!identical(attr(cached, "probe"), probe)) {
    cat("Cached _slice_raw.rds was built with a DIFFERENT probe — ignoring it and re-reading the master.\n")
    slice <- NULL
  } else {
    cat("Resuming from cached raw slice (probe matches):", raw_path, "\n")
    slice <- cached
  }
} else slice <- NULL

if (is.null(slice)) {
  corpus <- readRDS(src)
  # master is a data.table; convert in place (setDF) — as.data.frame() would deep-copy ~all columns
  # and briefly double peak RAM on the ~1.2 GB master (r-reviewer Major #3).
  if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)
  miss <- setdiff(c("FULL_TEXT", "DATE"), names(corpus))
  if (length(miss)) stop("Master is missing required columns: ", paste(miss, collapse = ", "))

  if (USE_SAMPLE && mean(grepl("REDACTED", corpus$FULL_TEXT, fixed = TRUE)) > 0.5)
    stop("Sample FULL_TEXT is redacted (synthetic placeholder) — the entity probe needs real text.\n",
         "  Run where the master lives, or against a REAL stratified sample (NOT data/sample/).")

  # lowercase BEFORE matching (MEMORY.md); str_to_lower(locale='hr') is Croatian-diacritic-correct.
  txt   <- stringr::str_to_lower(corpus$FULL_TEXT, locale = "hr")
  flags <- as.data.frame(lapply(probe[c(spine_keys, "rituali")],
                                function(rx) stringr::str_detect(txt, rx)))
  names(flags) <- paste0("probe_", c(spine_keys, "rituali"))
  corpus <- dplyr::bind_cols(corpus, flags)
  corpus$spine_hit   <- rowSums(corpus[spine_cols], na.rm = TRUE) > 0   # NA text -> FALSE, not NA-dropped
  corpus$past_anchor <- stringr::str_detect(txt, past_rx) %in% TRUE     # whole-doc past token; NA -> FALSE

  # C1: DATE is a CHARACTER ISO "YYYY-MM-DD" in the master (03_aggregate.R). Parse + make BOTH drops
  # visible: NA/unparseable AND out-of-[2021,2025]-window (r-reviewer Major #4) — silent drops bias counts.
  corpus$date_parsed <- as.Date(corpus$DATE)
  n_bad_date <- sum(is.na(corpus$date_parsed) & corpus$spine_hit)
  n_out_win  <- sum(corpus$spine_hit & !is.na(corpus$date_parsed) &
                    (corpus$date_parsed < as.Date("2021-01-01") | corpus$date_parsed > as.Date("2025-12-31")))
  if (n_bad_date > 0) cat("NOTE:", n_bad_date, "education-spine rows have NA/unparseable DATE — dropped.\n")
  if (n_out_win  > 0) cat("NOTE:", n_out_win,  "education-spine rows fall OUTSIDE 2021–2025 — dropped (scope).\n")
  slice <- dplyr::filter(corpus, spine_hit, !is.na(date_parsed),
                         date_parsed >= as.Date("2021-01-01"), date_parsed <= as.Date("2025-12-31"))
  slice$date_parsed <- NULL
  rm(corpus, txt, flags); invisible(gc())

  attr(slice, "probe") <- probe   # fingerprint: a probe edit invalidates this checkpoint on next run
  if (!dir.exists(dirname(raw_path))) dir.create(dirname(raw_path), recursive = TRUE)
  saveRDS(slice, raw_path)
  cat("Cached raw education-spine slice (", nrow(slice), "rows) ->", raw_path, "\n")
}

# --- 3. candidate table with PER-ENTITY windowed past-anchoring (PROPOSAL §3) -----------------
# WINDOWED past-anchoring (review fix): whole-document co-occurrence is ~68% INCIDENTAL (sister study),
# so genuine linkage = a past token within +/- WINDOW chars of an entity's OWN match. Critical: this is
# computed PER ENTITY (r-reviewer Critical #1) — using the OR of all spine bundles would credit an entity
# for a co-occurring bundle's proximity and confound the construct-validity gate.
txt_slice <- stringr::str_to_lower(slice$FULL_TEXT, locale = "hr")
past_doc  <- if ("past_anchor" %in% names(slice)) slice$past_anchor else stringr::str_detect(txt_slice, past_rx)
WINDOW    <- 160L
near_past_ent <- function(s, ent_rx) {          # past token within WINDOW of THIS entity's match
  sp <- stringr::str_locate_all(s, ent_rx)[[1]]
  pa <- stringr::str_locate_all(s, past_rx)[[1]]
  if (nrow(sp) == 0L || nrow(pa) == 0L) return(FALSE)
  any(abs(outer(sp[, "start"], pa[, "start"], `-`)) <= WINDOW)
}
entity_genuine <- function(ecol) {              # per-row genuine flag for one entity (only where it can be TRUE)
  g  <- logical(nrow(slice))
  gi <- which(slice[[ecol]] %in% TRUE & past_doc)
  if (length(gi)) g[gi] <- vapply(txt_slice[gi], near_past_ent, logical(1), ent_rx = probe[[sub("^probe_", "", ecol)]])
  g
}
roles <- c(setNames(rep("spine", length(spine_keys)), spine_keys), rituali = "secondary")
candidates <- do.call(rbind, lapply(c(spine_keys, "rituali"), function(e) {
  col <- paste0("probe_", e); hit <- slice[[col]] %in% TRUE; n <- sum(hit)
  if (n == 0) return(data.frame(entity = e, role = roles[[e]], recurrence_n = 0L,
                                past_anchor_doc = NA_real_, past_anchor_genuine = NA_real_, incidental_share = NA_real_))
  gen <- entity_genuine(col)
  data.frame(entity = e, role = roles[[e]], recurrence_n = n,
             past_anchor_doc     = round(mean(past_doc[hit]), 3),   # NOTE: per-BUNDLE count (some bundles
             past_anchor_genuine = round(mean(gen[hit]), 3),         # group several roots) — de-bundle in
             incidental_share    = round(mean(past_doc[hit]) - mean(gen[hit]), 3),  # stageA_checks.R.
             stringsAsFactors = FALSE)
}))
candidates <- candidates[order(-candidates$recurrence_n), ]

# --- 3b. construct-validity controls (PROPOSAL §3), now entity-true ---------------------------
gv <- function(e) candidates$past_anchor_genuine[candidates$entity == e]
cat("\n-- construct-validity controls (ENTITY-SPECIFIC genuine past-anchoring share) --\n")
cat("  positive control stepinac :", gv("stepinac"), "(expect HIGH)\n")
cat("  policy-dispute foil       :", gv("odgoj_vrijednosti"), "(expect LOW)\n")
cat("  => if positive <= foil, the four-signal construct does NOT separate memory from policy talk;\n",
    "     revisit the construct (PROPOSAL §3) BEFORE any substantive Stage-B selection.\n")

# --- 4. write ONLY into output/ --------------------------------------------------------------
out_dir <- here::here("studies/catholic-education/output")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
slice$past_anchor_doc <- past_doc
saveRDS(slice,        file.path(out_dir, "slice.rds"))
write.csv(candidates, file.path(out_dir, "candidate_sites_of_memory.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\nEducation-spine slice:", nrow(slice), "rows ->", file.path(out_dir, "slice.rds"),
    if (USE_SAMPLE) "(FROM SAMPLE)" else "(full corpus)", "\n")
cat("Candidate table (per-entity recurrence + doc/windowed past-anchor + incidental) ->",
    file.path(out_dir, "candidate_sites_of_memory.csv"), "\n")
cat("NOTE: PARTIAL screen — 2 of 4 signals. /data-analysis adds temporal-peaking (commemorative-vs-",
    "newscycle) + affect (report lexicon coverage %); HAND-VALIDATE (PROPOSAL §6) before reporting numbers.\n")
