#!/usr/bin/env Rscript
# R/semantic/16_wiki.R  —  TOP-LEVEL cluster analysis + an LLM-written "wiki page" per cluster.
#
# WHAT THIS DOES (two stages):
#   1. Auto-tunes HDBSCAN's minPts to land in a TARGET cluster-count range (there is no direct
#      "give me N clusters" knob in density-based clustering — minPts is the only lever, and it's
#      indirect, so we binary-search it instead of hand-tuning by trial and error).
#   2. For each cluster, sends a sample of its posts to Claude (via ellmer) and asks for a short
#      name + description — replacing the crude word-frequency labels from 15_clusters.R with an
#      actual readable summary (the "LLM wiki" pattern: model reads raw examples, writes the label,
#      rather than a human or a keyword heuristic doing it).
#
# PREREQUISITE: ANTHROPIC_API_KEY must be set (environment variable or ~/.Renviron). This step
# sends a SAMPLE of post text (not the whole corpus) to Anthropic's API — a real data-handling
# choice, different from the fully-local embedding step. Confirm this is acceptable before running
# at scale; start with the default target_clusters to keep the number of API calls small.
#
# Run:  Rscript R/semantic/16_wiki.R
suppressPackageStartupMessages({
  library(here); library(DBI); library(duckdb); library(dbscan); library(uwot)
  library(ggplot2); library(dplyr); library(ellmer)
})
source(here::here("R/theme_digikat.R"))

# ============================================================================================
# STAGE 1 — sample + auto-tune minPts to hit a TARGET cluster count range
# ============================================================================================
dk_cluster_sample <- function(n = 5000L, seed = 20260709L,
                              store_path = here::here("data/semantic/digikat.ragnar.duckdb")) {
  con <- dbConnect(duckdb::duckdb(), dbdir = store_path, read_only = TRUE, array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  dbGetQuery(con, sprintf(
    "SELECT doc_id, platform, date, data_source, text, embedding FROM chunks
     USING SAMPLE %d ROWS (reservoir, %d)", as.integer(n), as.integer(seed)))
}

# Binary-search minPts so the resulting cluster count falls in [lo, hi]. HDBSCAN's relationship
# between minPts and cluster count is monotonic-ish (higher minPts -> fewer clusters) but noisy,
# so this is a bounded search, not an exact solver — it stops at max_iter and returns its BEST
# attempt (closest to the target range) if it never lands exactly inside [lo, hi].
dk_autotune_clusters <- function(samp, target_lo = 10L, target_hi = 20L,
                                 minpts_range = c(10L, 80L), max_iter = 8L, n_components = 12L) {
  set.seed(20260709L)
  red <- uwot::umap(samp$embedding, n_components = n_components, n_neighbors = 15,
                    min_dist = 0.0, metric = "cosine")
  lo_mp <- minpts_range[1]; hi_mp <- minpts_range[2]
  best <- NULL
  for (i in seq_len(max_iter)) {
    mp <- round((lo_mp + hi_mp) / 2)
    cl <- dbscan::hdbscan(red, minPts = mp)
    k <- length(unique(cl$cluster[cl$cluster != 0]))
    cat(sprintf("  [%d/%d] minPts=%d -> %d clusters\n", i, max_iter, mp, k))
    dist_to_target <- if (k < target_lo) target_lo - k else if (k > target_hi) k - target_hi else 0L
    if (is.null(best) || dist_to_target < best$dist) best <- list(mp = mp, cl = cl, k = k, dist = dist_to_target)
    if (k >= target_lo && k <= target_hi) break               # landed in range — stop early
    if (k < target_lo) hi_mp <- mp - 1L else lo_mp <- mp + 1L  # too few clusters -> need SMALLER minPts (opposite of k-means intuition)
    if (lo_mp > hi_mp) break
  }
  cat(sprintf("Selected minPts=%d -> %d clusters (target was %d-%d)\n", best$mp, best$k, target_lo, target_hi))
  samp$cluster <- best$cl$cluster
  attr(samp, "minPts") <- best$mp
  samp
}

# ============================================================================================
# STAGE 2 — LLM wiki: one Claude call per cluster, reading a sample of its actual posts
# ============================================================================================
dk_wiki_prompt <- function(posts) {
  numbered <- paste(sprintf("%d. %s", seq_along(posts), substr(posts, 1, 300)), collapse = "\n\n")
  paste0(
    "Ovo je uzorak objava iz hrvatskog medijskog korpusa (katolička/vjerska tematika), ",
    "grupiranih zajedno jer su semantički slične. Pročitaj ih i odgovori u TOČNO ovom formatu:\n\n",
    "NASLOV: <kratak naslov teme, 3-7 riječi>\n",
    "OPIS: <2-3 rečenice o čemu je ova skupina objava, na hrvatskom>\n\n",
    "Objave:\n\n", numbered)
}

dk_wiki_generate <- function(samp, cluster_id, n_sample = 20L, seed_offset = 0L) {
  rows <- samp[samp$cluster == cluster_id, ]
  set.seed(20260709L + seed_offset)
  posts <- rows$text[sample.int(nrow(rows), min(n_sample, nrow(rows)))]
  chat <- ellmer::chat_anthropic(model = "claude-sonnet-5")
  resp <- chat$chat(dk_wiki_prompt(posts))
  title <- sub(".*NASLOV:\\s*(.*?)\\n.*", "\\1", resp)
  desc  <- sub(".*OPIS:\\s*(.*)", "\\1", resp)
  list(cluster = cluster_id, n = nrow(rows), title = trimws(title), description = trimws(desc),
       top_platform = names(sort(table(rows$platform), decreasing = TRUE))[1])
}

# ============================================================================================
# run as a script
# ============================================================================================
if (!interactive() || sys.nframe() == 0L) {
  if (!nzchar(Sys.getenv("ANTHROPIC_API_KEY")))
    stop("ANTHROPIC_API_KEY is not set. Set it (env var or ~/.Renviron) before running the wiki step.\n",
         "  The clustering itself (stage 1) doesn't need it — only the LLM summaries (stage 2) do.")

  cat("Sampling 5000 posts ...\n")
  samp <- dk_cluster_sample(n = 5000L)

  cat("Auto-tuning minPts for a TOP-LEVEL cluster count (target: 10-20) ...\n")
  samp <- dk_autotune_clusters(samp, target_lo = 10L, target_hi = 20L)

  sizes <- sort(table(samp$cluster[samp$cluster != 0]), decreasing = TRUE)
  cat("\nCluster sizes:", paste(sizes, collapse = ", "), "\n")
  cat("Noise:", sum(samp$cluster == 0), sprintf("(%.0f%%)\n", 100 * mean(samp$cluster == 0)))

  cat("\nGenerating LLM wiki entries (one Claude call per cluster) ...\n")
  cluster_ids <- as.integer(names(sizes))
  wiki <- lapply(seq_along(cluster_ids), function(i) {
    cid <- cluster_ids[i]
    cat(sprintf("  [%d/%d] cluster %d (n=%d) ...\n", i, length(cluster_ids), cid, sizes[as.character(cid)]))
    tryCatch(dk_wiki_generate(samp, cid, seed_offset = i),
             error = function(e) list(cluster = cid, n = sizes[as.character(cid)],
                                      title = "(GREŠKA)", description = conditionMessage(e),
                                      top_platform = NA))
  })
  wiki_df <- do.call(rbind, lapply(wiki, as.data.frame))
  wiki_df <- wiki_df[order(-wiki_df$n), ]

  out_csv <- here::here("R/semantic/wiki_clusters.csv")
  write.csv(wiki_df, out_csv, row.names = FALSE, fileEncoding = "UTF-8")
  saveRDS(samp, here::here("R/semantic/wiki_sample.rds"))

  cat("\n================ CORPUS WIKI (top-level clusters) ================\n\n")
  for (i in seq_len(nrow(wiki_df))) {
    cat(sprintf("## %s  (n=%d, %s)\n%s\n\n", wiki_df$title[i], wiki_df$n[i],
                wiki_df$top_platform[i], wiki_df$description[i]))
  }
  cat("Saved table:", out_csv, "\n")
  cat("Saved sample+clusters:", here::here("R/semantic/wiki_sample.rds"), "\n")
}
