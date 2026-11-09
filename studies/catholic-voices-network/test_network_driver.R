# End-to-end synthetic input/save/reopen test; no corpus records or claims.
Sys.setenv(DIGIKAT_VOICES_WORKDIR = tempfile("digikat-network-test-"))
source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
dir.create(file.path(workdir, "network_inputs"), recursive = TRUE)
appearances <- do.call(rbind, lapply(1:80, function(i) {
  group <- if (i <= 40) 1:4 else 5:8
  data.frame(doc_id = paste0("fixture-", i), entity_id = paste0("Q", group),
    mention_spans = 1L, platform = "web", era = "post2024", date = "2025-01-01",
    source_id = paste0("source-", i), label = "unlabelled", family_id = i)
}))
paragraphs <- appearances[c("doc_id", "entity_id")]; paragraphs$paragraph_id <- 0L
tables <- list(people = data.frame(entity_id = paste0("Q", 1:8)),
               appearances = appearances, paragraphs = paragraphs)
files <- lapply(names(tables), function(key) {
  path <- file.path(workdir, "network_inputs", paste0(key, ".csv"))
  readr::write_csv(tables[[key]], path)
  list(rows = nrow(tables[[key]]), path = basename(path), sha256 = digest::digest(file = path, algo = "sha256"))
}); names(files) <- names(tables)
jsonlite::write_json(list(corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash, files = files),
  file.path(workdir, "network_inputs_report.json"), auto_unbox = TRUE)
source(file.path(study, "70_networks.R"), encoding = "UTF-8")
before <- digest::digest(file = file.path(workdir, "network_results", "mention_paragraphs.rds"), algo = "sha256")
source(file.path(study, "70_networks.R"), encoding = "UTF-8")
after <- digest::digest(file = file.path(workdir, "network_results", "mention_paragraphs.rds"), algo = "sha256")
stopifnot(identical(before, after))
saved <- readRDS(file.path(workdir, "network_results", "mention_measures.rds"))
stopifnot(nrow(saved$measures) == 8, all(saved$measures$mentioned_documents == 40L),
  all(saved$measures$excess_family_appearances == 0L))
cat("Synthetic network driver and resume checks passed.\n")
source(file.path(study, "78_export_network_metrics.R"), encoding = "UTF-8")
bridge_before <- digest::digest(file = file.path(workdir, "network_metrics.json"), algo = "sha256")
source(file.path(study, "78_export_network_metrics.R"), encoding = "UTF-8")
stopifnot(bridge_before == digest::digest(file = file.path(workdir, "network_metrics.json"), algo = "sha256"))
bridge <- jsonlite::fromJSON(file.path(workdir, "network_metrics.json"))
stopifnot(all(bridge$networks$paragraphs$edges$independent_documents == 40L),
          all(bridge$networks$paragraphs$edges$display),
          all(bridge$networks$outlets$edges$shared_contexts == 40L))
cat("Synthetic graph evidence export and identical reopening passed.\n")
