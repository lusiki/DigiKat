#!/usr/bin/env Rscript
# Mechanical source-to-data checks for PAPER_v2.md.

suppressPackageStartupMessages({
  library(here)
})
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")

study_dir <- here::here("studies/catholic-education")
out_dir <- file.path(study_dir, "output")
tab_dir <- file.path(out_dir, "tables")
paper_path <- file.path(study_dir, "PAPER_v2.md")
paper_lines <- readLines(paper_path, encoding = "UTF-8", warn = FALSE)
paper <- paste(paper_lines, collapse = "\n")

slice <- readRDS(file.path(out_dir, "slice.rds"))
catholic_education_assert_slice_current(slice)
input_manifest <- jsonlite::fromJSON(
  file.path(out_dir, "analysis_input_manifest.json"),
  simplifyVector = TRUE
)
if (!identical(
  tolower(input_manifest$input$sha256),
  tolower(attr(slice, "cache_fingerprint")$input$sha256)
)) {
  stop("analysis_input_manifest.json does not match slice.rds.", call. = FALSE)
}

# Generated Table 1 must appear byte-for-byte between explicit manuscript markers.
table_lines <- readLines(file.path(tab_dir, "paper_table1.md"), encoding = "UTF-8", warn = FALSE)
start <- which(paper_lines == "<!-- BEGIN GENERATED TABLE 1 -->")
end <- which(paper_lines == "<!-- END GENERATED TABLE 1 -->")
if (length(start) != 1L || length(end) != 1L || end <= start) {
  stop("PAPER_v2.md has invalid generated Table 1 markers.", call. = FALSE)
}
embedded <- paper_lines[(start + 1L):(end - 1L)]
if (!identical(embedded, table_lines)) {
  stop("Generated Table 1 in PAPER_v2.md differs from paper_table1.md.", call. = FALSE)
}

# Each headline scalar is generated in paper_derived.csv and must occur in the prose/table source.
derived <- read.csv(
  file.path(tab_dir, "paper_derived.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
required_metrics <- c(
  "official_corpus_n", "corpus_2021_2025_n", "education_strand_n",
  "observed_months", "document_overlap_share", "local_overlap_share",
  "overlap_removed_share", "stepinac_n", "stepinac_local_share",
  "foil_local_share", "stepinac_foil_ratio", "stepinac_cv",
  "stepinac_source_coverage", "stepinac_nonconf_share",
  "affect_unique_posts", "affect_token_coverage", "web_share_strand",
  "value_token_n", "upbringing_token_n", "curriculum_token_n"
)
missing_metrics <- setdiff(required_metrics, derived$metric)
if (length(missing_metrics)) {
  stop("paper_derived.csv is missing: ", paste(missing_metrics, collapse = ", "), call. = FALSE)
}
missing_displays <- vapply(required_metrics, function(metric) {
  display <- derived$display[derived$metric == metric][1]
  !grepl(display, paper, fixed = TRUE)
}, logical(1))
if (any(missing_displays)) {
  stop(
    "PAPER_v2.md does not contain generated display value(s) for: ",
    paste(required_metrics[missing_displays], collapse = ", "),
    call. = FALSE
  )
}

# Stale accumulator-run claims must not survive except the explicitly labelled strand comparison.
stale_forbidden <- c(
  "710,307", "9,831", "82,025", "79,962", "22,233", "14,918", "5,172",
  "23.9%", "69.4%", "62.2%", "36.0%", "11.0%", "95-term"
)
stale_hits <- stale_forbidden[vapply(stale_forbidden, grepl, logical(1), x = paper, fixed = TRUE)]
if (length(stale_hits)) {
  stop("PAPER_v2.md retains stale accumulator claim(s): ", paste(stale_hits, collapse = ", "), call. = FALSE)
}
old_strand_lines <- grep("176,312", paper_lines, fixed = TRUE, value = TRUE)
if (length(old_strand_lines) != 2L || any(!grepl("previous|rather than", old_strand_lines, ignore.case = TRUE))) {
  stop("The old strand count may appear only twice as an explicit old-versus-new comparison.", call. = FALSE)
}

if (grepl("genuine anchoring", paper, ignore.case = TRUE)) {
  stop("Use 'local past linkage'; proximity is not semantically validated genuine anchoring.", call. = FALSE)
}
mojibake <- c("Ã", "ÄŤ", "Å¡", "Å¾", "â€“", "â€”")
bad_encoding <- mojibake[vapply(mojibake, grepl, logical(1), x = paper, fixed = TRUE)]
if (length(bad_encoding)) {
  stop("PAPER_v2.md contains mojibake marker(s): ", paste(bad_encoding, collapse = ", "), call. = FALSE)
}

figure_paths <- c(
  "paper_anchor_split.png", "paper_overlap_filter.png",
  "paper_pooled_seasonality.png", "paper_source_boundary.png"
)
figure_files <- file.path(out_dir, "figures", figure_paths)
missing_figures <- figure_files[!file.exists(figure_files) | file.info(figure_files)$size == 0]
if (length(missing_figures)) {
  stop("Missing or empty manuscript figure(s): ", paste(missing_figures, collapse = ", "), call. = FALSE)
}

# Study-scoped disclosure check. Row-level slice files are ignored; public CSV outputs must not expose
# text, URLs, account handles or contact identifiers.
public_csv <- list.files(out_dir, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)
direct_identifiers <- c(
  "url", "urls", "permalink", "link_url", "uri", "full_text", "raw_text", "text",
  "body", "content", "caption", "title", "description", "window", "context", "excerpt",
  "quote", "username", "user_name", "screen_name", "handle", "author_id", "email", "phone",
  "ip", "ip_address"
)
disclosure_violations <- vapply(public_csv, function(path) {
  header <- names(utils::read.csv(path, nrows = 0L, check.names = FALSE, fileEncoding = "UTF-8-BOM"))
  risky <- intersect(tolower(header), direct_identifiers)
  if (length(risky)) paste0(basename(path), ": ", paste(risky, collapse = ", ")) else ""
}, character(1))
disclosure_violations <- disclosure_violations[nzchar(disclosure_violations)]
if (length(disclosure_violations)) {
  stop(
    "Catholic-education public output disclosure check failed: ",
    paste(disclosure_violations, collapse = "; "),
    call. = FALSE
  )
}

code_files <- c(
  "study_input.R", "slice.R", "stageA_checks.R", "signal2_actors.R",
  "conf_secular.R", "signal3_affect.R", "paper_figures.R", "paper_tables.R",
  "paper_checks.R"
)
analysis_manifest <- list(
  schema_version = 1,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/catholic-education/paper_checks.R",
  input = list(
    kind = "official_digikat_corpus",
    sha256 = input_manifest$input$sha256,
    rows = input_manifest$input$rows,
    analysis_rows = nrow(slice)
  ),
  code = setNames(
    lapply(file.path(study_dir, code_files), function(path) list(sha256 = digikat_hash_file(path))),
    code_files
  ),
  manuscript = list(
    path = "studies/catholic-education/PAPER_v2.md",
    sha256 = digikat_hash_file(paper_path),
    generated_table_match = TRUE,
    numeric_claim_check = TRUE,
    stale_claim_check = TRUE,
    utf8_check = TRUE,
    disclosure_check = TRUE
  )
)
digikat_write_json_atomic(
  analysis_manifest,
  file.path(out_dir, "final_run_manifest.json")
)

cat("Catholic-education paper checks passed.\n")
