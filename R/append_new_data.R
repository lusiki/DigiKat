# =============================================================================
# append_new_data.R
# -----------------------------------------------------------------------------
# Incrementally append a NEW batch of raw .xlsx files to the existing
# merged_comprehensive.rds, running the new rows through the religious-terms
# filter (>= 2 distinct term matches), de-duplicating against what is already
# in the master file, and saving an updated master (with a timestamped backup).
#
# This does NOT rebuild from scratch. It only processes the files you drop into
# the NEW-batch folder (default: data/raw/new/), so existing rows are untouched.
#
# USAGE
#   1. Put ONLY the new .xlsx files in  data/raw/new/   (create the folder).
#   2. Make sure  data/merged_comprehensive.rds  exists locally.
#   3. From the project root, run:   Rscript R/append_new_data.R
#      (or open in RStudio and source it).
#
# The script writes data/merged_comprehensive.rds and a backup copy
# data/merged_comprehensive_backup_<UTC-timestamp>.rds before overwriting.
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(tidyverse)
  library(stringi)
})

# ---- Configuration ----------------------------------------------------------
new_data_folder <- "data/raw/new"                 # drop NEW .xlsx files here
master_path     <- "data/merged_comprehensive.rds"
terms_path      <- "R/religious_terms.R"
dedup_key       <- "URL"   # column used to detect rows already in the master
min_matches     <- 2L      # keep rows with >= this many distinct term matches
batch_size      <- 5000L

# =============================================================================
# 1. PRE-FLIGHT CHECKS
# =============================================================================
if (!file.exists(master_path)) {
  stop(
    "Master file not found: ", master_path,
    "\nThis script APPENDS to an existing master. Restore it first ",
    "(it is gitignored and not in the repo)."
  )
}
if (!dir.exists(new_data_folder)) {
  stop(
    "New-data folder not found: ", new_data_folder,
    "\nCreate it and drop ONLY the new .xlsx files into it."
  )
}

new_files <- list.files(new_data_folder, pattern = "\\.xlsx$", full.names = TRUE)
if (length(new_files) == 0) {
  stop("No .xlsx files found in ", new_data_folder)
}

if (!file.exists(terms_path)) {
  stop("Religious terms script not found: ", terms_path)
}

cat("Found", length(new_files), "new file(s) in", new_data_folder, "\n")

# =============================================================================
# 2. LOAD MASTER + RELIGIOUS TERMS
# =============================================================================
cat("Loading master:", master_path, "...\n")
master <- readRDS(master_path)
cat("  Master rows:", nrow(master), " cols:", ncol(master), "\n")

# religious_terms.R returns the data frame as its last expression
religious_terms <- source(terms_path, local = TRUE)$value
religious_terms <- religious_terms |>
  mutate(
    term  = stringi::stri_trans_tolower(term),
    regex = as.character(regex)
  )

# =============================================================================
# 3. READ + MERGE THE NEW BATCH
# =============================================================================
cat("Reading new .xlsx files...\n")
new_data <- map_df(new_files, read_excel)
cat("  New rows read:", nrow(new_data), "\n")

# --- schema sanity checks ---
if (!"FULL_TEXT" %in% names(new_data)) {
  stop("New data has no FULL_TEXT column; the religious filter cannot run.")
}
if (!dedup_key %in% names(new_data)) {
  warning(
    "Dedup key '", dedup_key, "' missing from new data; ",
    "de-duplication against the master will be SKIPPED for new rows."
  )
}
missing_cols <- setdiff(names(master), names(new_data))
if (length(missing_cols) > 0) {
  cat("NOTE:", length(missing_cols),
      "column(s) present in master but absent in new data will be NA:\n  ",
      paste(head(missing_cols, 20), collapse = ", "),
      if (length(missing_cols) > 20) " ..." else "", "\n")
}

# =============================================================================
# 4. RELIGIOUS-TERMS FILTER (regex match, keep >= min_matches)
#    (logic mirrors R/load_merge_filter_religious.R)
# =============================================================================
extract_match_details_regex <- function(txt, terms_df) {
  if (is.na(txt) || txt == "") {
    return(list(matched_terms = NA_character_, matched_words = NA_character_,
                matched_sentences = NA_character_, match_count = 0L))
  }
  matched_terms <- character(); all_words <- character(); all_sents <- character()
  sentences <- unlist(stringi::stri_split_regex(txt, "(?<=[.!?])\\s+"))
  for (i in seq_len(nrow(terms_df))) {
    pat <- terms_df$regex[i]
    words <- unlist(stringi::stri_extract_all_regex(
      txt, pat, opts_regex = list(case_insensitive = TRUE)))
    words <- unique(words[!is.na(words) & nzchar(words)])
    if (length(words) > 0) {
      matched_terms <- c(matched_terms, terms_df$term[i])
      all_words     <- c(all_words, words)
      sents_i <- sentences[stringi::stri_detect_regex(
        sentences, pat, opts_regex = list(case_insensitive = TRUE))]
      all_sents <- c(all_sents, sents_i)
    }
  }
  if (length(matched_terms) == 0) {
    return(list(matched_terms = NA_character_, matched_words = NA_character_,
                matched_sentences = NA_character_, match_count = 0L))
  }
  list(
    matched_terms     = paste(unique(matched_terms), collapse = "; "),
    matched_words     = paste(unique(all_words),     collapse = "; "),
    matched_sentences = paste(unique(all_sents),     collapse = " | "),
    match_count       = length(unique(matched_terms))
  )
}

n_rows  <- nrow(new_data)
txt_low <- stringi::stri_trans_tolower(new_data$FULL_TEXT)

mt <- character(n_rows); mw <- character(n_rows)
ms <- character(n_rows); mc <- integer(n_rows)

n_batches <- ceiling(n_rows / batch_size)
cat("Filtering", n_rows, "new rows in", n_batches, "batch(es)...\n")
for (i in seq_len(n_batches)) {
  s <- (i - 1) * batch_size + 1
  e <- min(i * batch_size, n_rows)
  for (j in s:e) {
    r <- extract_match_details_regex(txt_low[j], religious_terms)
    mt[j] <- r$matched_terms; mw[j] <- r$matched_words
    ms[j] <- r$matched_sentences; mc[j] <- r$match_count
  }
  cat("\r  Batch", i, "/", n_batches, "-", round(100 * e / n_rows), "%   ")
  flush.console()
}
cat("\n")

new_data <- new_data |>
  mutate(
    root_match_count  = mc,
    matched_terms     = mt,
    matched_words     = mw,
    matched_sentences = ms
  )

new_filtered <- new_data |> filter(root_match_count >= min_matches)
cat("New rows passing religious filter (>=", min_matches, "matches):",
    nrow(new_filtered), "of", n_rows,
    " (", round(100 * nrow(new_filtered) / n_rows, 1), "%)\n", sep = "")

if (nrow(new_filtered) == 0) {
  cat("Nothing to append. Exiting without changes.\n")
  quit(save = "no", status = 0)
}

# =============================================================================
# 5. ALIGN COLUMNS + TAG SOURCE
# =============================================================================
new_filtered <- new_filtered |> mutate(data_source = "filtered_religious")

# Keep only columns the master already has (so bind_rows stays clean).
common_cols  <- intersect(names(master), names(new_filtered))
new_to_bind  <- new_filtered |> select(all_of(common_cols))

# =============================================================================
# 6. DE-DUPLICATE AGAINST THE MASTER
#    Only drop new rows whose dedup_key already exists in the SAME half
#    (data_source == "filtered_religious") of the master.
# =============================================================================
if (dedup_key %in% names(master) && dedup_key %in% names(new_to_bind)) {
  existing_relig_keys <- master |>
    filter(.data$data_source == "filtered_religious") |>
    pull(.data[[dedup_key]])
  before <- nrow(new_to_bind)
  new_to_bind <- new_to_bind |>
    filter(!.data[[dedup_key]] %in% existing_relig_keys)
  cat("De-dup on", dedup_key, ": dropped",
      before - nrow(new_to_bind), "row(s) already in master;",
      nrow(new_to_bind), "remain to append.\n")
} else {
  cat("De-dup skipped (key not available in both); appending all filtered rows.\n")
}

if (nrow(new_to_bind) == 0) {
  cat("All new rows were already present. Nothing to append. Exiting.\n")
  quit(save = "no", status = 0)
}

# =============================================================================
# 7. BACKUP + SAVE
# =============================================================================
updated <- bind_rows(master, new_to_bind)

# Timestamp is read from the OS clock at runtime (fine in plain Rscript).
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
backup_path <- sub("\\.rds$", paste0("_backup_", stamp, ".rds"), master_path)

cat("\nBacking up current master to:", backup_path, "\n")
file.copy(master_path, backup_path, overwrite = FALSE)

cat("Saving updated master to:", master_path, "\n")
saveRDS(updated, master_path)

cat("\n=== DONE ===\n")
cat("Master rows before:", nrow(master), "\n")
cat("Rows appended:     ", nrow(new_to_bind), "\n")
cat("Master rows after: ", nrow(updated), "\n")
cat("Backup saved at:   ", backup_path, "\n")
cat("\nNEXT: re-render the map pages (pages/mapa/*.qmd) to refresh ",
    "data/processed/*.rds. NLP-dependent maps also need tokenization re-run.\n", sep = "")
