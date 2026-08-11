#!/usr/bin/env Rscript
# moral-economy STAGE A — full-census tagging + validated windowed linkage.
# Reads the master READ-ONLY; writes ONLY to studies/moral-economy/output/. Never touches data/.
#
# For every post: tag the 11 economy domains (register-neutral lexicon), then for each matched
# domain compute whether a TIGHTENED religion term falls within +/-220 chars of a domain match
# (genuine-linkage CANDIDATE — precision fixed later by coding, ~0.4 ceiling). Uses the FROZEN
# 95-term religion lexicon with the 5 economic-homonym tightenings (lexicon.R). Captures a window
# excerpt (original-case) for every LINKED candidate (the Stage-B coding pool) and for a capped
# random sample of matched posts per domain (the Gate-1 precision hand-scan) — so 02/03 NEVER
# re-read the ~1.2 GB master.
#
# >>> Run with Dropbox sync PAUSED (CLAUDE.local.md: cold master read + Dropbox => os error 32). <<<
#   Rscript studies/moral-economy/01_stageA_tag_linkage.R
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })
source(here::here("studies/moral-economy/lexicon.R"))

# PINNED to the accumulator (data/merged_comprehensive.rds), NOT the official corpus
# data/digikat_corpus.rds. This analysis is complete and its published numbers were computed
# from the accumulator; repointing it would silently change results a paper already reports.
# See quality_reports/plans/2026-08-10_official-corpus-v1.md §4.
src <- here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("Stage A needs the master. See CLAUDE.local.md.")
out_dir <- here::here("studies/moral-economy/output")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
CAND_PATH <- file.path(out_dir, "stageA_candidates.rds")

relig <- me_build_religion_regex()
cat(sprintf("Religion lexicon: %d terms, %d homonym tightenings applied.\n", relig$n_terms, length(relig$tightened)))

# ------------------------------------------------------------------------------------------------
# resumable checkpoint: fingerprint EVERY input that shapes the output (domain + religion regexes,
# the metaphor/foreign probes, window, master identity, the outlet-label file's mtime, AND the frozen
# religion lexicon's content hash) so a stale cache can NEVER masquerade as fresh (r-review MAJOR 3).
lab_path <- here::here("resources/dictionaries/source_labels.csv")
fp <- list(econ = ME_ECON, relig = relig$with_caritas, infl_rx = ME_INFLATION_METAPHOR,
           foreign_rx = ME_FOREIGN_HINT, window = ME_WINDOW,
           mtime = as.character(file.info(src)$mtime), size = file.info(src)$size,
           relterms_md5 = unname(tools::md5sum(here::here("R/religious_terms.R"))),
           label_mtime = if (file.exists(lab_path)) as.character(file.info(lab_path)$mtime) else NA)
if (file.exists(CAND_PATH)) {
  ck <- readRDS(CAND_PATH)
  if (identical(attr(ck, "fingerprint"), fp)) { cat("Stage A already complete for this input; nothing to do.\n"); quit(save = "no") }
  cat("Existing candidates built from a DIFFERENT lexicon/master — recomputing.\n")
}

cat("Reading master (pause Dropbox!):", src, "\n"); t0 <- Sys.time()
corpus <- readRDS(src)
if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)
need <- c("FULL_TEXT", "DATE"); miss <- setdiff(need, names(corpus))
if (length(miss)) stop("Master missing columns: ", paste(miss, collapse = ", "))
N <- nrow(corpus)
cat(sprintf("  %s rows in %.1f min\n", format(N, big.mark = ","), as.numeric(difftime(Sys.time(), t0, "mins"))))

# optional metadata columns (present in this master; guard if absent)
getcol <- function(nm) if (nm %in% names(corpus)) corpus[[nm]] else rep(NA_character_, N)
FROM <- getcol("FROM"); SOURCE_TYPE <- getcol("SOURCE_TYPE"); STREAM <- getcol("data_source")
TITLE <- getcol("TITLE"); URL <- getcol("URL")
# MATCH ON ORIGINAL TEXT with ignore_case (r-review MAJOR 2): a separate lowered copy can drift in
# length from orig_text (İ U+0130 lowercases to 2 chars even under locale='hr'), shifting offsets and
# corrupting the window excerpt fed to coders. One string + ICU ignore_case (folds Croatian correctly)
# removes the risk structurally. (Regex DETECTION only — udpipe tokenization still lowercases; MEMORY.md.)
orig_text <- corpus$FULL_TEXT
n_na <- sum(is.na(orig_text)); n_empty <- sum(!is.na(orig_text) & !nzchar(orig_text))
cat("  FULL_TEXT NA/empty:", n_na, "/", n_empty, "\n")
# folded-text share (nlp-review M6): posts with NO Croatian diacritics — where religion recall
# (bare-diacritic patterns from R/religious_terms.R) is depressed vs the diacritic-class economy patterns.
n_folded <- sum(!str_detect(orig_text, "[čćžšđČĆŽŠĐ]"), na.rm = TRUE)
cat(sprintf("  diacritic-free posts (folded-text share): %d (%.1f%%)\n", n_folded, 100 * n_folded / N))

# outlet label (confessional/secular; PI-owned proposed labels — indicative)
label <- rep("neoznačeno", N)
if (file.exists(lab_path)) {
  lab <- read.csv(lab_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  lk <- setNames(lab$label, lab$from)
  hit <- !is.na(FROM) & FROM %in% names(lk); label[hit] <- unname(lk[FROM[hit]])
}
dparse <- suppressWarnings(as.Date(substr(as.character(corpus$DATE), 1, 10)))
cat("  DATE unparseable:", sum(is.na(dparse) & !is.na(corpus$DATE)), "\n")

# ------------------------------------------------------------------------------------------------
# POSITION-BASED linkage (rewritten after a live hang on the master, 2026-07-07 — see below).
# A combined proximity REGEX ("(?:DOM)[\s\S]{0,W}(?:REL)|(?:REL)[\s\S]{0,W}(?:DOM)") is catastrophic-
# backtracking-prone: on a real article with MANY repeated domain-term hits (e.g. a tax-policy piece
# repeating "porez/porezni/pdv/..." dozens of times) the engine must try the ~220-char lookahead from
# every hit, and combined with a 95-term religion alternation this hung the actual Stage-A run at
# 99% CPU / zero progress on `taxes_fiscal` (confirmed: an isolated repro of "many repeated domain
# terms, no religion nearby" reproduced an 8+ second hang per call; a REAL long article can be far
# worse). FIX: never build a combined proximity regex. Locate ALL domain-hit and ALL religion-hit
# character positions ONCE per doc (each a single well-behaved regex, no backtracking risk), then do
# the ±WINDOW proximity test as plain integer-vector arithmetic. Benchmarked on adversarial stress
# text (thousands of interleaved domain+religion hits in one 100k-char doc): <1s, vs a >10s hang for
# the regex-proximity approach on the same input.
IC <- function(p) regex(p, ignore_case = TRUE, dotall = TRUE)
# ENGINE CHOICE (2026-07-07): base-R grepl/gregexpr(perl=TRUE) is ~3-4x faster than stringr::str_detect
# (ICU) on the 95-term religion alternation, and was tried here — but REJECTED after verification:
# PCRE's \w (even under useBytes=FALSE, UTF-8 locale) does NOT treat Croatian diacritics as word
# characters, so e.g. "porez\\w*" matches only "porezni" and STOPS before "čki" in "poreznički" —
# silently truncating recall on every \w+/\w* pattern that spans a diacritic (most of the domain
# lexicon). PCRE's (*UCP) Unicode mode is the documented fix but crashed R in ad-hoc testing here and
# was not verified safe in the time available. Given the choice between a ~47-min correct run (ICU)
# and a faster run with an unverified, potentially silent recall regression across the whole lexicon,
# correctness wins. stringr's str_detect/str_locate_all (ICU, Unicode-\w-correct) are kept as the
# detection engine; the perf fix that actually mattered is the GLOBAL religion pass below (computed
# ONCE for the whole corpus, not 11x) plus the position-based (non-regex-proximity) linkage test.
pcre_detect <- function(txt, pattern) str_detect(txt, IC(pattern))
pcre_locate_all <- function(txt, pattern) str_locate_all(txt, IC(pattern))
# near(): TRUE if ANY domain-hit and ANY religion-hit are within `window` chars of each other
# (either can start first) using open intervals [start,end]; NA-safe (empty locate -> 0-row matrix).
near <- function(dloc, rloc, window) {
  if (!nrow(dloc) || !nrow(rloc)) return(FALSE)
  any(outer(dloc[, 1], rloc[, 2], `-`) <= window & outer(dloc[, 2], rloc[, 1], `-`) >= -window)
}
first_span <- function(dloc, rloc, window) {
  # smallest domain/religion hit PAIR that satisfies `near`, for window-excerpt extraction
  for (i in seq_len(nrow(dloc))) for (j in seq_len(nrow(rloc))) {
    if (dloc[i,1] - rloc[j,2] <= window && dloc[i,2] - rloc[j,1] >= -window)
      return(c(min(dloc[i,1], rloc[j,1]), max(dloc[i,2], rloc[j,2])))
  }
  NULL
}
WIN_PAD <- 40L   # extra context chars each side of the matched proximity span, for coder readability

# ------------------------------------------------------------------------------------------------
# GLOBAL religion pass (done ONCE for the whole corpus, not per-domain — perf fix #2, 2026-07-07).
# The 95-term religion alternation is expensive to evaluate; because this corpus is ALREADY
# religion-filtered (>=2 matches on every row by construction), the "only locate where detect says
# TRUE" gate barely reduces work here (most rows DO contain religion) — so this step is a genuinely
# long, mostly-unavoidable computation, not a bug. Stage-A's domain loop used to re-run this fresh
# inside EACH of 11 iterations (an 11x redundant cost); doing it once here is still the big win.
#
# CHUNKED + INCREMENTALLY CHECKPOINTED (2026-07-08, v2 — after this step ran ~14 min/chunk on the
# real master, far slower than synthetic benchmarks suggested, projecting ~6.5h total). A run THIS
# long WILL get interrupted eventually (a kill, a reboot, a Dropbox hiccup), so the checkpoint now
# saves after EVERY chunk (not just once at the very end) — an interruption loses at most one
# chunk's work (~14 min), not the whole multi-hour pass. Resume picks up at the first incomplete chunk.
na_safe <- function(x) { x[is.na(x)] <- FALSE; x }
GLOBAL_PATH <- file.path(out_dir, "stageA_global_religion.rds")
CHUNK <- 25000L
global_fp <- list(relig_wc = relig$with_caritas, relig_core = relig$core, foreign_rx = ME_FOREIGN_HINT,
                  mtime = fp$mtime, size = fp$size, relterms_md5 = fp$relterms_md5, chunk = CHUNK)
chunks <- split(seq_len(N), ceiling(seq_len(N) / CHUNK))

done_ci <- 0L
G_has_wc <- logical(N); G_rloc_wc <- vector("list", N)
G_has_core <- logical(N); G_rloc_co <- vector("list", N)
G_has_fg <- logical(N); G_rloc_fg <- vector("list", N)
if (file.exists(GLOBAL_PATH)) {
  Gc <- readRDS(GLOBAL_PATH)
  if (identical(attr(Gc, "fingerprint"), global_fp)) {
    done_ci <- attr(Gc, "done_ci")
    cat(sprintf("Resuming GLOBAL religion pass from chunk %d/%d (checkpoint: %s)\n",
                done_ci + 1L, length(chunks), GLOBAL_PATH))
    G_has_wc <- Gc$has_wc; G_rloc_wc <- Gc$rloc_wc; G_has_core <- Gc$has_core
    G_rloc_co <- Gc$rloc_co; G_has_fg <- Gc$has_fg; G_rloc_fg <- Gc$rloc_fg
  } else cat("Cached global religion pass built from a DIFFERENT input — recomputing from chunk 1.\n")
}

if (done_ci < length(chunks)) {
  if (done_ci == 0L) cat("Global religion pass (chunked, checkpointed after EVERY chunk)...\n")
  tg <- Sys.time()
  for (ci in seq.int(done_ci + 1L, length(chunks))) {
    idx <- chunks[[ci]]; ctxt <- orig_text[idx]
    hwc <- na_safe(pcre_detect(ctxt, relig$with_caritas)); G_has_wc[idx] <- hwc
    if (any(hwc)) G_rloc_wc[idx[hwc]] <- pcre_locate_all(ctxt[hwc], relig$with_caritas)
    hco <- hwc & na_safe(pcre_detect(ctxt, relig$core)); G_has_core[idx] <- hco
    if (any(hco)) G_rloc_co[idx[hco]] <- pcre_locate_all(ctxt[hco], relig$core)
    hfg <- na_safe(pcre_detect(ctxt, ME_FOREIGN_HINT)); G_has_fg[idx] <- hfg
    if (any(hfg)) G_rloc_fg[idx[hfg]] <- pcre_locate_all(ctxt[hfg], ME_FOREIGN_HINT)

    Gc <- list(has_wc = G_has_wc, rloc_wc = G_rloc_wc, has_core = G_has_core, rloc_co = G_rloc_co,
              has_fg = G_has_fg, rloc_fg = G_rloc_fg)
    attr(Gc, "fingerprint") <- global_fp; attr(Gc, "done_ci") <- ci
    saveRDS(Gc, GLOBAL_PATH)   # written after EVERY chunk — worst-case loss on interruption = 1 chunk

    el <- as.numeric(difftime(Sys.time(), tg, "mins")); done_now <- ci - done_ci
    cat(sprintf("  chunk %2d/%d (rows up to %s) — %.1f min elapsed this session, ~%.1f min remaining [saved]\n",
                ci, length(chunks), format(max(idx), big.mark = ","), el, el / done_now * (length(chunks) - ci)))
  }
  cat(sprintf("Global religion pass done (religion hits: %d, core: %d, foreign-hint: %d)\n",
              sum(G_has_wc), sum(G_has_core), sum(G_has_fg)))
} else cat("Global religion pass already fully complete from checkpoint.\n")

set.seed(20260707)
PREC_N <- 80L    # per-domain matched sample captured for the Gate-1 precision hand-scan
cand_list <- list(); prec_list <- list(); stat_list <- list()
wilson <- function(k, n, z = 1.96) { if (!n) return(c(NA, NA)); p <- k/n; d <- 1+z^2/n
  c(max(0,((p+z^2/(2*n))-z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d), min(1,((p+z^2/(2*n))+z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d)) }

for (d in names(ME_ECON)) {
  t1 <- Sys.time(); dom_rx <- ME_ECON[[d]]
  matched  <- which(na_safe(pcre_detect(orig_text, dom_rx)))   # NA -> FALSE -> which() drops it (no phantoms)
  txt      <- orig_text[matched]
  dloc_all <- pcre_locate_all(txt, dom_rx)
  # subset the GLOBAL religion pass (no re-detection, no re-location — O(1) indexing)
  rloc_wc <- G_rloc_wc[matched]; rloc_co <- G_rloc_co[matched]; rloc_fg <- G_rloc_fg[matched]

  linked  <- mapply(function(dl, rl) if (is.null(rl)) FALSE else near(dl, rl, ME_WINDOW), dloc_all, rloc_wc)
  core    <- mapply(function(dl, rl) if (is.null(rl)) FALSE else near(dl, rl, ME_WINDOW), dloc_all, rloc_co)
  foreign <- mapply(function(dl, rl) if (is.null(rl)) FALSE else near(dl, rl, ME_WINDOW), dloc_all, rloc_fg)
  metaphor <- if (d == "inflation_prices") na_safe(pcre_detect(txt, ME_INFLATION_METAPHOR)) else rep(FALSE, length(txt))
  actor_only <- linked & !core                                   # linked only via caritas = religion-as-actor
  lk <- which(linked)

  # Pass 2 — window TEXT only for linked rows (position arithmetic, no regex re-scan)
  win <- rep(NA_character_, length(txt))
  if (length(lk)) {
    for (i in lk) {
      sp <- first_span(dloc_all[[i]], rloc_wc[[i]], ME_WINDOW)
      a <- max(1L, sp[1]-WIN_PAD); b <- min(str_length(txt[i]), sp[2]+WIN_PAD)
      win[i] <- str_replace_all(str_sub(txt[i], a, b), "\\s+", " ")
    }
  }
  if (length(lk)) {
    li <- matched[lk]
    cand_list[[d]] <- data.frame(
      rid = li, domain = d, tier = ME_TIER[[d]],
      DATE = corpus$DATE[li], year = format(dparse[li], "%Y"), month = format(dparse[li], "%Y-%m"),
      FROM = FROM[li], SOURCE_TYPE = SOURCE_TYPE[li], stream = STREAM[li], label = label[li],
      actor_only_caritas = actor_only[lk], foreign_hint = foreign[lk], infl_metaphor_hint = metaphor[lk],
      TITLE = TITLE[li], URL = URL[li], window = win[lk], stringsAsFactors = FALSE)
  }

  # precision sample = capped random draw of MATCHED posts (linked or not), window around the domain match
  ps <- if (length(matched) > PREC_N) sort(sample(seq_along(matched), PREC_N)) else seq_along(matched)
  if (length(ps)) {
    ploc <- str_locate(txt[ps], IC(dom_rx))
    pa <- pmax(1L, ploc[,1]-ME_WINDOW); pb <- pmin(str_length(txt[ps]), ploc[,2]+ME_WINDOW)
    prec_list[[d]] <- data.frame(
      rid = matched[ps], domain = d, matched = TRUE, linked = linked[ps],
      FROM = FROM[matched[ps]], stream = STREAM[matched[ps]], label = label[matched[ps]],
      window = str_replace_all(str_sub(txt[ps], pa, pb), "\\s+", " "), stringsAsFactors = FALSE)
  }

  # domain stats (full census). linkage_ex_caritas == mean(core) since core-terms ⊂ with_caritas ⇒ core ⊆ linked.
  k <- length(lk); ci <- wilson(k, length(matched))
  s1 <- linked[STREAM[matched] %in% "original_dta"]; s2 <- linked[STREAM[matched] %in% "filtered_religious"]
  cl <- label[matched]; cl <- cl[cl %in% c("confessional","secular")]
  stat_list[[d]] <- data.frame(
    domain = d, tier = ME_TIER[[d]], n_matched = length(matched), n_linked = k,
    linkage = round(k/max(1,length(matched)), 3), linkage_lo = round(ci[1],3), linkage_hi = round(ci[2],3),
    linkage_ex_caritas = round(mean(core), 3),
    linkage_2021_24 = if(length(s1)) round(mean(s1),3) else NA,
    linkage_2024_26 = if(length(s2)) round(mean(s2),3) else NA,
    foreign_hint_rate = round(mean(foreign),3),
    confessional_share = if(length(cl)) round(mean(cl=="confessional"),3) else NA,
    infl_metaphor_flagged = sum(metaphor & linked),
    stringsAsFactors = FALSE)
  cat(sprintf("  %-17s matched=%6d linked=%5d (%.3f)  [%.1fs]\n",
              d, length(matched), k, k/max(1,length(matched)), as.numeric(difftime(Sys.time(), t1, "secs"))))
}

candidates <- do.call(rbind, cand_list); rownames(candidates) <- NULL
attr(candidates, "fingerprint") <- fp
saveRDS(candidates, CAND_PATH)
saveRDS(do.call(rbind, prec_list), file.path(out_dir, "stageA_precision_sample.rds"))
stats <- do.call(rbind, stat_list)
write.csv(stats, file.path(out_dir, "stageA_domain_stats.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\n== STAGE A complete — full-census linkage (N =", format(N, big.mark=","), ") ==\n")
print(stats[, c("domain","tier","n_matched","n_linked","linkage","confessional_share")], row.names = FALSE)
cat("\nLINKED candidate pool (Stage-B source):", format(nrow(candidates), big.mark=","), "rows across",
    length(unique(candidates$domain)), "domains\n")
cat("Outputs: stageA_candidates.rds | stageA_precision_sample.rds | stageA_domain_stats.csv ->", out_dir, "\n")
cat("Next: 02_gate1_precision_scan.R (hand-scan) then 03_build_coding_sheet.R (stratified sample).\n")
