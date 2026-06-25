#!/usr/bin/env Rscript
# =============================================================================
# R/make_sample.R
# Build a SMALL, SHAREABLE synthetic sample of the master corpus so anyone can
# run the pipeline + render the data pages WITHOUT the gitignored master.
# Strategy: stratified ~500-row draw (platform x year), then SCRUB free text and
# author/account PII so the result is safe to commit (CC BY 4.0).
#
# Run where the master lives:  Rscript R/make_sample.R
# Output: data/sample/merged_sample.rds  (tracked in git)
#
# NOTE: the column-name lists below are best-effort — ADJUST them to the real
# schema (run names(readRDS(master)) once) and ALWAYS run /disclosure-check on
# the output before committing.
# =============================================================================
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringi) })
set.seed(20260625)

master_path <- here::here("data/merged_comprehensive.rds")
out_dir     <- here::here("data/sample")
out         <- file.path(out_dir, "merged_sample.rds")
N_TARGET    <- 500L

if (!file.exists(master_path))
  stop("Master not found: ", master_path, "\nRun this on the pipeline machine where the master lives.")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

df <- as.data.frame(readRDS(master_path))

# --- stratified draw by platform x year, if those columns exist ---
strata_cols <- intersect(c("platform", "PLATFORM", "source_type", "year", "YEAR"), names(df))
if (length(strata_cols) >= 1L) {
  df$.stratum <- interaction(df[strata_cols], drop = TRUE)
  per  <- max(1L, floor(N_TARGET / nlevels(df$.stratum)))
  samp <- df |> group_by(.stratum) |> slice_sample(n = per) |> ungroup()
  if (nrow(samp) > N_TARGET) samp <- samp |> slice_sample(n = N_TARGET)
  samp$.stratum <- NULL
} else {
  samp <- df |> slice_sample(n = min(N_TARGET, nrow(df)))
}

# --- SCRUB free text + redact author/account PII (disclosure safety) ---
text_cols   <- intersect(c("FULL_TEXT", "TITLE", "DESCRIPTION", "title", "text", "content"), names(samp))
author_cols <- intersect(c("AUTHOR", "author", "account", "ACCOUNT", "user", "USER", "FROM", "from_name"), names(samp))
for (cl in text_cols)   samp[[cl]] <- "[SAMPLE TEXT REDACTED — synthetic placeholder for structure only]"
for (cl in author_cols) samp[[cl]] <- "[REDACTED]"
if ("URL" %in% names(samp))            # keep domain for structure, drop the path
  samp$URL <- stri_replace_all_regex(samp$URL, "(https?://[^/]+).*", "$1/[redacted]")

attr(samp, "digikat_sample") <- TRUE
attr(samp, "generated_utc")  <- format(Sys.time(), tz = "UTC")
saveRDS(samp, out)

cat("Wrote", out, "—", nrow(samp), "rows,", ncol(samp), "cols (text + author columns scrubbed).\n")
cat("Scrubbed text cols:  ", if (length(text_cols))   paste(text_cols, collapse = ", ")   else "(none matched — CHECK schema!)", "\n")
cat("Redacted author cols:", if (length(author_cols)) paste(author_cols, collapse = ", ") else "(none matched — CHECK schema!)", "\n")
cat("REVIEW it and run /disclosure-check before committing; confirm no real post text or PII remains.\n")
