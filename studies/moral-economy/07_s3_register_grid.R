#!/usr/bin/env Rscript
# moral-economy STAGE S3 — the DOMAIN x REGISTER grid and the POVERTY split (PROPOSAL_v3 §7, Q2/Q3).
#
# This is the paper's headline table: when religion meets each economic domain, in what VOICE does it
# speak — structural justice, charity, the Church as institution, the cost of religious life, or
# devotional metaphor? The keyword lens structurally cannot answer this (a regex has no register), and
# hand-coding it was v2's bottleneck (inherited kappa 0.46, months of work). The meaning lens produces
# it at scale; Stage V then decides whether the answer is trustworthy.
#
# EVERYTHING THIS SCRIPT EMITS IS PROVISIONAL. The register anchors are v0 (probe centroids), the
# margin is a placeholder, and no number here may be published before Stage V:
#   * v1 register anchors are rebuilt from the coded FIT half of the gold sample;
#   * delta_reg / delta_p are fitted on FIT;
#   * every reported agreement comes from VALIDATE.
# Re-run this script after 09 to produce the publishable version.
#
#   Rscript studies/moral-economy/07_s3_register_grid.R [--anchors=v0|v1] [--boot=2000]
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))

args     <- commandArgs(trailingOnly = TRUE)
AV       <- digikat_cli_value(args, "--anchors", "v0")
NBOOT    <- as.integer(digikat_cli_value(args, "--boot", "2000"))
DELTA_REG <- as.numeric(digikat_cli_value(args, "--delta-reg", "0.5"))   # z units; fitted in Stage V
DELTA_P   <- as.numeric(digikat_cli_value(args, "--delta-p",   "0.5"))

cat(sprintf("=== STAGE S3 — register grid + poverty split (anchors=%s) ===\n", AV))
anch <- readRDS(file.path(ME_SEM, "anchors.rds"))
if (AV == "v1") {
  v1 <- file.path(ME_SEM, "anchors_v1.rds")
  if (!file.exists(v1)) stop("--anchors=v1 needs anchors_v1.rds from 09 (coded FIT half).", call. = FALSE)
  anch <- readRDS(v1)
}
S    <- readRDS(file.path(ME_SEM, "scores_full.rds"))
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
REG  <- anch$registers; PS <- anch$psplit
cat(sprintf("registers: %s\n", paste(REG, collapse = ", ")))

# scores_full.rds was produced with the v0 anchors. Swapping in v1 anchors WITHOUT rescoring would
# silently reuse the v0 numbers — the run would look like it succeeded and change nothing. So v1
# rescores the register/poverty columns over the whole corpus (one DuckDB pass, seconds) and
# recomputes the background median/MAD those z-scores are standardised against.
if (AV == "v1") {
  suppressPackageStartupMessages({ library(DBI); library(duckdb) })
  cat("\n-- rescoring register/poverty anchors with v1 (scores_full.rds holds v0) --\n")
  con <- sem_con(); on.exit(sem_disconnect(con), add = TRUE)
  keep <- c(REG, PS)
  A1 <- anch$A_cen[keep, , drop = FALSE]
  t0 <- Sys.time()
  new <- dbGetQuery(con, sem_score_sql(A1, anch$mu, extra_cols = "chunk_id"))
  cat(sprintf("  rescored %s rows in %.1f s\n", digikat_format_integer(nrow(new)),
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  o <- match(S$chunk_id, new$chunk_id)
  for (nm in keep) S[[paste0("s_", nm)]] <- new[[paste0("s_", nm)]][o]
  bg <- dbGetQuery(con, sprintf(
    "SELECT chunk_id FROM chunks USING SAMPLE %d ROWS (reservoir, %d)", anch$n_background, ME_SEED))
  bi <- match(bg$chunk_id, S$chunk_id)
  for (nm in keep) {
    v <- S[[paste0("s_", nm)]][bi]
    anch$bg_med[nm] <- median(v, na.rm = TRUE)
    anch$bg_mad[nm] <- max(mad(v, na.rm = TRUE), 1e-6)
  }
  cat("  background median/MAD recomputed for the v1 anchors\n")
}

# ------------------------------------------------------------------------------------------------
# 1. Attach scores to the 132,519 LINKED CANDIDATE ROWS.
#    NB one post can be a candidate in several domains, so a row here is a (post x domain) pair and
#    the grid is a per-candidate-row statistic, not a per-post one. Stated in the paper.
# ------------------------------------------------------------------------------------------------
idx <- match(cand$rid, S$chunk_id)
miss <- sum(is.na(idx))
if (miss) cat(sprintf("  !! %d candidate rows have no score row (dropped)\n", miss))
D <- cand[!is.na(idx), c("rid","domain","stream","label","DATE","year","SOURCE_TYPE")]
sidx <- idx[!is.na(idx)]
zof <- function(nm) (S[[paste0("s_", nm)]][sidx] - anch$bg_med[nm]) / anch$bg_mad[nm]
Z <- sapply(REG, zof); colnames(Z) <- REG
cat(sprintf("scored candidate rows: %s\n", digikat_format_integer(nrow(D))))

# ------------------------------------------------------------------------------------------------
# 2. REGISTER ASSIGNMENT — margin rule, not argmax.
#    Anchors are collinear (S1 gram up to 0.79), so a bare argmax over near-parallel directions
#    allocates by noise. A row is assigned only when its top register beats the runner-up by
#    delta_reg; otherwise it is 'ambiguous' — reported as its own column and NEVER redistributed,
#    which is CODEBOOK.md's "the remainder is never silently dropped" rule applied to the machine.
# ------------------------------------------------------------------------------------------------
ord  <- t(apply(Z, 1, function(r) order(r, decreasing = TRUE)[1:2]))
top1 <- REG[ord[, 1]]
marg <- Z[cbind(seq_len(nrow(Z)), ord[, 1])] - Z[cbind(seq_len(nrow(Z)), ord[, 2])]
D$register <- ifelse(marg >= DELTA_REG, top1, "ambiguous")
D$margin   <- round(marg, 3)
cat(sprintf("\nambiguous share at delta_reg=%.2f: %.1f%%\n", DELTA_REG, 100 * mean(D$register == "ambiguous")))
print(round(prop.table(table(D$register)), 3))

# ------------------------------------------------------------------------------------------------
# 3. THE GRID, with stratified bootstrap CIs (resampled WITHIN stream x platform, so the interval
#    reflects the design rather than assuming iid rows).
# ------------------------------------------------------------------------------------------------
cat("\n-- domain x register grid (provisional) --\n")
LEV <- c(REG, "ambiguous")
D$strat <- paste(D$stream, D$SOURCE_TYPE, sep = "|")
grid_of <- function(rows) {
  t <- table(factor(D$domain[rows], levels = sort(unique(D$domain))),
             factor(D$register[rows], levels = LEV))
  prop.table(t, 1)
}
G <- grid_of(seq_len(nrow(D)))
print(round(G, 3))

set.seed(ME_SEED)
strata <- split(seq_len(nrow(D)), D$strat)
boot <- array(NA_real_, c(nrow(G), ncol(G), NBOOT), dimnames = list(rownames(G), colnames(G), NULL))
for (b in seq_len(NBOOT)) {
  rows <- unlist(lapply(strata, function(ix) sample(ix, length(ix), replace = TRUE)), use.names = FALSE)
  boot[, , b] <- grid_of(rows)
}
lo <- apply(boot, 1:2, quantile, .025, na.rm = TRUE)
hi <- apply(boot, 1:2, quantile, .975, na.rm = TRUE)

grid_long <- do.call(rbind, lapply(rownames(G), function(d) data.frame(
  domain = d, register = colnames(G), share = round(as.numeric(G[d, ]), 4),
  ci_lo = round(as.numeric(lo[d, ]), 4), ci_hi = round(as.numeric(hi[d, ]), 4),
  n = as.integer(table(D$domain)[d]), stringsAsFactors = FALSE)))

# the paper's claim in one line: justice share by domain
js <- grid_long[grid_long$register == "justice", ]
js <- js[order(-js$share), ]
cat("\n-- justice share by domain (H2: justice for work, charity/devotion for the poor) --\n")
print(data.frame(domain = js$domain, justice = sprintf("%.1f%% [%.1f, %.1f]", 100 * js$share,
                 100 * js$ci_lo, 100 * js$ci_hi)), row.names = FALSE)

# by stream (the 2024 collection seam is never compared across, only within)
grid_stream <- do.call(rbind, lapply(unique(D$stream), function(st) {
  rows <- which(D$stream == st); g <- grid_of(rows)
  do.call(rbind, lapply(rownames(g), function(d) data.frame(
    stream = st, domain = d, register = colnames(g), share = round(as.numeric(g[d, ]), 4),
    n = sum(D$stream == st & D$domain == d), stringsAsFactors = FALSE)))
}))

# ------------------------------------------------------------------------------------------------
# 4. THE POVERTY SPLIT (Q3/H3) — margin band, on THREE populations.
#    A two-anchor argmax structurally cannot produce CODEBOOK ax5's 'mixed', so the band produces it.
#    The pilot's ~73/27 came from the top-800 of a hand-written anchor inside a 20k sample — not the
#    poverty domain. Reporting all three populations pre-empts a "the number moved" referee.
# ------------------------------------------------------------------------------------------------
cat("\n-- poverty split (provisional; three populations) --\n")
z_ec <- (S$s_economic_poverty - anch$bg_med["economic_poverty"]) / anch$bg_mad["economic_poverty"]
z_dc <- (S$s_doctrinal_poverty - anch$bg_med["doctrinal_poverty"]) / anch$bg_mad["doctrinal_poverty"]
split_of <- function(rows) {
  dz <- z_ec[rows] - z_dc[rows]
  f <- ifelse(dz >= DELTA_P, "economic_poverty", ifelse(dz <= -DELTA_P, "doctrinal_poverty", "mixed"))
  prop.table(table(factor(f, levels = ME_PSPLIT)))
}
kw_pov  <- S$chunk_id %in% unique(cand$rid[cand$domain == "poverty_social"])
k_pov   <- sum(kw_pov)
sem_pov <- rank(-S$s_poverty_social, ties.method = "first") <= k_pov   # matched volume
pops <- list(`keyword-linked poverty` = which(kw_pov),
             `semantic poverty (matched volume)` = which(sem_pov),
             `intersection` = which(kw_pov & sem_pov))
psplit <- do.call(rbind, lapply(names(pops), function(nm) {
  p <- split_of(pops[[nm]])
  data.frame(population = nm, n = length(pops[[nm]]),
             economic = round(as.numeric(p["economic_poverty"]), 4),
             doctrinal = round(as.numeric(p["doctrinal_poverty"]), 4),
             mixed = round(as.numeric(p["mixed"]), 4), stringsAsFactors = FALSE)
}))
print(psplit, row.names = FALSE)
cat(sprintf("  (pilot reported ~73%% doctrinal / 27%% economic on the top-800 of a hand anchor in a 20k sample)\n"))
cat(sprintf("  binary fallback (economic vs rest), keyword-linked poverty: %.1f%% / %.1f%%\n",
            100 * psplit$economic[1], 100 * (1 - psplit$economic[1])))

# ------------------------------------------------------------------------------------------------
# 5. WRITE — all tracked files carry the provisional flag in their manifest.
# ------------------------------------------------------------------------------------------------
grid_long$provisional <- TRUE; grid_stream$provisional <- TRUE; psplit$provisional <- TRUE
sem_write_shareable(grid_long,   file.path(ME_SEM, sprintf("register_grid_%s.csv", AV)), suppress = TRUE)
sem_write_shareable(grid_stream, file.path(ME_SEM, sprintf("register_grid_by_stream_%s.csv", AV)), suppress = TRUE)
sem_write_shareable(psplit,      file.path(ME_SEM, sprintf("poverty_split_%s.csv", AV)))
saveRDS(D[, c("rid","domain","register","margin","stream","label","year")],
        file.path(ME_SEM, sprintf("candidate_registers_%s.rds", AV)))

digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/07_s3_register_grid.R",
  inputs = list(anchors = sprintf("output/semantic/anchors%s.rds", if (AV == "v1") "_v1" else ""),
                scores = "output/semantic/scores_full.rds"),
  outputs = list(grid = sprintf("output/semantic/register_grid_%s.csv", AV)),
  extra = list(anchor_version = AV, delta_reg = DELTA_REG, delta_p = DELTA_P, n_boot = NBOOT,
               n_candidate_rows = nrow(D),
               ambiguous_share = round(mean(D$register == "ambiguous"), 4),
               provisional = identical(AV, "v0"),
               note = if (AV == "v0")
                 "PROVISIONAL — probe-centroid register anchors, placeholder margins. Not publishable before Stage V."
                 else "Anchors and margins fitted on the Stage V FIT half; agreement reported on VALIDATE.")
), file.path(ME_SEM, sprintf("s3_manifest_%s.json", AV)))

cat("\n== S3 complete ==\n")
cat(sprintf("  grid -> output/semantic/register_grid_%s.csv (tracked, PROVISIONAL)\n", AV))
cat("Next: 08_build_gold_sheet.R\n")
