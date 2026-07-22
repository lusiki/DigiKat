#!/usr/bin/env Rscript
# R/semantic/15_clusters.R  —  CLUSTER ANALYSIS on the meaning-search store.
#
# WHAT THIS DOES: instead of YOU typing a query, this lets the DATA tell you what topics
# exist. It samples posts, groups the ones with similar meaning automatically (HDBSCAN —
# a density-based clusterer), then shows you the most common WORDS in each group so you can
# read off what each cluster is "about". This is how you find themes BEYOND the fixed
# 16-category dictionary (the roadmap's core Level-3 promise).
#
# WHY HDBSCAN (not k-means): k-means forces EVERY post into some cluster, even ones that
# don't belong anywhere ("Grupna mobilnost učenika iz Malage" landing in an abortion-topic
# search in Test 3 is exactly that problem). HDBSCAN allows a NOISE label (-1) for posts
# that don't clearly belong to any dense group — honest about the fuzzy middle.
#
# WHY A SAMPLE: HDBSCAN on 710k x 1024-dim vectors is heavy; a stratified sample (default
# 5000 posts) is enough to reveal cluster structure. Raise n if you want more granularity.
#
# Run:  Rscript R/semantic/15_clusters.R
suppressPackageStartupMessages({
  library(here); library(DBI); library(duckdb); library(dbscan); library(uwot)
  library(ggplot2); library(dplyr)
})
source(here::here("R/theme_digikat.R"))
source(here::here("R/semantic/12_query.R"))    # for dk_umap()-style DB access patterns

# --- 1. sample posts + their embeddings ---------------------------------------------------------
dk_cluster_sample <- function(n = 5000L, seed = 20260709L,
                              store_path = here::here("data/semantic/digikat.ragnar.duckdb")) {
  con <- dbConnect(duckdb::duckdb(), dbdir = store_path, read_only = TRUE, array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  dbGetQuery(con, sprintf(
    "SELECT doc_id, platform, date, data_source, text, embedding FROM chunks
     USING SAMPLE %d ROWS (reservoir, %d)", as.integer(n), as.integer(seed)))
}

# --- 2. cluster with HDBSCAN on a UMAP-REDUCED embedding (not the raw 1024-dim vectors).
# WHY: in very high dimensions, distances between points become nearly uniform (the "curse of
# dimensionality") — HDBSCAN's density-based logic needs real near/far contrast to find groups,
# and at 1024 dims it mostly can't (empirically: 2 tiny clusters, 76% noise, on structure that
# is clearly visible once projected to 2D). Reducing to ~10-15 dims with UMAP first preserves
# the neighborhood structure that matters while giving HDBSCAN a space where density is meaningful.
# This reduced embedding is ALSO used for the picture, so what you see IS what got clustered.
dk_cluster_run <- function(samp, min_pts = 25L, n_components = 12L) {
  mat <- samp$embedding
  set.seed(20260709L)
  red <- uwot::umap(mat, n_components = n_components, n_neighbors = 15, min_dist = 0.0, metric = "cosine")
  cl <- dbscan::hdbscan(red, minPts = min_pts)
  samp$cluster <- cl$cluster                      # 0 = noise (no clear cluster)
  samp$cluster_prob <- cl$membership_prob
  attr(samp, "hdbscan") <- cl
  attr(samp, "umap_reduced") <- red                # reuse for the 2D plot — no need to re-run UMAP
  samp
}

# --- 3. name each cluster by its most DISTINCTIVE words — relative frequency (frequency INSIDE
# this cluster vs frequency in the REST of the sample), not raw term-frequency. Raw counts just
# surface generic high-frequency words ("nije", "samo", "kada") in every cluster; comparing
# against the rest of the sample surfaces words that are special to THIS group. Still simple,
# transparent term-counting — not a TF-IDF library — but the ratio is what makes labels readable.
.hr_stopwords <- c("i","u","na","je","se","da","za","su","od","do","ali","ili","kao","koji",
                   "koja","koje","ne","neće","biti","ima","kako","sam","sa","po","iz","ovo",
                   "nije","nisam","samo","kada","bila","bio","rekla","rekao","uvijek","nego",
                   "https","http","www","com","hr","the","a","to","of","in","and","is","for","on")
# .looks_like_a_word: crude but effective real-word filter for noisy social text (usernames,
# hashtag mashups, base64-ish fragments — e.g. "cicgpkvh", "hranazadusuyt" from the first pass).
# Croatian/English words have vowels roughly every few letters; require a vowel, reasonable
# length, and no long consonant runs (a cheap proxy that kills most garbage tokens).
.looks_like_a_word <- function(w) {
  nchar(w) <= 15 &
    grepl("[aeiouàáâãäåèéêëìíîïòóôõöùúûüAEIOUČĆŽŠĐčćžšđ]", w) &
    !grepl("[^aeiouyščćžđ]{5,}", w)                            # 5+ consonants in a row = not a word
}
.tokenize_hr <- function(txt) {
  words <- unlist(strsplit(tolower(txt), "[^\\p{L}]+", perl = TRUE))
  words <- words[nchar(words) > 3 & !words %in% .hr_stopwords]
  words[vapply(words, .looks_like_a_word, logical(1))]
}
dk_cluster_label <- function(samp, cluster_id, top_n = 8L, min_count = 4L) {
  in_words  <- .tokenize_hr(samp$text[samp$cluster == cluster_id])
  out_words <- .tokenize_hr(samp$text[samp$cluster != cluster_id])
  in_tbl  <- table(in_words);  in_rate  <- in_tbl  / max(length(in_words), 1)
  out_tbl <- table(out_words); out_rate <- out_tbl / max(length(out_words), 1)
  in_tbl <- in_tbl[in_tbl >= min_count]                      # drop words too rare to trust the ratio
  if (!length(in_tbl)) return("(nedovoljno teksta)")
  out_rate_for <- function(w) if (w %in% names(out_rate)) out_rate[[w]] else 1e-6   # unseen outside -> very distinctive
  ratio <- vapply(names(in_tbl), function(w) in_rate[[w]] / out_rate_for(w), numeric(1))
  ord <- order(ratio, decreasing = TRUE)
  paste(names(in_tbl)[ord][seq_len(min(top_n, length(ord)))], collapse = ", ")
}

# --- 4. summarize + plot -------------------------------------------------------------------------
dk_cluster_summarize <- function(samp) {
  ids <- sort(unique(samp$cluster))
  ids <- ids[ids != 0]                              # report noise separately
  summ <- lapply(ids, function(cid) {
    rows <- samp[samp$cluster == cid, ]
    data.frame(cluster = cid, n = nrow(rows),
               top_platform = names(sort(table(rows$platform), decreasing = TRUE))[1],
               top_words = dk_cluster_label(samp, cid), stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, summ)
  out <- out[order(-out$n), ]
  noise_n <- sum(samp$cluster == 0)
  cat(sprintf("Clusters found: %d | posts in a cluster: %d | noise (no cluster): %d (%.0f%%)\n",
              nrow(out), sum(out$n), noise_n, 100 * noise_n / nrow(samp)))
  out
}

# Plots a 2D UMAP JUST for the picture (n_components=2), separate from the higher-dim UMAP used
# for clustering — a 12-dim reduction can't be plotted directly, and re-running at 2D is cheap.
# min_dist is higher here (0.1 vs 0.0) purely for a more readable SCATTER; the clustering pass
# uses 0.0 (tighter packing) because that's better for HDBSCAN's density estimate, not for viewing.
# Only the top `n_labeled` clusters (by size) get their own colour/legend entry — the rest are
# shown as a single "ostali klasteri" colour so the legend stays readable. Noise is separate again.
dk_cluster_plot <- function(samp, title = "Klasteri objava po značenju", n_labeled = 10L) {
  set.seed(20260709L)
  emb2d <- uwot::umap(samp$embedding, n_neighbors = 15, min_dist = 0.1, metric = "cosine")
  samp$x <- emb2d[, 1]; samp$y <- emb2d[, 2]
  top_ids <- as.integer(names(sort(table(samp$cluster[samp$cluster != 0]), decreasing = TRUE)))[seq_len(min(n_labeled, length(unique(samp$cluster[samp$cluster!=0]))))]
  samp$cluster_f <- dplyr::case_when(
    samp$cluster == 0 ~ "šum (bez klastera)",
    samp$cluster %in% top_ids ~ paste("klaster", samp$cluster),
    TRUE ~ "ostali (manji) klasteri")
  ggplot2::ggplot(samp, ggplot2::aes(x, y, colour = cluster_f)) +
    ggplot2::geom_point(size = 1.2, alpha = 0.7) +
    ggplot2::labs(title = title, x = NULL, y = NULL, colour = "Skupina") +
    theme_digikat_void() +
    ggplot2::theme(legend.position = "right")
}

# --- run as a script -------------------------------------------------------------------------
if (!interactive() || sys.nframe() == 0L) {
  cat("Sampling 5000 posts for clustering ...\n")
  samp <- dk_cluster_sample(n = 5000L)
  cat("Running HDBSCAN on a UMAP-reduced embedding (this can take a minute) ...\n")
  samp <- dk_cluster_run(samp, min_pts = 40L)             # raised from 15 -> fewer, bigger, more readable clusters
  summ <- dk_cluster_summarize(samp)
  cat("\n--- top 12 clusters by size, with their most distinctive words ---\n")
  print(utils::head(summ, 12), row.names = FALSE)

  cat("\nBuilding 2D plot (UMAP projection, coloured by cluster) ...\n")
  p <- dk_cluster_plot(samp)
  out <- here::here("R/semantic/clusters_sample.png")
  ggplot2::ggsave(out, p, width = 11, height = 8, dpi = 150, bg = dk_col$paper)
  cat("saved:", out, "\n")

  saveRDS(samp, here::here("R/semantic/clusters_sample.rds"))
  cat("\nDONE. Full sample + cluster labels saved for further inspection.\n")
  cat("Try:  samp <- readRDS('R/semantic/clusters_sample.rds'); table(samp$cluster)\n")
}
