# Load, merge, and filter .xlsx files based on religious terms regex

library(readxl)
library(tidyverse)
library(stringi)

# Set the folder path (relative to project root)
# NOTE: Place raw Excel files in data/raw/ folder
folder_path <- "data/raw"

# List all .xlsx files in the folder
xlsx_files <- list.files(
  path = folder_path,
  pattern = "\\.xlsx$",
  full.names = TRUE
)

if (length(xlsx_files) == 0) {
  stop("No .xlsx files found in the folder: ", folder_path)
}

# Read and merge all files
cat("Reading", length(xlsx_files), "files...\n")
merged_data <- map_df(xlsx_files, read_excel)

cat("Merged", length(xlsx_files), "files\n")

# ---- FILTERING SECTION ----

# Use religious_terms from workspace with regex patterns
if (!exists("religious_terms")) {
  stop("religious_terms not found in workspace. Please define it with columns 'term' and 'regex'.")
}

religious_terms <- religious_terms |>
  mutate(
    term = stringi::stri_trans_tolower(term),
    regex = as.character(regex)
  )

# Optionally normalize unique_strings if present (for labeling consistency)
if (exists("unique_strings")) {
  unique_strings <- unique(stringi::stri_trans_tolower(unique_strings))
}

cat("Lowercasing FULL_TEXT column...\n")
merged_data <- merged_data |>
  mutate(FULL_TEXT_lower = stringi::stri_trans_tolower(FULL_TEXT))

cat("Searching for articles with at least 2 term regex matches...\n")
cat("Extracting matched terms, full words, and sentences...\n")

n_rows <- nrow(merged_data)
batch_size <- 5000
n_batches <- ceiling(n_rows / batch_size)

# Function to extract match details using regex patterns per term
extract_match_details_regex <- function(txt, terms_df) {
  if (is.na(txt) || txt == "") {
    return(list(
      matched_terms = NA_character_,
      matched_words = NA_character_,
      matched_sentences = NA_character_,
      match_count = 0L
    ))
  }

  matched_terms <- character()
  all_matched_words <- character()
  all_matched_sentences <- character()

  sentences <- unlist(stringi::stri_split_regex(txt, "(?<=[.!?])\\s+"))

  for (i in seq_len(nrow(terms_df))) {
    pat <- terms_df$regex[i]
    words <- unlist(stringi::stri_extract_all_regex(
      txt, pat,
      opts_regex = list(case_insensitive = TRUE)
    ))
    words <- unique(words[!is.na(words) & nzchar(words)])
    if (length(words) > 0) {
      matched_terms <- c(matched_terms, terms_df$term[i])
      all_matched_words <- c(all_matched_words, words)
      sents_i <- sentences[stringi::stri_detect_regex(
        sentences, pat, opts_regex = list(case_insensitive = TRUE)
      )]
      all_matched_sentences <- c(all_matched_sentences, sents_i)
    }
  }

  if (length(matched_terms) == 0) {
    return(list(
      matched_terms = NA_character_,
      matched_words = NA_character_,
      matched_sentences = NA_character_,
      match_count = 0L
    ))
  }

  list(
    matched_terms = paste(unique(matched_terms), collapse = "; "),
    matched_words = paste(unique(all_matched_words), collapse = "; "),
    matched_sentences = paste(unique(all_matched_sentences), collapse = " | "),
    match_count = length(unique(matched_terms))
  )
}

# Initialize result columns
matched_terms_vec <- character(n_rows)
matched_words_vec <- character(n_rows)
matched_sentences_vec <- character(n_rows)
match_counts <- integer(n_rows)

cat("Processing", n_rows, "rows in", n_batches, "batches...\n")

for (i in seq_len(n_batches)) {
  start_idx <- (i - 1) * batch_size + 1
  end_idx <- min(i * batch_size, n_rows)

  batch_text <- merged_data$FULL_TEXT_lower[start_idx:end_idx]

  for (j in seq_along(batch_text)) {
    idx <- start_idx + j - 1
    result <- extract_match_details_regex(batch_text[j], religious_terms)
    matched_terms_vec[idx] <- result$matched_terms
    matched_words_vec[idx] <- result$matched_words
    matched_sentences_vec[idx] <- result$matched_sentences
    match_counts[idx] <- result$match_count
  }

  pct <- round(100 * end_idx / n_rows)
  cat("\r  Batch", i, "/", n_batches, "-", pct, "% complete   ")
  flush.console()
}

cat("\n\nFiltering complete!\n")

# Add new columns and drop helper
merged_data <- merged_data |>
  mutate(
    root_match_count = match_counts,
    matched_terms = matched_terms_vec,
    matched_words = matched_words_vec,
    matched_sentences = matched_sentences_vec
  ) |>
  select(-FULL_TEXT_lower)

# Filter rows with at least 2 matches
filtered_data <- merged_data |> filter(root_match_count >= 2)

cat("Rows with >= 2 term regex matches:", nrow(filtered_data), "\n")
cat("Percentage retained:", round(100 * nrow(filtered_data) / n_rows, 1), "%\n")

# Return filtered data
filtered_data
