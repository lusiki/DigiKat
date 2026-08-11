#!/usr/bin/env Rscript
# moral-economy - draw fresh R4 and R1/R2 validation samples for the official corpus.
#
# R4 is a simple random sample of 60 linked (post, domain) pairs within each economic domain.
# R1 is a fresh proportional stratified sample of 150 posts from the corrected CST core, using
# doctrinal era x current outlet-rank band. All cards are emitted blind and both axes are recoded.
# No legacy decision is reused: this prevents an undocumented strict-code pass or old outlet-band
# probabilities from entering the official analysis.
#
#   Rscript studies/moral-economy/30_refresh_rsp_audits.R
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))
source(here::here("studies/moral-economy/rsp_input.R"))

rsp_assert_official_inputs()
PER_DOMAIN <- 60L
R1_N <- 150L
BATCH <- 40L
R4_TEXT <- 400L
R1_EXCERPT <- 700L

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write.table(x, path, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE,
              fileEncoding = "UTF-8", na = "")
  invisible(path)
}
flat <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
pair_id <- function(rid, domain) paste(as.integer(rid), domain, sep = "\r")

# A rerun must never consume decisions made for a previous sample. Refuse before writing new sheets;
# archive or remove generated private TSV parts deliberately if a new sample is intended.
for (d in c(RSP_R4_NEW_ANN, RSP_R1_NEW_ANN)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  old_parts <- list.files(d, pattern = "\\.tsv$", full.names = TRUE)
  if (length(old_parts)) {
    stop("Annotation directory is not empty: ", d,
         "\nArchive/remove its generated TSV parts before redrawing the audits.", call. = FALSE)
  }
}

cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand$rid <- as.integer(cand$rid)
prepared <- readRDS(RSP_CORPUS_PREPARED)
prepared_rid <- as.integer(sub("^dk_", "", prepared$doc_id))
if (anyNA(prepared_rid) || anyDuplicated(prepared_rid)) {
  stop("Bad prepared-corpus rid key.", call. = FALSE)
}

## R4 denominator precision: fresh SRS within each domain -------------------------------
cat("=== R4 official-corpus audit sample ===\n")
pairs <- unique(cand[, c("rid", "domain")])
frame <- pairs
cand_first <- cand[!duplicated(pair_id(cand$rid, cand$domain)), ]
cand_key <- pair_id(cand_first$rid, cand_first$domain)

set.seed(ME_SEED + 411L)
r4_draw <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
  pool <- frame[frame$domain == d, , drop = FALSE]
  if (nrow(pool) < PER_DOMAIN) stop("R4 frame is too small for domain ", d, call. = FALSE)
  out <- pool[sample.int(nrow(pool), PER_DOMAIN), , drop = FALSE]
  out$provenance <- "new"
  out
}))
rownames(r4_draw) <- NULL
if (any(table(r4_draw$domain) != PER_DOMAIN) ||
    anyDuplicated(pair_id(r4_draw$rid, r4_draw$domain))) {
  stop("R4 draw did not produce 60 unique pairs per domain.", call. = FALSE)
}

ri <- match(pair_id(r4_draw$rid, r4_draw$domain), cand_key)
if (anyNA(ri)) stop("R4 draw contains a pair absent from Stage A.", call. = FALSE)
r4_draw$window <- cand_first$window[ri]
pi <- match(r4_draw$rid, prepared_rid)
if (anyNA(pi)) stop("R4 draw contains a rid absent from official prepared text.", call. = FALSE)
r4_draw$text_800 <- substr(prepared$text[pi], 1L, R4_TEXT)

set.seed(ME_SEED + 412L)
r4_draw <- r4_draw[sample.int(nrow(r4_draw)), , drop = FALSE]
r4_draw$item <- seq_len(nrow(r4_draw))
ri <- match(pair_id(r4_draw$rid, r4_draw$domain), cand_key)
if (anyNA(ri)) stop("Shuffled R4 draw no longer matches the Stage-A key.", call. = FALSE)
r4_blind <- r4_draw[, c("item", "rid", "domain", "window", "text_800")]
r4_blind$ax1_link_genuine <- ""
r4_blind$ax1_strict <- ""
sem_write_private(r4_blind, RSP_R4_SHEET)

meta_cols <- c("DATE", "year", "FROM", "SOURCE_TYPE", "stream", "label", "foreign_hint",
               "infl_metaphor_hint", "actor_only_caritas", "TITLE", "URL")
r4_key <- cbind(r4_draw[, c("item", "rid", "domain", "provenance")], cand_first[ri, meta_cols])
sem_write_private(r4_key, RSP_R4_KEY)
r4_reused <- data.frame(item = integer(), rid = integer(), ax1_link_genuine = character(),
                        ax1_strict = character(), stringsAsFactors = FALSE)
write_tsv(r4_reused, RSP_R4_ANN_REUSED)

dir.create(RSP_R4_BATCHES, recursive = TRUE, showWarnings = FALSE)
dir.create(RSP_R4_NEW_ANN, recursive = TRUE, showWarnings = FALSE)
groups <- split(seq_len(nrow(r4_draw)), ceiling(seq_len(nrow(r4_draw)) / BATCH))
for (g in names(groups)) {
  ix <- groups[[g]]
  lines <- c(sprintf("# R4 official full-recode batch %s of %d - %d pairs",
                     g, length(groups), length(ix)), "",
    "Code both fields from the blind material below.",
    "ax1_link_genuine: genuine | incidental",
    "  genuine - religious discourse and the economic subject address one another",
    "  incidental - mere co-occurrence, venue/organisation detail, homonym, or unrelated mention",
    "ax1_strict: genuine | incidental",
    "  genuine - ax1 is genuine AND the economic term has a real material/economic referent",
    "  incidental - otherwise; strict-genuine may never coexist with codebook-incidental",
    "Default to incidental when uncertain.",
    "Return: item<TAB>rid<TAB>ax1_link_genuine<TAB>ax1_strict", "")
  for (k in ix) lines <- c(lines,
    sprintf("### ITEM %d | rid=%s | domain=%s", r4_draw$item[k], r4_draw$rid[k], r4_draw$domain[k]),
    sprintf("WINDOW: %s", flat(r4_draw$window[k])),
    sprintf("TEXT: %s", flat(r4_draw$text_800[k])), "")
  writeLines(lines, file.path(RSP_R4_BATCHES,
                              sprintf("r4_official_batch_%02d.md", as.integer(g))), useBytes = FALSE)
}

r4_pop <- as.data.frame(table(domain = frame$domain), stringsAsFactors = FALSE)
names(r4_pop)[2] <- "frame_pairs"
r4_alloc <- data.frame(domain = r4_pop$domain, frame_pairs = as.integer(r4_pop$frame_pairs),
                       reused = 0L, new = PER_DOMAIN, sampled = PER_DOMAIN,
                       stringsAsFactors = FALSE)
r4_alloc$sampling_fraction <- round(r4_alloc$sampled / r4_alloc$frame_pairs, 6)
sem_write_shareable(r4_alloc, file.path(ME_OUT, "r4_sample_allocation.csv"))
cat(sprintf("  R4: 0 reused + %d new = %d pairs\n", nrow(r4_draw), nrow(r4_draw)))

## R1/R2 numerator precision: fresh proportional era x current outlet-band sample -------------
cat("\n=== R1/R2 official-corpus audit sample ===\n")
core <- cst_build_core(verbose = FALSE)
rank_tab <- sort(table(core$actor), decreasing = TRUE)
band <- function(a) {
  r <- match(as.character(a), names(rank_tab))
  ifelse(is.na(r), "rest",
         ifelse(r == 1, "top1", ifelse(r <= 3, "top2_3", ifelse(r <= 10, "top4_10", "rest"))))
}
core$band <- band(core$actor)
core$stratum <- paste(core$era, core$band, sep = "|")
sz <- table(core$stratum)
quota <- R1_N * as.numeric(sz) / sum(sz); names(quota) <- names(sz)
want <- pmax(1L, as.integer(floor(quota))); names(want) <- names(sz)
while (sum(want) < R1_N) {
  z <- which.max(quota - want); want[z] <- want[z] + 1L
}
while (sum(want) > R1_N) {
  eligible <- which(want > 1L)
  if (!length(eligible)) stop("Cannot reconcile the R1 integer allocation.", call. = FALSE)
  z <- eligible[which.max(want[eligible] - quota[eligible])]; want[z] <- want[z] - 1L
}

core_from <- pmax(1L, core$junction - R1_EXCERPT %/% 2L)
core$excerpt <- stri_sub(core$slice, core_from, core_from + R1_EXCERPT - 1L)
set.seed(ME_SEED + 421L)
r1_idx <- unlist(lapply(names(sz), function(s) {
  pool <- which(core$stratum == s)
  if (length(pool) < want[[s]]) stop("R1 stratum is smaller than its target: ", s, call. = FALSE)
  sample(pool, want[[s]])
}), use.names = FALSE)
r1_draw <- core[r1_idx, , drop = FALSE]
r1_draw$provenance <- "new"
if (nrow(r1_draw) != R1_N || anyDuplicated(r1_draw$rid)) {
  stop("R1 fresh draw failed.", call. = FALSE)
}

set.seed(ME_SEED + 422L)
r1_draw <- r1_draw[sample.int(nrow(r1_draw)), , drop = FALSE]
r1_draw$item <- seq_len(nrow(r1_draw))
r1_blind <- r1_draw[, c("item", "rid", "excerpt")]
r1_blind$r1_invocation <- ""
r1_blind$r2_econ_true <- ""
sem_write_private(r1_blind, RSP_R1_SHEET)

r1_key <- r1_draw[, c("item", "rid", "era", "band", "domains", "terms", "gap", "stream", "label",
                            "provenance")]
r1_key$domain_tier <- vapply(strsplit(r1_key$domains, "\\s+"),
                             function(d) paste(sort(unique(ME_TIER[d])), collapse = ""), "")
sem_write_private(r1_key, RSP_R1_KEY)
r1_reused <- data.frame(item = integer(), rid = integer(), r1_invocation = character(),
                        r2_econ_true = character(), stringsAsFactors = FALSE)
write_tsv(r1_reused, RSP_R1_ANN_REUSED)

dir.create(RSP_R1_BATCHES, recursive = TRUE, showWarnings = FALSE)
dir.create(RSP_R1_NEW_ANN, recursive = TRUE, showWarnings = FALSE)
groups <- split(seq_len(nrow(r1_draw)), ceiling(seq_len(nrow(r1_draw)) / BATCH))
for (g in names(groups)) {
  ix <- groups[[g]]
  lines <- c(sprintf("# R1/R2 official full-recode batch %s of %d - %d cards",
                     g, length(groups), length(ix)), "",
    "Each excerpt is centred where Tier-1 Catholic Social Teaching vocabulary was detected next to",
    "an economic term. The detected label is hidden.",
    "r1_invocation: genuine | mention | false",
    "  genuine - teaching is quoted, applied, or used as a reason",
    "  mention - doctrine is named but not used (listing, programme, advert, byline, title only)",
    "  false - no magisterial title or doctrine-specific term is present",
    "r2_econ_true: yes | no - the adjacent economic word has a real economic referent",
    "Return: item<TAB>rid<TAB>r1_invocation<TAB>r2_econ_true", "")
  for (k in ix) lines <- c(lines,
    sprintf("### CARD %d | rid=%s", r1_draw$item[k], r1_draw$rid[k]), flat(r1_draw$excerpt[k]), "")
  writeLines(lines, file.path(RSP_R1_BATCHES,
                              sprintf("r1_official_batch_%02d.md", as.integer(g))), useBytes = FALSE)
}

r1_alloc <- data.frame(stratum = names(sz), population = as.integer(sz), target = as.integer(want),
                       stringsAsFactors = FALSE)
r1_alloc$era <- sub("\\|.*$", "", r1_alloc$stratum)
r1_alloc$outlet_band <- sub("^[^|]+\\|", "", r1_alloc$stratum)
r1_alloc$reused <- 0L
r1_alloc$new <- r1_alloc$target
sem_write_shareable(r1_alloc[, c("era", "outlet_band", "population", "target", "reused", "new")],
                    file.path(ME_OUT, "r1_sample_allocation.csv"))
cat(sprintf("  R1: 0 reused + %d new = %d cards\n", nrow(r1_draw), nrow(r1_draw)))

provenance <- rbind(
  data.frame(audit = "R4", stratum = r4_alloc$domain, population = r4_alloc$frame_pairs,
             target = r4_alloc$sampled, reused = r4_alloc$reused, new = r4_alloc$new),
  data.frame(audit = "R1", stratum = paste(r1_alloc$era, r1_alloc$outlet_band, sep = "|"),
             population = r1_alloc$population, target = r1_alloc$target,
             reused = r1_alloc$reused, new = r1_alloc$new))
sem_write_shareable(provenance, file.path(ME_OUT, "rsp_annotation_provenance.csv"))

digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/30_refresh_rsp_audits.R",
  inputs = list(database_sha256 = rsp_read_input_manifest()$database$sha256,
                candidates_sha256 = digikat_hash_file(RSP_STAGEA_CANDIDATES),
                core_sha256 = digikat_hash_file(RSP_CORE_CACHE)),
  outputs = list(r4_sheet_sha256 = digikat_hash_file(RSP_R4_SHEET),
                 r1_sheet_sha256 = digikat_hash_file(RSP_R1_SHEET),
                 provenance = "output/rsp_annotation_provenance.csv"),
  extra = list(method = paste("Fresh official-corpus samples: R4 simple random sampling within domain;",
                              "R1 proportional stratified sampling within current era x outlet band."),
               r4_target_per_domain = PER_DOMAIN, r4_reused = 0L, r4_new = nrow(r4_draw),
               r1_target = R1_N, r1_reused = 0L, r1_new = nrow(r1_draw))
), file.path(ME_OUT, "rsp_audit_refresh_manifest.json"))

cat("\nBlind full-recode batches:\n  ", RSP_R4_BATCHES, "\n  ", RSP_R1_BATCHES, "\n", sep = "")
cat("Place coded TSV parts in the corresponding annotation directory, then run step 31.\n")
