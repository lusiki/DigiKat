#!/usr/bin/env Rscript
# moral-economy R4 — DRAW A FRESH, UNBIASED, PER-DOMAIN SAMPLE OF THE LINKED LAYER.
#
# PROPOSAL_v5_rsp.md Part V.2/R4 is the study's single largest risk. The invocation-rate gradient is
#   doctrinal(domain) / linked(domain)
# and `linked` is Stage A's keyword-linkage layer, whose precision was measured only POOLED (34.6%
# genuine, 192/555) and only on a set drawn for other purposes. `18_gold_reanalysis.R` showed the
# coded per-domain rates span 3.1%-53.1%, but its `random_linked` stratum is n = 28 — two posts for
# climate. That cannot estimate anything. If linkage precision varies by domain in the LAYER the way
# it varies in that sample, the gradient is a denominator artefact.
#
# This script draws the sample the proposal specifies: 60 (rid, domain) pairs per domain, simple
# random within domain, seeded with ME_SEED, from the linked layer itself.
#
# THREE DESIGN POINTS, each of which the analysis in 20_r4_recompute.R depends on:
#
#   1. The sampling unit is the (rid, domain) PAIR, not the post. 17_cst_robustness.R's gate G1b
#      established that the gradient's denominator is `distinct(rid, domain)` — 132,519 pairs across
#      108,966 posts. A post linked to three domains is three chances for the linkage rule to be
#      right or wrong, and precision has to be estimated on the same unit the rate divides by.
#
#   2. The 555 gold rids are EXCLUDED. The proposal forbids reusing them; drawing fresh but allowing
#      overlap would reintroduce the same posts through the back door and make "independent" false.
#      555 of 108,966 is a 0.5% reduction of the frame — reported below, not hidden.
#
#   3. The coder sees the ±220 `window` — which IS the unit Axis 1 is defined on ("is religion in
#      conversation with the economic content INSIDE the ±220 window") — plus a 400-character opening
#      excerpt for topical context. The gold set carried 800 characters of context. The shorter
#      excerpt is a deliberate, declared deviation: it is cheaper to code at 660 items, and because
#      the codebook resolves uncertainty toward `incidental`, less context can only push the measured
#      precision DOWN. A conservative denominator correction is the safe direction of error here,
#      since a lower measured precision inflates the adjusted invocation rates we are trying to
#      falsify. This must be stated in the manuscript, not left implicit.
#
#   Rscript studies/moral-economy/19_r4_linkage_sample.R [--per-domain=60] [--batch=60] [--text=400]
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))

args      <- commandArgs(trailingOnly = TRUE)
PER_DOM   <- as.integer(digikat_cli_value(args, "--per-domain", "60"))
BATCH     <- as.integer(digikat_cli_value(args, "--batch", "60"))
TEXT_CHARS <- as.integer(digikat_cli_value(args, "--text", "400"))

cat("=== R4 — fresh per-domain linkage-precision sample ===\n")

cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
cand$rid <- as.integer(cand$rid)
pairs <- unique(cand[, c("rid", "domain")])
cat(sprintf("linked layer: %s pairs across %s posts\n",
            digikat_format_integer(nrow(pairs)), digikat_format_integer(length(unique(pairs$rid)))))

# ---- exclude the gold rids (independence firewall) ------------------------------------------
gold_path <- file.path(ME_PRIVATE, "gold_core.csv")
gold_rids <- integer(0)
if (file.exists(gold_path)) {
  gold_rids <- as.integer(read.csv(gold_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)$rid)
  gold_rids <- gold_rids[!is.na(gold_rids)]
}
frame <- pairs[!pairs$rid %in% gold_rids, ]
cat(sprintf("excluded %d gold rids -> frame of %s pairs (%.2f%% of the layer removed)\n",
            length(unique(gold_rids)), digikat_format_integer(nrow(frame)),
            100 * (1 - nrow(frame) / nrow(pairs))))

# ---- draw ------------------------------------------------------------------------------------
set.seed(ME_SEED)
drawn <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
  pool <- frame[frame$domain == d, ]
  k <- min(PER_DOM, nrow(pool))
  if (k < PER_DOM) {
    cat(sprintf("  NOTE %-17s has only %d pairs; drawing all of them\n", d, nrow(pool)))
  }
  pool[sample(nrow(pool), k), ]
}))
rownames(drawn) <- NULL
cat("\ndrawn per domain:\n"); print(table(drawn$domain))
cat(sprintf("total: %d pairs\n", nrow(drawn)))

# The sampling FRACTION differs by domain by three orders of magnitude (60/407 for the euro
# changeover vs 60/38,232 for poverty). That is intentional -- we need a precision estimate of usable
# width in every domain, not a self-weighting sample -- but it means the pooled rate across this
# sample is NOT an estimate of layer-wide precision. 20_r4_recompute.R must reweight for that, and
# the weights are computed here so the two scripts cannot disagree about them.
dom_size <- as.data.frame(table(pairs$domain), stringsAsFactors = FALSE)
names(dom_size) <- c("domain", "layer_pairs")
alloc <- merge(as.data.frame(table(drawn$domain), stringsAsFactors = FALSE) |>
                 setNames(c("domain", "sampled")), dom_size, by = "domain")
alloc$sampling_fraction <- round(alloc$sampled / alloc$layer_pairs, 5)
alloc$layer_share       <- round(alloc$layer_pairs / sum(alloc$layer_pairs), 5)
cat("\nsampling fractions (why the pooled sample rate is not a layer estimate):\n")
print(alloc[order(-alloc$layer_pairs), ], row.names = FALSE)

# ---- attach the coding text ------------------------------------------------------------------
w <- cand[!duplicated(paste(cand$rid, cand$domain)), c("rid", "domain", "window")]
sheet <- merge(drawn, w, by = c("rid", "domain"), all.x = TRUE)
if (any(is.na(sheet$window) | !nzchar(sheet$window))) stop("A drawn pair has no Stage-A window.", call. = FALSE)

cat(sprintf("\nreading corpus_prepared.rds for the %d-char context excerpt...\n", TEXT_CHARS))
corpus <- readRDS(here::here("data/semantic/corpus_prepared.rds"))
rid_all <- as.integer(sub("^dk_", "", corpus$doc_id))
i <- match(sheet$rid, rid_all)
if (anyNA(i)) stop("Drawn rid(s) absent from corpus_prepared.rds — the id mapping has drifted.", call. = FALSE)
sheet$text_800 <- substr(corpus$text[i], 1L, TEXT_CHARS)
rm(corpus); invisible(gc())

# ---- KEY (withheld from the coder) ------------------------------------------------------------
meta_cols <- c("DATE", "year", "FROM", "SOURCE_TYPE", "stream", "label",
               "foreign_hint", "infl_metaphor_hint", "actor_only_caritas", "TITLE", "URL")
mi <- match(paste(sheet$rid, sheet$domain), paste(cand$rid, cand$domain))
key <- cbind(sheet[, c("rid", "domain")], cand[mi, meta_cols])
sem_write_private(key, file.path(ME_PRIVATE, "r4_key.csv"))

# ---- BLIND sheet ------------------------------------------------------------------------------
set.seed(ME_SEED + 2L)
sheet <- sheet[sample(nrow(sheet)), ]           # shuffle so domain blocks are not contiguous
sheet$item <- seq_len(nrow(sheet))
blind <- sheet[, c("item", "rid", "domain", "window", "text_800")]
blind$ax1_link_genuine <- ""
LEAK <- c("FROM", "URL", "TITLE", "label", "stream", "DATE", "SOURCE_TYPE", "foreign_hint")
if (any(LEAK %in% names(blind))) stop("Blind sheet leaks a withheld field.", call. = FALSE)
sem_write_private(blind, file.path(ME_PRIVATE, "r4_sheet.csv"))

# ---- annotator batches (09a idiom: whitespace-collapsed blocks, never raw CSV) ----------------
bdir <- file.path(ME_PRIVATE, "r4_batches")
unlink(bdir, recursive = TRUE); dir.create(bdir, recursive = TRUE, showWarnings = FALSE)
flat <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
groups <- split(seq_len(nrow(blind)), ceiling(seq_len(nrow(blind)) / BATCH))
for (g in names(groups)) {
  ix <- groups[[g]]
  lines <- c(sprintf("# R4 linkage-precision batch %s of %d — %d items", g, length(groups), length(ix)),
             "",
             "AXIS 1 ONLY (CODEBOOK.md). For each item decide whether the religious content and the",
             "economic content are actually in conversation, or merely co-occur in the same post.",
             "  genuine    — religion and the economic matter address each other",
             "  incidental — co-occurrence only (a church as a venue, a homonym, an unrelated mention)",
             "DEFAULT TO `incidental` WHEN UNCERTAIN.",
             "Return one TSV row per item: item<TAB>rid<TAB>ax1_link_genuine",
             "")
  for (k in ix) {
    lines <- c(lines,
      sprintf("### ITEM %d | rid=%s | domain=%s", blind$item[k], blind$rid[k], blind$domain[k]),
      sprintf("WINDOW: %s", flat(blind$window[k])),
      sprintf("TEXT: %s", flat(blind$text_800[k])), "")
  }
  writeLines(lines, file.path(bdir, sprintf("r4_batch_%02d.md", as.integer(g))), useBytes = FALSE)
}

sem_write_shareable(alloc, file.path(ME_OUT, "r4_sample_allocation.csv"))
digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/19_r4_linkage_sample.R",
  inputs  = list(candidates = "studies/moral-economy/output/stageA_candidates.rds",
                 corpus = "data/semantic/corpus_prepared.rds"),
  outputs = list(sheet = "output/private/r4_sheet.csv (RESTRICTED, blind)",
                 key   = "output/private/r4_key.csv (RESTRICTED)",
                 batches = "output/private/r4_batches/ (RESTRICTED)"),
  extra = list(unit = "(rid, domain) pair", per_domain_target = PER_DOM, n_drawn = nrow(blind),
               gold_rids_excluded = length(unique(gold_rids)),
               text_chars = TEXT_CHARS, axis = "ax1_link_genuine only",
               blindness = "sheet carries item, rid, domain, window, text only")
), file.path(ME_SEM, "r4_sample_manifest.json"))

cat(sprintf("\n== R4 sample built: %d pairs -> %s ==\n", nrow(blind), bdir))
cat("Next: code every batch, save output/private/r4_ann1.tsv, then run 20_r4_recompute.R\n")
