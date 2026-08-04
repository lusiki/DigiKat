#!/usr/bin/env Rscript
# moral-economy STAGE S2 — FULL-CORPUS SCORING + the cross-lens gap audit (PROPOSAL_v3 §7).
#
# Scores all 710,307 posts against every calibrated anchor in ONE DuckDB pass, then asks the study's
# first question three ways and reports where the two lenses disagree.
#
# WHAT S1 FORCED US TO CHANGE HERE:
#   S1 measured each anchor's separation (AUC 0.73-0.92). Good enough to RANK posts, not good enough
#   to draw an unsupervised line and call everything above it "about poverty" — at a 1-5% base rate,
#   a threshold catching 80% of known seeds admits 25-56% of the corpus. So this script:
#     * stores RAW SCORES, never binary labels (no operating point is locked in before validation);
#     * reports coverage under THREE operating rules, not one, and shows how much the answer moves;
#     * compares the lenses at MATCHED VOLUME (top-k, k = that domain's keyword n_linked) — which asks
#       WHICH posts each lens picks rather than how many, the only unsupervised comparison that is not
#       an artifact of an arbitrary cut.
#   The operating point itself is fitted against human labels in Stage V, not here.
#
# READ-ONLY on the store and Stage A. Never opens the master.
#   Rscript studies/moral-economy/06_s2_corpus_scoring.R [--engine=sql|r]
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb) })
source(here::here("studies/moral-economy/sem_lib.R"))

args   <- commandArgs(trailingOnly = TRUE)
ENGINE <- digikat_cli_value(args, "--engine", "sql")
SCORES <- file.path(ME_SEM, "scores_full.rds")

cat("=== STAGE S2 — full-corpus scoring + gap audit ===\n")
anch <- readRDS(file.path(ME_SEM, "anchors.rds"))
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
kw   <- read.csv(file.path(ME_OUT, "stageA_domain_stats.csv"), fileEncoding = "UTF-8",
                 stringsAsFactors = FALSE)
A <- anch$A_cen; mu <- anch$mu; dom <- anch$domains; dec <- anch$decoys
cat(sprintf("anchors: %d (%d domain, %d decoy, %d register, %d poverty)\n",
            nrow(A), length(dom), length(dec), length(anch$registers), length(anch$psplit)))

con <- sem_con(); on.exit(sem_disconnect(con), add = TRUE)
cat("\n-- gates --\n")
sem_gate_id_mapping(con, cand, n = 500L)
sem_gate_unit_norm(con)

# ------------------------------------------------------------------------------------------------
# 1. ONE PASS OVER THE CORPUS
# ------------------------------------------------------------------------------------------------
fp <- list(anchors = digikat_hash_object(list(A = A, mu = mu)),
           store = file.info(ME_STORE)$size, engine = ENGINE)
S <- sem_checkpoint(SCORES, fp, function() {
  cat("\n-- scoring all posts --\n"); t0 <- Sys.time()
  if (ENGINE == "sql") {
    out <- dbGetQuery(con, sem_score_sql(A, mu, length_col = TRUE))
  } else {
    rng <- dbGetQuery(con, "SELECT min(chunk_id) lo, max(chunk_id) hi FROM chunks")
    acc <- list(); k <- 0L; a <- rng$lo
    while (a <= rng$hi) {
      b <- a + ME_BATCH - 1L; k <- k + 1L
      q <- dbGetQuery(con, sprintf(
        "SELECT chunk_id, platform, data_source, date, length(text) AS text_chars, embedding
         FROM chunks WHERE chunk_id BETWEEN %d AND %d", a, b))
      if (nrow(q)) {
        sc <- sem_score_r(q$embedding, A, mu)
        acc[[k]] <- cbind(q[, c("chunk_id","platform","data_source","date","text_chars")],
                          as.data.frame(sc))
      }
      a <- b + 1L
    }
    out <- do.call(rbind, acc)
    names(out)[-(1:5)] <- paste0("s_", rownames(A))
  }
  cat(sprintf("  %s rows in %.1f s (engine=%s)\n", digikat_format_integer(nrow(out)),
              as.numeric(difftime(Sys.time(), t0, units = "secs")), ENGINE))
  out
}, label = "scores_full.rds")
cat(sprintf("scores: %s rows x %d anchors\n", digikat_format_integer(nrow(S)), nrow(A)))

# G3 — the SQL and R implementations must agree. Anchors are computed in R in double precision from
# FLOAT-rounded stored vectors and cast back to FLOAT[1024]; without this check that round-trip could
# introduce a silent, invisible bias in every published number.
cat("\n-- G3: SQL vs R agreement --\n")
chk <- dbGetQuery(con, "SELECT chunk_id, embedding FROM chunks USING SAMPLE 5000 ROWS (reservoir, 20260804)")
R_ref <- sem_score_r(chk$embedding, A, mu)
idx <- match(chk$chunk_id, S$chunk_id)
d3 <- max(abs(as.matrix(S[idx, paste0("s_", rownames(A))]) - R_ref))
sem_gate_report("G3 SQL vs R", d3 < 1e-4, sprintf("max |SQL - R| = %.3e", d3))

sc <- function(d) S[[paste0("s_", d)]]

# ------------------------------------------------------------------------------------------------
# 2. COVERAGE — three operating rules, reported side by side.
#    None is privileged: S1 showed the unsupervised operating point is not identifiable, so the
#    honest presentation is the SPREAD across rules, with Stage V picking the one that matches
#    human coding. A ranking that survives all three is robust; one that flips is method-dependent.
# ------------------------------------------------------------------------------------------------
cat("\n-- coverage under three operating rules --\n")
kw_linked <- setNames(kw$n_linked, kw$domain)
N <- nrow(S)

# (a) winner-take-all among domains, gated by the post-centroid decoys
best   <- max.col(as.matrix(S[, paste0("s_", dom)]))
bestv  <- as.matrix(S[, paste0("s_", dom)])[cbind(seq_len(N), best)]
decoyv <- do.call(pmax, lapply(paste0("s_", dec), function(cc) S[[cc]]))
wta    <- ifelse(bestv > decoyv, dom[best], NA_character_)
cov_wta <- table(factor(wta, levels = dom))

# (b) robust z >= 3 against the S1 background distribution
z_of <- function(d) (sc(d) - anch$bg_med[d]) / anch$bg_mad[d]
cov_z3 <- sapply(dom, function(d) sum(z_of(d) >= 3))

# (c) recall-anchored tau at rho = 0.80 (provisional; S1 showed it runs loose)
cov_tau <- sapply(dom, function(d) sum(sc(d) >= anch$tau[d, "tau_80"]))

cov <- data.frame(
  domain = dom,
  kw_linked = as.integer(kw_linked[dom]),
  kw_rank = rank(-as.integer(kw_linked[dom]), ties.method = "min"),
  wta_n = as.integer(cov_wta[dom]), z3_n = as.integer(cov_z3[dom]), tau80_n = as.integer(cov_tau[dom]),
  stringsAsFactors = FALSE)
cov$wta_rank   <- rank(-cov$wta_n, ties.method = "min")
cov$z3_rank    <- rank(-cov$z3_n, ties.method = "min")
cov$tau80_rank <- rank(-cov$tau80_n, ties.method = "min")
cov$wta_pct_of_corpus <- round(100 * cov$wta_n / N, 2)
cov <- cov[order(cov$kw_rank), ]
print(cov[, c("domain","kw_linked","kw_rank","wta_n","wta_rank","z3_n","z3_rank","tau80_n","tau80_rank")],
      row.names = FALSE)

rho_wta <- cor(cov$kw_rank, cov$wta_rank,   method = "spearman")
rho_z3  <- cor(cov$kw_rank, cov$z3_rank,    method = "spearman")
rho_tau <- cor(cov$kw_rank, cov$tau80_rank, method = "spearman")
cat(sprintf("\n  Spearman vs keyword rank:  WTA %+.3f | z>=3 %+.3f | tau80 %+.3f\n", rho_wta, rho_z3, rho_tau))
cat(sprintf("  rank spread across rules (max |rank_i - rank_j| per domain): %d\n",
            max(apply(cov[, c("wta_rank","z3_rank","tau80_rank")], 1, function(r) diff(range(r))))))

# bootstrap CI for the headline (WTA) rank correlation — n = 11 domains, so the CI is wide by design
set.seed(ME_SEED)
boot_rho <- replicate(2000, { i <- sample(nrow(cov), replace = TRUE)
  suppressWarnings(cor(cov$kw_rank[i], cov$wta_rank[i], method = "spearman")) })
cat(sprintf("  WTA rho bootstrap 95%% CI over domains: [%+.3f, %+.3f] (n=11 domains — wide by construction)\n",
            quantile(boot_rho, .025, na.rm = TRUE), quantile(boot_rho, .975, na.rm = TRUE)))

# ------------------------------------------------------------------------------------------------
# 3. STREAM x PLATFORM CONDITIONING.
#    MEMORY.md: data_source is a collection seam (~2024), and the streams differ sharply in platform
#    mix, so "conditioned on stream" alone is not enough — rho is computed WITHIN cells and then
#    post-stratified to the overall platform mix.
# ------------------------------------------------------------------------------------------------
cat("\n-- rank agreement within platform x stream cells --\n")
S$wta <- wta
cells <- table(S$platform, S$data_source)
big <- which(cells >= 20000, arr.ind = TRUE)
cell_rows <- list()
for (i in seq_len(nrow(big))) {
  pl <- rownames(cells)[big[i, 1]]; ds <- colnames(cells)[big[i, 2]]
  sub <- S[S$platform == pl & S$data_source == ds, ]
  n_d <- table(factor(sub$wta, levels = dom))
  r <- suppressWarnings(cor(cov$kw_rank[match(dom, cov$domain)],
                            rank(-as.integer(n_d), ties.method = "min"), method = "spearman"))
  cell_rows[[i]] <- data.frame(platform = pl, data_source = ds, n_posts = nrow(sub),
                               n_economic = sum(!is.na(sub$wta)), rho_vs_keyword = round(r, 3),
                               stringsAsFactors = FALSE)
}
cellsdf <- do.call(rbind, cell_rows)
cellsdf <- cellsdf[order(-cellsdf$n_posts), ]
print(cellsdf, row.names = FALSE)
cat(sprintf("  rho range across cells: [%+.3f, %+.3f]  (post-stratified: %+.3f)\n",
            min(cellsdf$rho_vs_keyword), max(cellsdf$rho_vs_keyword),
            sum(cellsdf$rho_vs_keyword * cellsdf$n_posts) / sum(cellsdf$n_posts)))

# ------------------------------------------------------------------------------------------------
# 4. THE GAP AUDIT AT MATCHED VOLUME.
#    For each domain take the top k semantic posts where k = that domain's keyword n_linked, so both
#    lenses select exactly the same NUMBER of posts and the only question is WHICH ones.
#    NB: these are CANDIDATE gaps. A raw gap is not a measured gap until humans confirm the semantic
#    picks are on-topic — 08 draws hand-check strata from both sides for exactly that purpose.
# ------------------------------------------------------------------------------------------------
cat("\n-- gap audit at matched volume --\n")
gap_rows <- list(); gap_ids <- list()
for (d in dom) {
  k <- kw_linked[[d]]
  kw_set  <- unique(cand$rid[cand$domain == d])
  sem_set <- S$chunk_id[order(sc(d), decreasing = TRUE)[seq_len(k)]]
  inter <- length(intersect(kw_set, sem_set))
  gap_rows[[d]] <- data.frame(
    domain = d, k = k, overlap = inter,
    agreement = round(inter / k, 4),
    recall_gap = round(1 - inter / k, 4),      # semantic-picked, keyword-missed (candidates)
    precision_gap = round(1 - inter / length(kw_set), 4),
    stringsAsFactors = FALSE)
  gap_ids[[d]] <- list(sem_only = setdiff(sem_set, kw_set), kw_only = setdiff(kw_set, sem_set))
}
gaps <- do.call(rbind, gap_rows)
print(gaps, row.names = FALSE)
cat(sprintf("  mean agreement at matched volume: %.1f%%\n", 100 * mean(gaps$agreement)))

# 2x2 contingency per domain (counts only — shareable)
cont <- do.call(rbind, lapply(dom, function(d) {
  k <- kw_linked[[d]]
  kw_set <- unique(cand$rid[cand$domain == d])
  sem_set <- S$chunk_id[order(sc(d), decreasing = TRUE)[seq_len(k)]]
  both <- length(intersect(kw_set, sem_set))
  data.frame(domain = d, kw_yes_sem_yes = both, kw_yes_sem_no = length(kw_set) - both,
             kw_no_sem_yes = k - both, kw_no_sem_no = N - length(kw_set) - (k - both),
             stringsAsFactors = FALSE)
}))

# ------------------------------------------------------------------------------------------------
# 5. TRUNCATION SENSITIVITY — 30% of posts exceed the 4,000-char embed limit. If the coverage
#    ranking moves on the short-post subcorpus, that IS the size of the limitation.
# ------------------------------------------------------------------------------------------------
cat("\n-- truncation sensitivity --\n")
S$truncated <- S$text_chars > ME_TRUNC
cat(sprintf("  truncated posts: %s of %s (%.1f%%)\n", digikat_format_integer(sum(S$truncated)),
            digikat_format_integer(N), 100 * mean(S$truncated)))
trunc_by <- as.data.frame.matrix(round(100 * prop.table(table(S$platform, S$truncated), 1), 1))
names(trunc_by) <- c("pct_short", "pct_truncated")
trunc_by$platform <- rownames(trunc_by)
print(trunc_by[order(-trunc_by$pct_truncated), c("platform","pct_truncated")], row.names = FALSE)

short <- S[!S$truncated, ]
n_short <- table(factor(short$wta, levels = dom))
rho_short <- cor(cov$kw_rank[match(dom, cov$domain)],
                 rank(-as.integer(n_short), ties.method = "min"), method = "spearman")
cat(sprintf("  coverage rho on the <=%d-char subcorpus: %+.3f (full corpus: %+.3f)\n",
            ME_TRUNC, rho_short, rho_wta))

trunc_dom <- data.frame(domain = dom,
                        pct_truncated = round(100 * sapply(dom, function(d)
                          mean(S$truncated[!is.na(S$wta) & S$wta == d])), 1),
                        rank_full = cov$wta_rank[match(dom, cov$domain)],
                        rank_short = rank(-as.integer(n_short), ties.method = "min"),
                        stringsAsFactors = FALSE)

# ------------------------------------------------------------------------------------------------
# 6. WRITE
# ------------------------------------------------------------------------------------------------
sem_write_shareable(cov, file.path(ME_SEM, "coverage_ranking_v2.csv"))
sem_write_shareable(gaps, file.path(ME_SEM, "gap_summary.csv"))
sem_write_shareable(cont, file.path(ME_SEM, "gap_matrix.csv"))
sem_write_shareable(cellsdf, file.path(ME_SEM, "coverage_by_platform_stream.csv"))
sem_write_shareable(trunc_dom, file.path(ME_SEM, "truncation_by_domain.csv"))
saveRDS(gap_ids, file.path(ME_SEM, "gap_ids.rds"))   # gitignored; feeds 08's hand-check strata

digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/06_s2_corpus_scoring.R",
  inputs = list(anchors = "output/semantic/anchors.rds",
                stageA = digikat_file_metadata(file.path(ME_OUT, "stageA_candidates.rds"))),
  outputs = list(scores = "output/semantic/scores_full.rds",
                 coverage = "output/semantic/coverage_ranking_v2.csv"),
  extra = list(
    n_scored = N, engine = ENGINE, g3_max_abs_diff = signif(d3, 3),
    spearman_wta = round(rho_wta, 4), spearman_z3 = round(rho_z3, 4), spearman_tau80 = round(rho_tau, 4),
    spearman_wta_ci = round(unname(quantile(boot_rho, c(.025, .975), na.rm = TRUE)), 4),
    mean_agreement_matched_volume = round(mean(gaps$agreement), 4),
    pct_truncated = round(100 * mean(S$truncated), 2),
    spearman_short_subcorpus = round(rho_short, 4),
    operating_point = "NOT FIXED — three rules reported; the published cut is fitted on Stage V FIT half")
), file.path(ME_SEM, "s2_manifest.json"))

cat("\n== S2 complete ==\n")
cat("  scores      -> output/semantic/scores_full.rds (gitignored)\n")
cat("  coverage    -> output/semantic/coverage_ranking_v2.csv (tracked)\n")
cat("  gaps        -> output/semantic/gap_summary.csv, gap_matrix.csv (tracked)\n")
cat("Next: 07_s3_register_grid.R\n")
