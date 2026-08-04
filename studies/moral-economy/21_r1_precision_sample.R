#!/usr/bin/env Rscript
# moral-economy R1/R2 — NUMERATOR PRECISION AUDIT OF THE 1,198 DOCTRINAL POSTS.
#
# R4 validated the denominator. R1 is the other half: "the regex found 1,198" is not "1,198 posts
# invoke the tradition". A Tier-1 hit can be a bibliographic listing, a book advertisement, a
# conference programme, a byline, or a title used as a proper noun with no doctrinal content.
#
# Two axes are coded on the same cards, because the reader has the junction in front of them either
# way and a second pass would cost another 150 reads:
#   r1_invocation : genuine | mention | false
#       genuine — the post actually invokes the teaching (quotes it, applies it, argues from it)
#       mention — the doctrine is named but not used: a listing, a programme, an advert, a byline
#       false   — no Tier-1 doctrine is present at all in the excerpt (detector error)
#   r2_econ_true  : yes | no  — is the economic term next to it a genuine economic reference?
#
# STRATIFICATION. PROPOSAL_v5 R1 asks for era x domain-tier stratification AND warns that the
# largest confessional portal is 32.0% of the population, so an unstratified draw is substantially
# a sample of one newsroom. This script strata on era x outlet-band (top-1 / top-2-3 / top-4-10 /
# rest) with proportional allocation, which covers both concerns: era is the axis the argument
# turns on and outlet-band is the concentration risk. Domain tier is recorded on the key so the
# per-tier breakdown is still recoverable at analysis time.
#
#   Rscript studies/moral-economy/21_r1_precision_sample.R [--n=150] [--batch=50]
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))

args   <- commandArgs(trailingOnly = TRUE)
N      <- as.integer(digikat_cli_value(args, "--n", "150"))
BATCH  <- as.integer(digikat_cli_value(args, "--batch", "50"))
EXCERPT <- 700L

cat("=== R1/R2 — numerator precision sample ===\n")
core <- cst_build_core(verbose = TRUE)

# outlet band; `actor` is the outlet field on the core table
rank_tab <- sort(table(core$actor), decreasing = TRUE)
band <- function(a) {
  r <- match(a, names(rank_tab))
  ifelse(r == 1, "top1", ifelse(r <= 3, "top2_3", ifelse(r <= 10, "top4_10", "rest")))
}
core$band <- band(core$actor)
core$stratum <- paste(core$era, core$band, sep = "|")
cat("\nstrata (era | outlet band):\n"); print(table(core$stratum))

# proportional allocation with a floor of 1 where the stratum exists, then trim the largest strata
set.seed(ME_SEED)
sz <- table(core$stratum)
want <- pmax(1L, as.integer(round(N * sz / sum(sz))))
names(want) <- names(sz)
while (sum(want) > N) { i <- which.max(want); want[i] <- want[i] - 1L }
while (sum(want) < N) { i <- which.max(sz - want); want[i] <- want[i] + 1L }
idx <- unlist(lapply(names(sz), function(s) {
  pool <- which(core$stratum == s)
  if (want[[s]] >= length(pool)) pool else sample(pool, want[[s]])
}), use.names = FALSE)
samp <- core[idx, ]
cat(sprintf("\ndrawn: %d cards\n", nrow(samp)))
cat("by era:\n"); print(table(samp$era))
cat("by outlet band:\n"); print(table(samp$band))

# junction-centred excerpt: `slice` is 2000 chars centred on the CST<->economy meeting point and
# `junction` is that point's offset inside it, so the doctrine and the economic term are both here.
from <- pmax(1L, samp$junction - EXCERPT %/% 2L)
samp$excerpt <- stri_sub(samp$slice, from, from + EXCERPT - 1L)

# KEY (withheld): what the detector thinks, so the coding cannot be anchored on it
key <- samp[, c("rid", "era", "band", "domains", "terms", "gap", "stream", "label")]
key$domain_tier <- vapply(strsplit(key$domains, "\\s+"),
                          function(d) paste(sort(unique(ME_TIER[d])), collapse = ""), "")
sem_write_private(key, file.path(ME_PRIVATE, "r1_key.csv"))

set.seed(ME_SEED + 3L)
samp <- samp[sample(nrow(samp)), ]
samp$item <- seq_len(nrow(samp))
blind <- samp[, c("item", "rid", "excerpt")]
blind$r1_invocation <- ""; blind$r2_econ_true <- ""
LEAK <- c("terms", "era", "band", "actor", "url", "label", "domains", "stream")
if (any(LEAK %in% names(blind))) stop("Blind sheet leaks a withheld field.", call. = FALSE)
sem_write_private(blind, file.path(ME_PRIVATE, "r1_sheet.csv"))

bdir <- file.path(ME_PRIVATE, "r1_batches")
unlink(bdir, recursive = TRUE); dir.create(bdir, recursive = TRUE, showWarnings = FALSE)
flat <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
groups <- split(seq_len(nrow(blind)), ceiling(seq_len(nrow(blind)) / BATCH))
for (gname in names(groups)) {
  ix <- groups[[gname]]
  lines <- c(sprintf("# R1/R2 numerator-precision batch %s of %d — %d cards",
                     gname, length(groups), length(ix)), "",
    "Each excerpt is centred where Catholic Social Teaching vocabulary was detected next to an",
    "economic term. The detected term is NOT shown: finding it is part of the test.",
    "",
    "r1_invocation: genuine | mention | false",
    "  genuine — the teaching is actually invoked: quoted, applied, or argued from",
    "  mention — doctrine named but not used (bibliography, programme, book advert, byline, title only)",
    "  false   — no magisterial title or doctrine-specific term is present at all",
    "r2_econ_true: yes | no — is the economic word here a real economic reference, not a homonym",
    "  or a metaphor?",
    "",
    "Return one TSV row per card: item<TAB>rid<TAB>r1_invocation<TAB>r2_econ_true", "")
  for (k in ix) {
    lines <- c(lines, sprintf("### CARD %d | rid=%s", blind$item[k], blind$rid[k]),
               flat(blind$excerpt[k]), "")
  }
  writeLines(lines, file.path(bdir, sprintf("r1_batch_%02d.md", as.integer(gname))), useBytes = FALSE)
}

alloc <- as.data.frame(table(samp$era, samp$band), stringsAsFactors = FALSE)
names(alloc) <- c("era", "outlet_band", "n"); alloc <- alloc[alloc$n > 0, ]
sem_write_shareable(alloc, file.path(ME_OUT, "r1_sample_allocation.csv"))
cat(sprintf("\n== R1 sample built: %d cards -> %s ==\n", nrow(blind), bdir))
cat("Next: code every batch, save output/private/r1_ann1.tsv, then run 22_r1_recompute.R\n")
