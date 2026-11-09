# Clearly constructed figure fixture, separate from actual report outputs.
source("studies/catholic-voices-network/test_network_driver.R", encoding = "UTF-8")
fixture_output <- file.path(study, "output/private/figure-smoke")
Sys.setenv(DIGIKAT_VOICES_REPORT_DIR = fixture_output)
people_fixture <- lapply(1:8, function(i) list(entity_id = paste0("Q", i), public_name = paste("Konstruirana osoba", letters[i]),
  documents = 40L, minimum_documents = 35L, maximum_documents = 45L))
model_fixture <- lapply(c("v4", "v5"), function(version) lapply(c("qwen3:14b", "qwen3:8b", "gemma3:12b"),
  function(model) list(protocol = version, model = model, passed = 40L)))
fixture <- list(corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash,
  display_policy = list(range_counts = TRUE), constants = list(synthetic_required = 52L, synthetic_cases = 54L),
  values = list(people = people_fixture,
    platforms = list(list(platform = "web", documents = 80L), list(platform = "facebook", documents = 4L)),
    identity_classes = list(list(platform = "web", life_class = "contemporary", spans = 320L)),
    source_distribution = list(list(public_label = "constructed.test", platform = "web", documents = 80L)),
    person_platform_eras = lapply(1:8, function(i) list(entity_id = paste0("Q", i), platform = "web", era = "post2024", documents = 40L)),
    platform_eras = list(list(platform = "web", era = "post2024", documents = 80L)),
    circulation_sizes = list(list(size_group = "1", families = 80L)),
    quarter_denominators = list(list(platform = "web", era = "post2024", quarter = "2025-Q1", documents = 80L))),
  evidence = list(publication_audit = list(level_a_identity_gate = "passed"),
    network_metrics = jsonlite::fromJSON(file.path(workdir, "network_metrics.json"), simplifyVector = FALSE),
    model_gate_summary = list(configurations = unlist(model_fixture, recursive = FALSE))))
jsonlite::write_json(fixture, file.path(workdir, "report_data.json"), auto_unbox = TRUE, pretty = TRUE)
dir.create(fixture_output, recursive = TRUE, showWarnings = FALSE)
file.copy(file.path(workdir, "report_data.json"), file.path(fixture_output, "constructed_figure_data.json"), overwrite = TRUE)
file.copy(file.path(workdir, "mention_network_report.json"), file.path(fixture_output, "constructed_network_report.json"), overwrite = TRUE)
source(file.path(study, "81_report_figures.R"), encoding = "UTF-8")
stopifnot(length(figures) == 10L)
svg <- paste(readLines(file.path(fixture_output, "figures/platforms.svg"), encoding = "UTF-8"), collapse = "\n")
stopifnot(!grepl("facebook", svg, fixed = TRUE))
cat("Constructed charts and small-cell omission checked; visual review directory:", fixture_output, "\n")
