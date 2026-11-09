# Private, auditable JSON bridge from the frozen R graphs to the report registry.
source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
directory <- file.path(workdir, "network_results")
input <- jsonlite::fromJSON(file.path(workdir, "network_inputs_report.json"), simplifyVector = FALSE)
stopifnot(input$corpus_sha256 == manifest$corpus$sha256, input$config_hash == config_hash)
read_input <- function(key) {
  path <- file.path(workdir, "network_inputs", input$files[[key]]$path)
  stopifnot(digest::digest(file = path, algo = "sha256") == input$files[[key]]$sha256)
  readr::read_csv(path, col_types = readr::cols(.default = readr::col_character()), progress = FALSE)
}
appearances <- read_input("appearances"); paragraphs <- read_input("paragraphs")
sources <- list(); networks <- list()
for (kind in c("outlets", "paragraphs")) {
  path <- file.path(directory, paste0("mention_", kind, ".rds"))
  sources[[basename(path)]] <- digest::digest(file = path, algo = "sha256")
  result <- readRDS(path); graph <- result$graph
  ids <- igraph::V(graph)$name
  context_rows <- if (kind == "outlets") data.frame(entity_id = appearances$entity_id, context = appearances$source_id) else
    data.frame(entity_id = paragraphs$entity_id, context = paste(paragraphs$doc_id, paragraphs$paragraph_id, sep = ":p"))
  contexts <- lapply(split(context_rows$context, context_rows$entity_id), unique)
  edges <- igraph::as_data_frame(graph, what = "edges")
  edges$shared_contexts <- integer(nrow(edges)); edges$independent_documents <- rep(NA_integer_, nrow(edges))
  for (i in seq_len(nrow(edges))) {
    shared <- intersect(contexts[[edges$from[i]]], contexts[[edges$to[i]]])
    edges$shared_contexts[i] <- length(shared)
    if (kind == "paragraphs") edges$independent_documents[i] <- length(unique(sub(":p[0-9]+$", "", shared)))
  }
  edges$display <- edges$shared_contexts >= 5L & (kind == "outlets" | edges$independent_documents >= 5L)
  networks[[kind]] <- list(nodes = data.frame(entity_id = ids,
    community = as.integer(result$membership[ids]), degree = as.integer(igraph::degree(graph)),
    brokerage = as.numeric(result$brokerage[ids])), edges = edges, metadata = result$metadata,
    withheld_display_edges = sum(!edges$display),
    note = "Full frozen graph defines communities and brokerage. Display omits ties supported by fewer than five contexts or, for paragraph ties, fewer than five distinct documents.")
}
path <- file.path(directory, "mention_measures.rds")
sources[[basename(path)]] <- digest::digest(file = path, algo = "sha256")
measures <- readRDS(path)
output <- list(created_utc = measures$created_utc, corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash,
  code_sha256 = digest::digest(file = file.path(study, "78_export_network_metrics.R"), algo = "sha256"),
  source_sha256 = sources, networks = networks, measures = measures$measures,
  temporal = measures$temporal, adjacent_top20 = measures$adjacent_top20)
target <- file.path(workdir, "network_metrics.json")
encoded <- jsonlite::toJSON(output, auto_unbox = TRUE, pretty = TRUE, na = "null", digits = 16)
if (file.exists(target)) {
  existing <- paste(readLines(target, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  stopifnot(identical(existing, as.character(encoded)))
} else {
  temporary <- paste0(target, ".tmp"); writeLines(encoded, temporary, useBytes = TRUE)
  if (!file.rename(temporary, target)) stop("Cannot publish metric checkpoint")
}
cat("Private network metric bridge saved; disclosure flags retained.\n")
