#!/usr/bin/env Rscript
# Seal one internally consistent public-paper run after tables and prose have been synchronised.
# The manifest contains hashes only for restricted audit files; no raw text or identifiers are exposed.
suppressPackageStartupMessages({ library(here); library(jsonlite) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/cst_core.R"))

rsp_assert_official_inputs()
ROOT <- normalizePath(here::here(), winslash = "/", mustWork = TRUE)
OUT <- RSP_OUT
MANIFEST <- file.path(OUT, "rsp_final_run_manifest.json")

rel_path <- function(path) {
  p <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(ROOT, "/")
  if (!startsWith(p, prefix)) stop("Manifest input is outside the repository: ", p, call. = FALSE)
  substring(p, nchar(prefix) + 1L)
}
record <- function(path) {
  if (!file.exists(path)) stop("Final-run input is missing: ", path, call. = FALSE)
  list(path = rel_path(path), bytes = unname(file.info(path)$size), sha256 = digikat_hash_file(path))
}
records <- function(paths) {
  paths <- unique(normalizePath(paths, winslash = "/", mustWork = TRUE))
  unname(lapply(sort(paths), record))
}

core <- cst_build_core(verbose = FALSE)
core_pairs <- cst_core_pairs(core)
cand <- readRDS(RSP_STAGEA_CANDIDATES)
candidate_pairs <- unique(data.frame(rid = as.integer(cand$rid), domain = as.character(cand$domain)))
grad <- read.csv(file.path(OUT, "cst_gradient_adjusted.csv"), fileEncoding = "UTF-8")
grad_main <- grad[grad$code == "ax1_link_genuine", ]
era <- read.csv(file.path(OUT, "cst_core_domain_era.csv"), fileEncoding = "UTF-8")
rob <- read.csv(file.path(OUT, "cst_robustness_summary.csv"), fileEncoding = "UTF-8")
stab <- read.csv(file.path(OUT, "rsp_annotation_stability.csv"), fileEncoding = "UTF-8")
stab_manifest <- jsonlite::fromJSON(file.path(OUT, "rsp_stability_manifest.json"), simplifyVector = TRUE)
coding_manifest <- jsonlite::fromJSON(file.path(OUT, "rsp_coding_manifest.json"), simplifyVector = TRUE)
input_manifest <- rsp_read_input_manifest()
database_path <- here::here(digikat_corpus_path())
actual_database_sha <- digikat_hash_file(database_path)

gates <- list(
  official_database_sha_matches = identical(
    as.character(input_manifest$database$sha256),
    as.character(digikat_read_corpus_manifest()$corpus$sha256)) &&
    identical(as.character(input_manifest$database$sha256), actual_database_sha),
  candidate_pairs_equal_manifest = nrow(candidate_pairs) == as.integer(input_manifest$inputs$candidates$rows),
  candidate_posts_equal_manifest = length(unique(candidate_pairs$rid)) ==
    as.integer(input_manifest$inputs$candidates$posts),
  core_posts = nrow(core),
  core_pairs = nrow(core_pairs),
  gradient_numerator_pairs = sum(grad_main$doctrinal),
  era_pairs = sum(era$Freq),
  baseline_linked_pairs = rob$pairs[rob$variant == "baseline"],
  baseline_linked_posts = rob$posts[rob$variant == "baseline"],
  same_domain_core_reconciles = nrow(core_pairs) == sum(grad_main$doctrinal) &&
    nrow(core_pairs) == sum(era$Freq),
  baseline_frame_reconciles = nrow(candidate_pairs) == rob$pairs[rob$variant == "baseline"] &&
    length(unique(candidate_pairs$rid)) == rob$posts[rob$variant == "baseline"],
  annotations_match_coding_manifest =
    identical(digikat_hash_file(RSP_R4_ANN), as.character(coding_manifest$assembled$r4_sha256)) &&
    identical(digikat_hash_file(RSP_R1_ANN), as.character(coding_manifest$assembled$r1_sha256)),
  stability_output_matches_manifest = identical(
    digikat_hash_file(file.path(OUT, "rsp_annotation_stability.csv")),
    as.character(stab_manifest$output_sha256)),
  stability_threshold = as.numeric(stab_manifest$gate$threshold),
  stability_passed = isTRUE(stab_manifest$gate$passed),
  stability_failed_axes = as.character(stab$axis[stab$agreement < as.numeric(stab_manifest$gate$threshold)])
)
if (!isTRUE(gates$official_database_sha_matches) ||
    !isTRUE(gates$candidate_pairs_equal_manifest) ||
    !isTRUE(gates$candidate_posts_equal_manifest) ||
    !isTRUE(gates$same_domain_core_reconciles) ||
    !isTRUE(gates$baseline_frame_reconciles) ||
    !isTRUE(gates$annotations_match_coding_manifest) ||
    !isTRUE(gates$stability_output_matches_manifest)) {
  stop("A final-run reconciliation gate failed.", call. = FALSE)
}
if (isTRUE(gates$stability_passed)) {
  stop("Expected the reported failed R2 repeatability gate, but the current stability manifest says pass. Re-review claims.",
       call. = FALSE)
}
if (!identical(gates$stability_failed_axes, "r2_econ_true")) {
  stop("The final run does not have the single reported r2_econ_true stability failure.", call. = FALSE)
}

public_outputs <- file.path(OUT, c(
  "cst_census_summary.csv", "cst_census_terms.csv", "cst_core_domains.csv",
  "cst_core_domain_era.csv", "cst_core_terms.csv", "cst_gradient_adjusted.csv",
  "r1_numerator_precision.csv", "r1_precision_by_era.csv", "r1_precision_by_domain.csv",
  "r1_sample_allocation.csv", "r4_linkage_precision.csv", "r4_sample_allocation.csv",
  "cst_robustness_detail.csv", "cst_robustness_summary.csv", "cst_duplicate_clusters.csv",
  "gold_register_by_domain.csv", "gold_reanalysis_summary.csv",
  "rsp_annotation_provenance.csv", "rsp_annotation_stability.csv",
  "cst_frame_sensitivity.csv", "cst_frame_sensitivity_manifest.json",
  "cst_lexicon_sensitivity.csv", "cst_lexicon_sensitivity_summary.csv",
  "cst_lexicon_sensitivity_adjusted.csv", "cst_lexicon_sensitivity_adjusted_summary.csv",
  "cst_lexicon_sensitivity_manifest.json", "rsp_audit_refresh_manifest.json",
  "rsp_coding_manifest.json", "rsp_stability_manifest.json",
  "rsp_coder_context_diagnostics.csv", "rsp_coder_context_manifest.json",
  "rsp_stability_transitions.csv", "rsp_stability_r1_by_domain.csv"))

restricted_inputs <- c(
  RSP_R4_SHEET, RSP_R4_KEY, RSP_R4_ANN,
  RSP_R1_SHEET, RSP_R1_KEY, RSP_R1_ANN,
  file.path(RSP_PRIVATE, "rsp_stability_key_full_recode.tsv"))

table_paths <- c(file.path(OUT, "tables", sprintf("tab%d_%s.md", 1:7,
  c("population", "audits", "gradient", "era", "boundary", "register", "terms"))),
  file.path(OUT, "tables", "rsp_derived.csv"))
figure_paths <- file.path(OUT, "figures", c(
  "rsp_fig1_gradient.png", "rsp_fig2_era.png", "rsp_fig3_boundary.png",
  "rsp_fig4_lexicon_sensitivity.png",
  # Each figure's caption and source note are generated text installed into the manuscript, so they
  # are sealed alongside the image they describe.
  "fig1_gradient.md", "fig2_era.md", "fig3_boundary.md", "fig4_lexicon_sensitivity.md"))
script_paths <- c(
  list.files(RSP_STUDY, pattern = "\\.R$", full.names = TRUE),
  here::here("R/religious_terms.R"),
  here::here("resources/dictionaries/source_labels.csv"))
manuscript_paths <- c(
  here::here("studies/moral-economy/PAPER_RSP_v2.md"),
  here::here("pages/studije/socijalni-nauk-i-gospodarstvo.qmd"),
  here::here("studies/moral-economy/PIPELINE.md"))

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/36_rsp_final_run_manifest.R",
  status = "complete_with_reported_failed_measurement_gate",
  database_sha256 = input_manifest$database$sha256,
  gates = gates,
  inputs = records(c(database_path, here::here("data/digikat_corpus_manifest.json"), RSP_INPUT_MANIFEST,
                     RSP_CORPUS_PREPARED, RSP_STAGEA_CANDIDATES, RSP_CORE_CACHE)),
  restricted_audit_inputs = records(restricted_inputs),
  public_analysis_outputs = records(public_outputs),
  generated_tables = records(table_paths),
  generated_figures = records(figure_paths),
  manuscripts_and_pipeline = records(manuscript_paths),
  analysis_sources = records(script_paths),
  note = paste(
    "Hashes of restricted files are shareable; their content is not.",
    "The run is complete, but the failed R2 repeatability gate is an analytic result and is retained as a limitation.")
)
digikat_write_json_atomic(manifest, MANIFEST)
cat("[PASS] sealed final run -> ", rel_path(MANIFEST), "\n", sep = "")
cat(sprintf("        %d core posts / %d core pairs; stability passed = %s; failed axis = %s\n",
            nrow(core), nrow(core_pairs), gates$stability_passed,
            paste(gates$stability_failed_axes, collapse = ", ")))
