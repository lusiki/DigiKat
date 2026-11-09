# Pure network methods. Corpus loading and disclosure belong to the stage driver.
# API verified against backbone 3.0.4 CRAN manual, 2026-10-25.
sdsm_network <- function(incidence, seed = 20261025L) {
  stopifnot(is.matrix(incidence) || inherits(incidence, "Matrix"))
  stopifnot(!anyNA(incidence), all(incidence >= 0))
  # SDSM requires binary incidence, NOT the weighted projected adjacency matrix.
  # Counts remain separate descriptive measures.
  B <- (incidence > 0) * 1
  stopifnot(!is.null(rownames(B)), !anyDuplicated(rownames(B)))
  set.seed(seed)
  if (nrow(B) < 2L || ncol(B) < 1L || !any(B > 0)) {
    graph <- igraph::make_empty_graph(nrow(B), directed = FALSE)
    igraph::V(graph)$name <- rownames(B)
  } else {
    # Zero columns contribute no ties; retain all eligible people, including isolates.
    B <- B[, Matrix::colSums(B) > 0, drop = FALSE]
    adjacency <- backbone::backbone_from_projection(
      B, alpha = 0.05, model = "sdsm", signed = FALSE, mtc = "BH",
      missing_as_zero = TRUE, narrative = FALSE, backbone_only = TRUE
    )
    graph <- igraph::graph_from_adjacency_matrix(adjacency, mode = "undirected", weighted = NULL, diag = FALSE)
  }
  if (igraph::ecount(graph)) {
    groups <- igraph::cluster_leiden(graph, objective_function = "modularity", n_iterations = 10L)
    membership <- igraph::membership(groups)
  } else {
    membership <- seq_len(igraph::vcount(graph))
    names(membership) <- igraph::V(graph)$name
  }
  list(graph = graph, membership = membership,
       brokerage = igraph::betweenness(graph, directed = FALSE, normalized = TRUE),
       metadata = list(model = "SDSM", alpha = 0.05, multiple_tests = "BH across all projected pairs, including zero edges",
                       incidence = "binary presence; frequencies reported separately",
                       backbone_version = as.character(utils::packageVersion("backbone")), seed = seed))
}

rank_stability <- function(previous, current) {
  stopifnot(all(c("entity_id", "rank") %in% names(previous)), all(c("entity_id", "rank") %in% names(current)))
  paired <- merge(previous, current, by = "entity_id", suffixes = c("_previous", "_current"))
  list(common_entities = nrow(paired),
       kendall_tau = if (nrow(paired) >= 2L) stats::cor(paired$rank_previous, paired$rank_current, method = "kendall") else NA_real_)
}

ei_index <- function(confessional, secular) {
  # Unlabelled outlets are excluded from this denominator and must be counted separately.
  denominator <- confessional + secular
  ifelse(denominator > 0, (secular - confessional) / denominator, NA_real_)
}
