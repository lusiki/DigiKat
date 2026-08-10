#!/usr/bin/env Rscript
# Build the complete, tracked DigiKat aggregate generation from the official corpus.
#
# Input is data/digikat_corpus.rds — the posts one inclusion rule keeps across both collection eras
# — NOT the accumulator it is cut from. Everything the website reports therefore describes the
# corpus. To aggregate the accumulator instead (for a completed paper, or to compare the two), pass
# --master=data/merged_comprehensive.rds explicitly.
#
# Safe preview (writes to a temporary directory and removes it after checks):
#   Rscript R/03_aggregate.R
#
# Persistent validation output:
#   Rscript R/03_aggregate.R --output-dir=PATH
#
# Protected production replacement:
#   Rscript R/03_aggregate.R --apply

suppressPackageStartupMessages(library(dplyr))
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/03_aggregate.R [--apply] [--master=PATH] [--output-dir=PATH]",
    "",
    "Without --apply, the default data/processed target is generated and validated",
    "inside a temporary directory. A non-production --output-dir is safe to use",
    "for a persistent preview.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

master_path <- digikat_cli_value(args, "--master", digikat_corpus_path())
requested_output <- digikat_cli_value(args, "--output-dir", "data/processed")
apply_changes <- digikat_cli_flag(args, "--apply")
production_dir <- "data/processed"
is_production <- digikat_same_path(requested_output, production_dir)
year_min <- 2021L
year_max <- 2026L
source_levels <- c(
  "web", "youtube", "facebook", "twitter", "reddit",
  "forum", "instagram", "comment", "tiktok"
)
actor_platforms <- c("web", "youtube", "facebook", "instagram", "tiktok", "twitter")
top_source_platforms <- c("web", "youtube", "facebook")

if (apply_changes && !is_production) {
  stop("--apply is reserved for the protected data/processed target.", call. = FALSE)
}
if (!file.exists(master_path)) stop("Master not found: ", master_path, call. = FALSE)

temporary_preview <- is_production && !apply_changes
if (temporary_preview) {
  build_dir <- tempfile(pattern = "digikat-processed-preview-")
  on.exit(unlink(build_dir, recursive = TRUE, force = TRUE), add = TRUE)
} else if (is_production) {
  build_dir <- file.path("data", paste0(".processed-stage-", Sys.getpid()))
  if (dir.exists(build_dir)) {
    stop("Staging directory already exists: ", build_dir, call. = FALSE)
  }
} else {
  build_dir <- requested_output
  if (dir.exists(build_dir) && length(list.files(build_dir, all.files = TRUE, no.. = TRUE))) {
    stop("Preview output directory must be empty or absent: ", build_dir, call. = FALSE)
  }
}
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

cat("Reading master:", master_path, "...\n")
dta <- as.data.frame(readRDS(master_path))
master_rows <- nrow(dta)
digikat_require_columns(
  dta,
  c("DATE", "year", "SOURCE_TYPE", "FROM", "INTERACTIONS", "REACH", "ENGAGEMENT_RATE"),
  "master"
)
cat("  Master rows:", master_rows, "| columns:", ncol(dta), "\n")

parsed_date <- digikat_parse_date(dta$DATE, name = "master DATE", allow_missing = FALSE)
derived_year <- as.integer(format(parsed_date, "%Y"))
upstream_year <- suppressWarnings(as.integer(as.character(dta$year)))
year_mismatch <- !is.na(upstream_year) & upstream_year != derived_year
if (any(year_mismatch)) {
  cat(
    "  NOTE:", sum(year_mismatch),
    "stored year value(s) differ from DATE; aggregates use the DATE-derived year.\n"
  )
}
dta$DATE <- parsed_date
dta$year <- derived_year
dta$SOURCE_TYPE <- as.character(dta$SOURCE_TYPE)

unknown_sources <- setdiff(unique(stats::na.omit(dta$SOURCE_TYPE)), source_levels)
if (length(unknown_sources)) {
  stop("Unknown SOURCE_TYPE value(s): ", paste(unknown_sources, collapse = ", "), call. = FALSE)
}

dta <- dta |>
  filter(
    !is.na(SOURCE_TYPE),
    DATE >= as.Date(sprintf("%d-01-01", year_min)),
    DATE <= as.Date(sprintf("%d-12-31", year_max))
  ) |>
  mutate(SOURCE_TYPE = factor(SOURCE_TYPE, levels = source_levels))

included_rows <- nrow(dta)
if (!included_rows) stop("No rows remain after aggregate scope filters.", call. = FALSE)
cat("  Included rows:", included_rows, "| date span:", format(min(dta$DATE)), "to", format(max(dta$DATE)), "\n")

sum_numeric <- function(value) sum(as.numeric(value), na.rm = TRUE)
mean_numeric <- function(value) {
  value <- as.numeric(value)
  if (all(is.na(value))) return(NA_real_)
  mean(value, na.rm = TRUE)
}

platform_summary <- dta |>
  group_by(year, SOURCE_TYPE) |>
  summarise(
    total_posts = n(),
    total_interactions = sum_numeric(INTERACTIONS),
    total_reach = sum_numeric(REACH),
    .groups = "drop"
  )

proportions_summary <- platform_summary |>
  group_by(year) |>
  mutate(
    post_share = total_posts / sum(total_posts),
    interaction_share = if (sum(total_interactions) == 0) 0 else total_interactions / sum(total_interactions),
    reach_share = if (sum(total_reach) == 0) 0 else total_reach / sum(total_reach)
  ) |>
  ungroup()

platform_monthly <- dta |>
  mutate(month = as.Date(paste0(format(DATE, "%Y-%m"), "-01"))) |>
  group_by(month, SOURCE_TYPE) |>
  summarise(
    total_posts = n(),
    total_interactions = sum_numeric(INTERACTIONS),
    total_reach = sum_numeric(REACH),
    .groups = "drop"
  )

source_summary <- dta |>
  filter(!is.na(FROM), nzchar(trimws(as.character(FROM)))) |>
  group_by(year, FROM) |>
  summarise(
    productivity = n(),
    total_interactions = sum_numeric(INTERACTIONS),
    avg_engagement_rate = mean_numeric(ENGAGEMENT_RATE),
    total_reach = sum_numeric(REACH),
    .groups = "drop"
  )

top_sources_by_year <- source_summary |>
  group_by(year) |>
  slice_max(order_by = total_interactions, n = 15L, with_ties = TRUE) |>
  ungroup()

summarise_platform_actors <- function(data, platform) {
  data |>
    filter(SOURCE_TYPE == platform, !is.na(FROM), nzchar(trimws(as.character(FROM)))) |>
    group_by(FROM) |>
    summarise(
      total_posts = n(),
      total_interactions = sum_numeric(INTERACTIONS),
      total_reach = sum_numeric(REACH),
      .groups = "drop"
    )
}

top_sources <- setNames(vector("list", length(top_source_platforms)), top_source_platforms)
for (platform in top_source_platforms) {
  top_sources[[platform]] <- summarise_platform_actors(dta, platform) |>
    slice_max(order_by = total_interactions, n = 20L, with_ties = TRUE)
}

actor_outputs <- setNames(vector("list", length(actor_platforms)), actor_platforms)
for (platform in actor_platforms) {
  all_actors <- summarise_platform_actors(dta, platform)
  top_interactions <- slice_max(all_actors, order_by = total_interactions, n = 15L, with_ties = TRUE)
  top_reach <- slice_max(all_actors, order_by = total_reach, n = 15L, with_ties = TRUE)
  actor_outputs[[platform]] <- bind_rows(top_interactions, top_reach) |>
    distinct(FROM, .keep_all = TRUE)
}

outputs <- list(
  platform_summary = platform_summary,
  proportions_summary = proportions_summary,
  platform_monthly = platform_monthly,
  source_summary = source_summary,
  top_sources_by_year = top_sources_by_year,
  top_web_sources = top_sources$web,
  top_youtube_sources = top_sources$youtube,
  top_facebook_sources = top_sources$facebook,
  web_actors = actor_outputs$web,
  youtube_actors = actor_outputs$youtube,
  facebook_actors = actor_outputs$facebook,
  instagram_actors = actor_outputs$instagram,
  tiktok_actors = actor_outputs$tiktok,
  twitter_actors = actor_outputs$twitter
)

if (sum(platform_summary$total_posts) != included_rows) {
  stop("platform_summary total does not reconcile to included corpus rows.", call. = FALSE)
}
if (sum(platform_monthly$total_posts) != included_rows) {
  stop("platform_monthly total does not reconcile to included corpus rows.", call. = FALSE)
}
post_share_check <- proportions_summary |>
  group_by(year) |>
  summarise(total = sum(post_share), .groups = "drop")
if (any(abs(post_share_check$total - 1) > 1e-10)) {
  stop("Annual post shares do not sum to one.", call. = FALSE)
}
for (platform in actor_platforms) {
  actor_data <- actor_outputs[[platform]]
  digikat_require_columns(
    actor_data,
    c("FROM", "total_posts", "total_interactions", "total_reach"),
    paste(platform, "actor aggregate")
  )
  if (anyDuplicated(actor_data$FROM)) {
    stop("Duplicate actor names in ", platform, " actor aggregate.", call. = FALSE)
  }
}

cat("Writing and round-trip validating", length(outputs), "RDS outputs in", build_dir, "...\n")
for (name in names(outputs)) {
  path <- file.path(build_dir, paste0(name, ".rds"))
  saveRDS(outputs[[name]], path)
  check <- readRDS(path)
  if (!identical(names(check), names(outputs[[name]])) || nrow(check) != nrow(outputs[[name]])) {
    stop("Round-trip validation failed for ", basename(path), call. = FALSE)
  }
}

source_counts <- as.data.frame(table(droplevels(dta$SOURCE_TYPE)), stringsAsFactors = FALSE)
names(source_counts) <- c("source_type", "rows")
output_manifest <- lapply(names(outputs), function(name) {
  path <- file.path(build_dir, paste0(name, ".rds"))
  list(
    file = basename(path),
    rows = nrow(outputs[[name]]),
    columns = names(outputs[[name]]),
    sha256 = digikat_hash_file(path)
  )
})
names(output_manifest) <- names(outputs)

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/03_aggregate.R",
  input = digikat_file_metadata(master_path, include_hash = TRUE),
  corpus = list(
    master_rows = master_rows,
    included_rows = included_rows,
    date_min = format(min(dta$DATE)),
    date_max = format(max(dta$DATE)),
    year_min = min(dta$year),
    year_max = max(dta$year),
    upstream_year_mismatches = sum(year_mismatch),
    source_counts = split(source_counts$rows, source_counts$source_type)
  ),
  outputs = output_manifest
)
digikat_write_json_atomic(manifest, file.path(build_dir, "manifest.json"))

expected_files <- c(paste0(names(outputs), ".rds"), "manifest.json")
actual_files <- sort(list.files(build_dir))
if (!identical(sort(expected_files), actual_files)) {
  stop(
    "Output generation is incomplete. Expected: ", paste(sort(expected_files), collapse = ", "),
    "; found: ", paste(actual_files, collapse = ", "),
    call. = FALSE
  )
}

if (temporary_preview) {
  cat("Preview validation passed. No tracked aggregate changed.\n")
  cat("  Outputs:", length(outputs), "| included rows:", included_rows, "\n")
  quit(save = "no", status = 0L)
}

if (!is_production) {
  cat("Persistent preview validation passed:", requested_output, "\n")
  cat("  Outputs:", length(outputs), "| included rows:", included_rows, "\n")
  quit(save = "no", status = 0L)
}

existing_allowed <- c(paste0(names(outputs), ".rds"), "manifest.json", ".gitkeep")
unexpected_existing <- setdiff(list.files(production_dir, all.files = TRUE, no.. = TRUE), existing_allowed)
if (length(unexpected_existing)) {
  stop(
    "Refusing directory replacement because data/processed contains unexpected file(s): ",
    paste(unexpected_existing, collapse = ", "),
    call. = FALSE
  )
}

generation_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
previous_dir <- file.path("data", "private", "processed-backups", generation_stamp)
dir.create(dirname(previous_dir), recursive = TRUE, showWarnings = FALSE)
if (dir.exists(previous_dir)) stop("Processed backup directory already exists: ", previous_dir, call. = FALSE)

cat("Installing validated aggregate generation...\n")
if (dir.exists(production_dir) && !file.rename(production_dir, previous_dir)) {
  stop("Could not move the current processed generation to: ", previous_dir, call. = FALSE)
}
if (!file.rename(build_dir, production_dir)) {
  if (dir.exists(previous_dir)) file.rename(previous_dir, production_dir)
  stop("Could not install the staged processed generation; previous generation restored.", call. = FALSE)
}

cat("Aggregate replacement complete.\n")
cat("  New generation:", production_dir, "\n")
cat("  Previous generation retained locally:", previous_dir, "\n")
cat("  Included rows:", included_rows, "| outputs:", length(outputs), "\n")
