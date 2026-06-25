#!/usr/bin/env Rscript
# Study slice: <slug>
# Materialize this study's corpus slice from the master (or the sample).
# Reads the corpus READ-ONLY; writes ONLY into this study's output/ folder. Never writes data/.
suppressPackageStartupMessages({ library(here); library(dplyr) })
set.seed(20260625)  # set to the study's own start date (YYYYMMDD)

USE_SAMPLE <- !file.exists(here::here("data/merged_comprehensive.rds"))
src <- if (USE_SAMPLE) here::here("data/sample/merged_sample.rds") else here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("No corpus found (need the master or data/sample/). See CLAUDE.local.md.")

corpus <- readRDS(src)

# --- define the slice (EDIT per study) ---
slice <- corpus
#   |> filter(platform == "youtube")
#   |> filter(grepl("<theme regex>", matched_terms))
#   |> filter(year >= 2021, year <= 2025)

out_dir <- here::here("studies/<slug>/output")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
saveRDS(slice, file.path(out_dir, "slice.rds"))
cat("Slice:", nrow(slice), "rows ->", file.path(out_dir, "slice.rds"),
    if (USE_SAMPLE) "(FROM SAMPLE — not the full corpus)" else "", "\n")
