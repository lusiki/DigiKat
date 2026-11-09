source("studies/catholic-voices-network/network_methods.R", encoding = "UTF-8")
set.seed(20261025)
B <- matrix(0, nrow = 31, ncol = 90)
for (i in seq_len(30)) {
  group <- (i - 1L) %/% 10L
  probability <- rep(0.04, 90)
  probability[group * 30L + seq_len(30)] <- 0.85
  B[i, ] <- stats::rbinom(90, 1, probability)
}
B[31, ] <- 1 # A ubiquitous actor must not connect everything merely by ubiquity.
rownames(B) <- paste0("synthetic_", seq_len(nrow(B)))
result <- sdsm_network(B)
stopifnot(igraph::vcount(result$graph) == 31L, igraph::ecount(result$graph) > 0L)
stopifnot(igraph::degree(result$graph)[31] == 0L)
again <- sdsm_network(B * 7)
stopifnot(identical(igraph::as_edgelist(result$graph), igraph::as_edgelist(again$graph)))
stopifnot(identical(result$membership, again$membership))
empty <- sdsm_network(matrix(0, nrow = 2, ncol = 3, dimnames = list(c("a", "b"), NULL)))
stopifnot(igraph::vcount(empty$graph) == 2, igraph::ecount(empty$graph) == 0)
stopifnot(is.na(ei_index(0, 0)), ei_index(3, 1) == -0.5)
cat("Network methods: binary SDSM/FDR, ubiquitous-actor null, deterministic Leiden, empty graph and E-I checks passed.\n")
