#!/usr/bin/env Rscript
# Compare a candidate aggregate generation with the protected production set.
#
# Example:
#   Rscript R/compare_aggregates.R --candidate-dir=C:/tmp/digikat-preview
#
# The command is read-only. It exits non-zero when any RDS value differs unless
# --allow-differences is supplied for diagnostic reporting.

source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/compare_aggregates.R --candidate-dir=PATH",
    "       [--reference-dir=data/processed] [--allow-differences]",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

candidate_dir <- digikat_cli_value(args, "--candidate-dir", NA_character_)
reference_dir <- digikat_cli_value(args, "--reference-dir", "data/processed")
allow_differences <- digikat_cli_flag(args, "--allow-differences")

if (is.na(candidate_dir) || !nzchar(candidate_dir)) {
  stop("--candidate-dir is required.", call. = FALSE)
}
if (!dir.exists(reference_dir)) stop("Reference directory not found: ", reference_dir, call. = FALSE)
if (!dir.exists(candidate_dir)) stop("Candidate directory not found: ", candidate_dir, call. = FALSE)

rds_names <- function(path) {
  sort(basename(list.files(path, pattern = "\\.rds$", full.names = TRUE)))
}

reference_names <- rds_names(reference_dir)
candidate_names <- rds_names(candidate_dir)
missing_candidate <- setdiff(reference_names, candidate_names)
extra_candidate <- setdiff(candidate_names, reference_names)

if (length(missing_candidate) || length(extra_candidate)) {
  if (length(missing_candidate)) {
    cat("Missing candidate RDS:", paste(missing_candidate, collapse = ", "), "\n")
  }
  if (length(extra_candidate)) {
    cat("Extra candidate RDS:", paste(extra_candidate, collapse = ", "), "\n")
  }
  quit(save = "no", status = 2L)
}

normalize_frame <- function(x) {
  if (!is.data.frame(x)) return(x)
  x[] <- lapply(x, function(column) {
    if (is.factor(column)) as.character(column) else column
  })
  if (nrow(x) > 1L && ncol(x) > 0L) {
    ordering <- do.call(order, c(unname(x), list(na.last = TRUE, method = "radix")))
    x <- x[ordering, , drop = FALSE]
  }
  rownames(x) <- NULL
  x
}

results <- vector("list", length(reference_names))
names(results) <- reference_names

for (name in reference_names) {
  reference <- readRDS(file.path(reference_dir, name))
  candidate <- readRDS(file.path(candidate_dir, name))
  exact <- identical(reference, candidate)
  normalized_reference <- normalize_frame(reference)
  normalized_candidate <- normalize_frame(candidate)
  value_comparison <- all.equal(
    normalized_reference,
    normalized_candidate,
    check.attributes = FALSE
  )
  order_insensitive <- isTRUE(value_comparison)

  numeric_deltas <- numeric()
  if (is.data.frame(reference) && is.data.frame(candidate)) {
    shared_numeric <- intersect(
      names(reference)[vapply(reference, is.numeric, logical(1L))],
      names(candidate)[vapply(candidate, is.numeric, logical(1L))]
    )
    numeric_deltas <- vapply(shared_numeric, function(column) {
      sum(candidate[[column]], na.rm = TRUE) - sum(reference[[column]], na.rm = TRUE)
    }, numeric(1L))
    numeric_deltas <- numeric_deltas[!vapply(
      numeric_deltas,
      function(delta) isTRUE(all.equal(delta, 0)),
      logical(1L)
    )]
  }

  results[[name]] <- list(
    exact = exact,
    order_insensitive = order_insensitive,
    reference_dimensions = paste(dim(reference), collapse = "x"),
    candidate_dimensions = paste(dim(candidate), collapse = "x"),
    names_equal = identical(names(reference), names(candidate)),
    comparison_detail = if (order_insensitive) character() else utils::head(value_comparison, 3L),
    numeric_deltas = numeric_deltas
  )
}

for (name in names(results)) {
  result <- results[[name]]
  status <- if (result$exact) {
    "IDENTICAL"
  } else if (result$order_insensitive) {
    "ORDER_OR_ATTRIBUTES_ONLY"
  } else {
    "VALUE_DIFFERENCE"
  }
  cat(
    name, "|", status,
    "| dimensions", result$reference_dimensions, "->", result$candidate_dimensions,
    "| names_equal", result$names_equal,
    "\n"
  )
  if (length(result$comparison_detail)) {
    for (detail in result$comparison_detail) cat("  comparison:", detail, "\n")
  }
  if (length(result$numeric_deltas)) {
    for (column in names(result$numeric_deltas)) {
      cat("  numeric_total_delta", column, "=", format(result$numeric_deltas[[column]], digits = 16), "\n")
    }
  }
}

n_exact <- sum(vapply(results, `[[`, logical(1L), "exact"))
n_order_only <- sum(vapply(results, function(x) !x$exact && x$order_insensitive, logical(1L)))
n_value <- length(results) - n_exact - n_order_only
cat(
  "Summary: exact =", n_exact,
  "| order/attributes only =", n_order_only,
  "| value differences =", n_value,
  "\n"
)

if (!allow_differences && n_exact != length(results)) {
  quit(save = "no", status = 1L)
}
