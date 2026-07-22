#!/usr/bin/env Rscript
# R/semantic/14_network.R  —  A SIMILARITY NETWORK from the meaning-search store.
#
# WHAT THIS SHOWS: each post is a dot (node). Two dots get a line (edge) between them
# if their MEANING is close enough (cosine similarity above a threshold). Dots that
# share many lines cluster together visually — those clusters are topics/events the
# corpus talks about, discovered bottom-up (not the fixed 16 categories).
#
# WHY A SAMPLE, NOT ALL 710k: comparing every post to every other post is ~250 BILLION
# pairs — intractable, and unreadable as a picture even if computed. We take a sample
# (default 1500 posts, optionally restricted by a query/topic filter first) and compute
# ALL pairwise similarities WITHIN that sample. This is a snapshot of local structure,
# not the whole corpus — treat it as "what does a slice look like", not a census.
#
# Run:  Rscript R/semantic/14_network.R
# Or source() and call dk_network_plot() with your own sample/threshold.
suppressPackageStartupMessages({
  library(here); library(ragnar); library(DBI); library(duckdb)
  library(igraph); library(tidygraph); library(ggraph); library(ggplot2)
})
source(here::here("R/theme_digikat.R"))       # dk_platform_colors, theme_digikat_void()

# --- pull a sample of (doc_id, platform, date, embedding) straight from the store ------------
# topic_query: optional. If given, sample from the top-N nearest posts to that query instead of
#   a random sample — lets you build "the network AROUND this topic" (e.g. "sinodalnost").
dk_sample_for_network <- function(n = 1500L, topic_query = NULL, seed = 20260709L,
                                  store_path = here::here("data/semantic/digikat.ragnar.duckdb")) {
  con <- dbConnect(duckdb::duckdb(), dbdir = store_path, read_only = TRUE, array = "matrix")
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
  if (is.null(topic_query)) {
    q <- sprintf("SELECT doc_id, platform, date, data_source, text, embedding FROM chunks
                 USING SAMPLE %d ROWS (reservoir, %d)", as.integer(n), as.integer(seed))
    dbGetQuery(con, q)
  } else {
    st <- ragnar_store_connect(store_path, read_only = TRUE)
    hits <- ragnar_retrieve(st, topic_query, top_k = as.integer(n))
    ids <- paste(sprintf("'%s'", hits$doc_id), collapse = ",")
    dbGetQuery(con, sprintf(
      "SELECT doc_id, platform, date, data_source, text, embedding FROM chunks WHERE doc_id IN (%s)", ids))
  }
}

# --- build the graph: nodes = sampled posts; edges = pairs above `threshold` cosine similarity -
# top_k_per_node caps how many edges each node can draw (its k closest neighbors) — without this,
# a threshold alone can still produce a dense hairball if the sample is topically narrow.
dk_network_build <- function(samp, threshold = 0.55, top_k_per_node = 8L) {
  mat <- samp$embedding
  mat <- mat / sqrt(rowSums(mat^2))                       # L2-normalize -> dot product = cosine similarity
  sim <- tcrossprod(mat)                                  # n x n cosine similarity matrix
  diag(sim) <- -Inf
  n <- nrow(samp)
  edges <- do.call(rbind, lapply(seq_len(n), function(i) {
    ord <- order(sim[i, ], decreasing = TRUE)[seq_len(min(top_k_per_node, n - 1))]
    keep <- ord[sim[i, ord] >= threshold]
    if (!length(keep)) return(NULL)
    data.frame(from = i, to = keep, weight = sim[i, keep])
  }))
  if (is.null(edges) || !nrow(edges)) stop("No edges above threshold=", threshold,
    " — lower the threshold or use a topic_query to make the sample more coherent.")
  edges <- edges[edges$from < edges$to, ]                 # dedup A-B / B-A
  nodes <- data.frame(id = seq_len(n), doc_id = samp$doc_id, platform = samp$platform,
                      date = samp$date, data_source = samp$data_source,
                      snippet = substr(samp$text, 1, 90))
  tidygraph::tbl_graph(nodes = nodes, edges = edges, directed = FALSE)
}

# --- plot it, on-brand (theme_digikat_void + dk_platform_colors) -------------------------------
dk_network_plot <- function(graph, title = "Mrežni prikaz sličnosti objava", subtitle = NULL) {
  set.seed(20260709L)
  # drop isolated nodes (no edge survived the threshold) so the layout isn't cluttered with dots
  graph <- graph %>% tidygraph::activate(nodes) %>%
    dplyr::filter(tidygraph::centrality_degree() > 0)
  ggraph::ggraph(graph, layout = "fr") +                  # force-directed: similar posts pull together
    ggraph::geom_edge_link(ggplot2::aes(alpha = weight), colour = dk_col$line, show.legend = FALSE) +
    ggraph::geom_node_point(ggplot2::aes(colour = platform), size = 2.2, alpha = 0.9) +
    ggplot2::scale_colour_manual(values = dk_platform_colors, name = "Platforma") +
    ggplot2::labs(title = title, subtitle = subtitle) +
    theme_digikat_void()
}

# --- run as a script: two example networks -----------------------------------------------------
if (!interactive() || sys.nframe() == 0L) {
  cat("Building network A: RANDOM 1500-post sample (general corpus structure) ...\n")
  sampA <- dk_sample_for_network(n = 1500L)
  gA <- dk_network_build(sampA, threshold = 0.55, top_k_per_node = 6L)
  cat("  nodes:", igraph::vcount(gA), "| edges:", igraph::ecount(gA), "\n")
  pA <- dk_network_plot(gA, subtitle = "Nasumični uzorak od 1500 objava; linija = sličnost ≥ 0.55")
  out_a <- here::here("R/semantic/network_sample.png")
  ggplot2::ggsave(out_a, pA, width = 10, height = 8, dpi = 150, bg = dk_col$paper)
  cat("  saved:", out_a, "\n")

  cat("\nBuilding network B: TOPIC-FOCUSED sample around 'sinodalnost i buducnost Crkve' ...\n")
  sampB <- dk_sample_for_network(n = 400L, topic_query = "sinodalnost i budućnost Crkve")
  gB <- dk_network_build(sampB, threshold = 0.5, top_k_per_node = 8L)
  cat("  nodes:", igraph::vcount(gB), "| edges:", igraph::ecount(gB), "\n")
  pB <- dk_network_plot(gB, title = "Mreža oko teme: sinodalnost",
                        subtitle = "400 najbližih objava upitu; linija = sličnost ≥ 0.5")
  out_b <- here::here("R/semantic/network_topic.png")
  ggplot2::ggsave(out_b, pB, width = 10, height = 8, dpi = 150, bg = dk_col$paper)
  cat("  saved:", out_b, "\n")

  cat("\nDONE. Two PNGs written under R/semantic/. Try your own:\n")
  cat('  samp <- dk_sample_for_network(n = 800, topic_query = "your topic")\n')
  cat('  g <- dk_network_build(samp, threshold = 0.5)\n')
  cat('  dk_network_plot(g)\n')
}
