#!/usr/bin/env Rscript
# Study slice: catholic-education — Catholic lieux de mémoire, education-first
# Stage-A PRELIMINARY DETECTION probe: materialize the education-spine slice + score the
# site-of-memory signals it can (recurrence + doc/windowed past-anchoring). Peaking + affect
# are added in /data-analysis (they need DATE-peakedness stats + the CroSentilex/lilaHR join).
#
# Reads the corpus READ-ONLY; writes ONLY into this study's output/. NEVER writes data/.
# Does NOT touch the global >=2-match religion filter — it only sub-selects + scores.
#
# DESIGN NOTE (as-built): Stage A runs on the FULL official corpus, not a 2–5% sample. Detection is
# recall-first and full-corpus scoring is what lets a RARE-but-real lieu survive (PROPOSAL §5
# rare-lieu rescue). The filtered slice is CHECKPOINTED to output/_slice_raw.rds with fingerprints
# of both the probe and the official database; a probe or database change invalidates it.
#
# Run where R + the official corpus live (see CLAUDE.local.md):
#   Rscript studies/catholic-education/slice.R
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")

contract <- catholic_education_input_contract(verify_hash = TRUE)
input_fingerprint <- contract$fingerprint
CACHE_SCHEMA_VERSION <- 2L
cat(
  "Official input:", contract$path, "\n",
  "  ", input_fingerprint$rows, "rows x", input_fingerprint$columns, "columns\n",
  "  SHA-256", input_fingerprint$sha256, "\n"
)

# --- 1. the study-local ENTITY PROBE (constants; NOT a global-filter change) -------------------
# Roots are intentionally loose for DETECTION; precision is fixed later by hand-validation (PROPOSAL §6).
# HOMONYM WARNINGS (audit before reporting any number): skola->autoskola, red->red voznje,
#   Petkovic = surname (disambiguated below), mladi ubiquitous. The war token is restricted below
#   so it does not match ratar/ratarstvo or other non-war rat* words.
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
  past_anchor      = "komunist|komuniz|sekular|jugoslavij|\\b1991\\b|domovinsk|[žz]rtv\\w*|\\brat(?:\\b|a\\b|u\\b|om\\b|ov\\w*|n\\w*)|(po)?slijeratn|predratn|poratn",
  # --- secondary: rituals (NOT the spine; reported as a signal, flagged 'secondary' in the table) ---
  rituali          = "hod za [žz]ivot|\\bshkm\\b|progledaj srcem|antunovsk\\w*\\s+hod|procesij|hodo[čc]a[šs]"
)
spine_keys <- c("vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "stepinac",
                "strossmayer", "stadler", "petkovic_marija", "redovi_orders")
spine_cols <- paste0("probe_", spine_keys)
past_rx    <- probe$past_anchor
cache_fingerprint <- list(
  schema_version = CACHE_SCHEMA_VERSION,
  input = input_fingerprint,
  probe_sha256 = digikat_hash_object(probe)
)

out_dir <- here::here("studies/catholic-education/output")
tab_dir <- file.path(out_dir, "tables")
for (d in c(out_dir, tab_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)

# --- 2. build (or resume) the education-spine slice; checkpoint is probe-fingerprinted ---------
raw_path <- here::here("studies/catholic-education/output/_slice_raw.rds")
cache_reused <- FALSE
if (file.exists(raw_path)) {
  cached <- readRDS(raw_path)
  if (!identical(attr(cached, "cache_fingerprint"), cache_fingerprint)) {
    cat("Cached _slice_raw.rds has a DIFFERENT probe/database fingerprint — rebuilding it.\n")
    slice <- NULL
  } else {
    cat("Resuming from cached raw slice (probe and official database match):", raw_path, "\n")
    slice <- cached
    cache_reused <- TRUE
  }
} else slice <- NULL

if (is.null(slice)) {
  corpus <- catholic_education_read_corpus(contract)

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
  corpus$date_parsed <- digikat_parse_date(corpus$DATE, name = "DATE", allow_missing = FALSE)
  n_bad_date <- sum(is.na(corpus$date_parsed) & corpus$spine_hit)
  n_out_win  <- sum(corpus$spine_hit & !is.na(corpus$date_parsed) &
                    (corpus$date_parsed < as.Date("2021-01-01") | corpus$date_parsed > as.Date("2025-12-31")))
  if (n_bad_date > 0) cat("NOTE:", n_bad_date, "education-spine rows have NA/unparseable DATE — dropped.\n")
  if (n_out_win  > 0) cat("NOTE:", n_out_win,  "education-spine rows fall OUTSIDE 2021–2025 — dropped (scope).\n")
  corpus_window <- dplyr::filter(
    corpus,
    date_parsed >= as.Date(input_fingerprint$analysis_start),
    date_parsed <= as.Date(input_fingerprint$analysis_end)
  ) |>
    mutate(ym = format(date_parsed, "%Y-%m"))
  month_counts <- corpus_window |>
    count(ym, name = "corpus_posts")
  month_stream_counts <- corpus_window |>
    count(data_source, ym, name = "corpus_posts")
  full_months <- data.frame(
    ym = format(
      seq(as.Date(input_fingerprint$analysis_start), as.Date("2025-12-01"), by = "month"),
      "%Y-%m"
    ),
    stringsAsFactors = FALSE
  )
  coverage <- full_months |>
    left_join(month_counts, by = "ym") |>
    mutate(
      corpus_posts = coalesce(corpus_posts, 0L),
      observed = corpus_posts > 0L
    )

  slice <- dplyr::filter(corpus, spine_hit, !is.na(date_parsed),
                         date_parsed >= as.Date(input_fingerprint$analysis_start),
                         date_parsed <= as.Date(input_fingerprint$analysis_end))
  slice$date_parsed <- NULL
  rm(corpus, corpus_window, txt, flags); invisible(gc())

  attr(slice, "probe") <- probe
  attr(slice, "cache_fingerprint") <- cache_fingerprint
  attr(slice, "corpus_month_coverage") <- coverage
  attr(slice, "corpus_month_stream_counts") <- month_stream_counts
  saveRDS(slice, raw_path)
  cat("Cached raw education-spine slice (", nrow(slice), "rows) ->", raw_path, "\n")
}

coverage <- attr(slice, "corpus_month_coverage")
month_stream_counts <- attr(slice, "corpus_month_stream_counts")
if (is.null(coverage) || is.null(month_stream_counts)) {
  stop("Raw slice lacks corpus coverage metadata; remove the checkpoint and rebuild.", call. = FALSE)
}
write.csv(
  coverage,
  file.path(tab_dir, "corpus_month_coverage.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

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

# Slice-wide local linkage uses the nearest match to ANY primary anchor. Entity-specific candidate
# shares above remain stricter and cannot borrow a neighbouring anchor's past reference.
spine_rx <- paste0("(?:", paste(unlist(probe[spine_keys]), collapse = "|"), ")")
combined_genuine <- logical(nrow(slice))
combined_idx <- which(past_doc)
if (length(combined_idx)) {
  combined_genuine[combined_idx] <- vapply(
    txt_slice[combined_idx], near_past_ent, logical(1), ent_rx = spine_rx
  )
}

# --- 3b. construct-validity controls (PROPOSAL §3), now entity-true ---------------------------
gv <- function(e) candidates$past_anchor_genuine[candidates$entity == e]
cat("\n-- construct-validity controls (ENTITY-SPECIFIC genuine past-anchoring share) --\n")
cat("  positive control stepinac :", gv("stepinac"), "(expect HIGH)\n")
cat("  policy-dispute foil       :", gv("odgoj_vrijednosti"), "(expect LOW)\n")
cat("  => if positive <= foil, the four-signal construct does NOT separate memory from policy talk;\n",
    "     revisit the construct (PROPOSAL §3) BEFORE any substantive Stage-B selection.\n")

# --- 4. write ONLY into output/ --------------------------------------------------------------
slice$past_anchor_doc <- past_doc
slice$past_anchor_genuine <- combined_genuine
saveRDS(slice,        file.path(out_dir, "slice.rds"))
write.csv(candidates, file.path(out_dir, "candidate_sites_of_memory.csv"), row.names = FALSE, fileEncoding = "UTF-8")

run_manifest <- list(
  schema_version = 1,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/catholic-education/slice.R",
  input = c(
    input_fingerprint,
    list(
      path = gsub("\\\\", "/", contract$manifest$corpus$path),
      manifest_path = "data/digikat_corpus_manifest.json",
      inclusion_rule = contract$manifest$rule$description
    )
  ),
  scope = list(
    rows_in_input = input_fingerprint$rows,
    rows_in_2021_2025 = sum(coverage$corpus_posts),
    observed_months = sum(coverage$observed),
    unobserved_months = coverage$ym[!coverage$observed],
    education_strand_rows = nrow(slice),
    cache_reused = cache_reused,
    proximity_window_characters = WINDOW
  ),
  probe = list(
    sha256 = cache_fingerprint$probe_sha256,
    primary_anchors = spine_keys,
    secondary_anchor = "rituali"
  ),
  caveats = contract$manifest$caveats,
  outputs = list(
    candidate_table = list(
      path = "studies/catholic-education/output/candidate_sites_of_memory.csv",
      sha256 = digikat_hash_file(file.path(out_dir, "candidate_sites_of_memory.csv"))
    ),
    restricted_slice = list(
      path = "studies/catholic-education/output/slice.rds",
      rows = nrow(slice),
      columns = ncol(slice)
    )
  )
)
digikat_write_json_atomic(run_manifest, file.path(out_dir, "analysis_input_manifest.json"))

cat("\nEducation-spine slice:", nrow(slice), "rows ->", file.path(out_dir, "slice.rds"),
    "(official corpus)", "\n")
cat("Candidate table (per-entity recurrence + doc/windowed past-anchor + incidental) ->",
    file.path(out_dir, "candidate_sites_of_memory.csv"), "\n")
cat("NOTE: PARTIAL screen — 2 of 4 signals. /data-analysis adds temporal-peaking (commemorative-vs-",
    "newscycle) + affect (report lexicon coverage %); HAND-VALIDATE (PROPOSAL §6) before reporting numbers.\n")
