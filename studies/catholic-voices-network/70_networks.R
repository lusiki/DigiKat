# Level-A networks from private frozen inputs. Speech/relation layers are separate
# and must never be inferred from a mention graph.
source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
source(file.path(study, "network_methods.R"), encoding = "UTF-8")
input_dir <- file.path(workdir, "network_inputs")
output_dir <- file.path(workdir, "network_results")
dir.create(output_dir, showWarnings = FALSE)
input <- jsonlite::fromJSON(file.path(workdir, "network_inputs_report.json"), simplifyVector = FALSE)
stopifnot(input$corpus_sha256 == manifest$corpus$sha256, input$config_hash == config_hash)
read_input <- function(key) {
  entry <- input$files[[key]]; path <- file.path(input_dir, entry$path)
  stopifnot(digest::digest(file = path, algo = "sha256") == entry$sha256)
  header <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE, progress = FALSE))
  characters <- intersect(c("doc_id", "entity_id", "date"), header)
  specification <- readr::cols()
  specification$cols <- setNames(lapply(characters, function(x) readr::col_character()), characters)
  frame <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE, col_types = specification)
  stopifnot(nrow(frame) == entry$rows)
  frame
}
atomic_rds <- function(value, path) {
  tmp <- paste0(path, ".tmp"); saveRDS(value, tmp)
  # rename cannot replace existing files on Windows; completed artifacts are
  # immutable and verified by the settings pin below.
  if (file.exists(path)) stop("Refusing to overwrite completed artifact: ", path)
  if (!file.rename(tmp, path)) stop("Could not publish checkpoint: ", path)
}
settings <- list(input_sha = digest::digest(file = file.path(workdir, "network_inputs_report.json"), algo = "sha256"),
  code = digest::digest(file = file.path(study, "70_networks.R"), algo = "sha256"),
  methods = digest::digest(file = file.path(study, "network_methods.R"), algo = "sha256"),
  seed = config$seed, backbone = as.character(packageVersion("backbone")),
  igraph = as.character(packageVersion("igraph")))
pin <- file.path(output_dir, "settings.rds")
if (file.exists(pin)) stopifnot(identical(settings, readRDS(pin))) else atomic_rds(settings, pin)

people <- read_input("people")
appearances <- read_input("appearances")
paragraphs <- read_input("paragraphs")
nodes <- sort(people$entity_id)
stopifnot(!anyDuplicated(appearances[c("doc_id", "entity_id")]))
incidence <- function(person, context) {
  pairs <- unique(data.frame(person = person, context = context))
  columns <- sort(unique(pairs$context))
  Matrix::sparseMatrix(i = match(pairs$person, nodes), j = match(pairs$context, columns), x = 1,
    dims = c(length(nodes), length(columns)), dimnames = list(nodes, columns))
}
contexts <- list(outlets = list(appearances$entity_id, appearances$source_id),
                 paragraphs = list(paragraphs$entity_id, paste(paragraphs$doc_id, paragraphs$paragraph_id, sep = ":p")))
networks <- list()
for (kind in names(contexts)) {
  checkpoint <- file.path(output_dir, paste0("mention_", kind, ".rds"))
  if (file.exists(checkpoint)) {
    networks[[kind]] <- readRDS(checkpoint)
  } else {
    B <- incidence(contexts[[kind]][[1]], contexts[[kind]][[2]])
    cat(utc(), kind, "starting SDSM:", nrow(B), "people,", ncol(B), "contexts\n")
    flush.console()
    result <- sdsm_network(B, config$seed)
    result$metadata$contexts <- ncol(B)
    result$metadata$people <- nrow(B)
    result$metadata$single_person_contexts <- sum(Matrix::colSums(B) == 1L)
    result$metadata$level <- "A"
    result$metadata$meaning <- "Shared source or paragraph exposure; neither speech nor influence."
    atomic_rds(result, checkpoint); networks[[kind]] <- result
    rm(B); gc()
  }
  cat(utc(), kind, igraph::vcount(networks[[kind]]$graph), "people,",
      igraph::ecount(networks[[kind]]$graph), "backbone edges\n")
}

checkpoint <- file.path(output_dir, "mention_measures.rds")
if (!file.exists(checkpoint)) {
  appearances$quarter <- ifelse(is.na(appearances$date), NA_character_,
    paste0(substr(appearances$date, 1, 4), "-Q", ceiling(as.integer(substr(appearances$date, 6, 7))/3)))
  summaries <- lapply(nodes, function(id) {
    x <- appearances[appearances$entity_id == id, ]
    # Families count independent captured text groups, not original authorship.
    data.frame(entity_id = id, mentioned_documents = nrow(x), mention_spans = sum(x$mention_spans),
      source_platform_pairs = length(unique(x$source_id)), platforms = length(unique(x$platform)),
      families = length(unique(x$family_id)), excess_family_appearances = nrow(x)-length(unique(x$family_id)),
      active_quarters = length(unique(x$quarter[!is.na(x$quarter)])),
      confessional_documents = sum(x$label == "confessional"), secular_documents = sum(x$label == "secular"),
      unlabelled_documents = sum(x$label == "unlabelled"))
  })
  measures <- if (length(summaries)) do.call(rbind, summaries) else data.frame(entity_id = character())
  temporal <- unique(appearances[c("doc_id", "entity_id", "era", "quarter")])
  temporal <- temporal[!is.na(temporal$quarter) & !is.na(temporal$era), ]
  if (nrow(temporal)) {
    temporal <- aggregate(list(documents = rep(1L, nrow(temporal))), temporal[c("entity_id", "era", "quarter")], sum)
    temporal$rank <- ave(temporal$documents, interaction(temporal$era, temporal$quarter), FUN = function(x) rank(-x, ties.method = "average"))
  }
  stability <- list()
  for (era in unique(temporal$era)) {
    quarters <- sort(unique(temporal$quarter[temporal$era == era]))
    if (length(quarters) < 2L) next
    for (i in 2:length(quarters)) {
      a <- temporal[temporal$era == era & temporal$quarter == quarters[i-1] & temporal$rank <= 20, ]
      b <- temporal[temporal$era == era & temporal$quarter == quarters[i] & temporal$rank <= 20, ]
      # A missing quarter breaks adjacency. Do not compare across a gap or era.
      serial <- function(q) as.integer(substr(q, 1, 4))*4L+as.integer(substr(q, 7, 7))
      if (serial(quarters[i])-serial(quarters[i-1]) != 1L) next
      stability[[length(stability)+1L]] <- c(list(era = era, previous = quarters[i-1], current = quarters[i],
        previous_top_n = nrow(a), current_top_n = nrow(b),
        previous_top_survival = if (nrow(a)) sum(a$entity_id %in% b$entity_id)/nrow(a) else NA_real_), rank_stability(a, b))
    }
  }
  atomic_rds(list(measures = measures, temporal = temporal, adjacent_top20 = stability,
    corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash, created_utc = utc(),
    note = "Ranks include ties. Kendall tau uses common top-20 members and reports their count; survival reports entrants/exits. No cross-era volume comparisons. E-I speech index requires a separately validated speech layer."), checkpoint)
}
summary <- list(created_utc = utc(), corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash,
  level = "A", status = "mention networks complete; speech, relations and perturbations separate",
  networks = lapply(networks, function(x) c(x$metadata, list(edges = igraph::ecount(x$graph),
    isolates = sum(igraph::degree(x$graph) == 0L), communities = length(unique(x$membership))))))
path <- file.path(workdir, "mention_network_report.json")
if (!file.exists(path)) {
  tmp <- paste0(path, ".tmp")
  jsonlite::write_json(summary, tmp, auto_unbox = TRUE, pretty = TRUE, na = "null")
  if (!file.rename(tmp, path)) stop("Could not publish network completion report")
}
