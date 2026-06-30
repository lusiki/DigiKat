#!/usr/bin/env Rscript
# R/04_nlp.R — per-page stratified sample + udpipe token annotation for the NLP analytical pages
# (pages/mapa/mapa_stats.qmd, pages/mapa/događaji.qmd).
#
# Replaces the fragile SHARED data/nlp/ design (where two pages sampled at different proportions
# but read the same tokens, so their row_number()-based doc_id spaces could not both match) with
# PER-PAGE {sample, tokens} files whose doc_id is guaranteed to align with the page's sample.
#
# Run from the REPO ROOT:  Rscript R/04_nlp.R
# Reads:  data/merged_comprehensive.rds (master), resources/models/croatian-set-ud-2.5-191206.udpipe
# Writes (data/nlp/ is GITIGNORED — local only; the rendered docs/ are what ship):
#   data/nlp/mapa_stats_sample.rds  + data/nlp/mapa_stats_tokens.rds   (prop 0.05)
#   data/nlp/dogadjaji_sample.rds   + data/nlp/dogadjaji_tokens.rds    (prop 0.03)
#
# Scope: 2021–2026, exclude tiktok, nchar(FULL_TEXT) > 100, stratified by year × SOURCE_TYPE, seed 123.
# HEAVY: udpipe annotation over tens of thousands of docs. Pause Dropbox before running.

suppressPackageStartupMessages({ library(dplyr); library(udpipe) })

master_path <- "data/merged_comprehensive.rds"
model_path  <- "resources/models/croatian-set-ud-2.5-191206.udpipe"
nlp_dir     <- "data/nlp"
SEED        <- 123L

stopifnot(file.exists(master_path), file.exists(model_path))
dir.create(nlp_dir, showWarnings = FALSE, recursive = TRUE)

message("Loading udpipe model …")
model <- udpipe_load_model(model_path)

message("Reading master …")
base <- readRDS(master_path) %>%
  filter(SOURCE_TYPE != "tiktok", !is.na(SOURCE_TYPE)) %>%
  filter(DATE >= as.Date("2021-01-01") & DATE <= as.Date("2026-12-31")) %>%
  filter(year >= 2021 & year <= 2026)
message("  base rows (2021–2026, no tiktok): ", nrow(base))

build_page <- function(prop, label) {
  set.seed(SEED)
  samp <- base %>%
    filter(nchar(FULL_TEXT) > 100) %>%
    group_by(year, SOURCE_TYPE) %>%
    slice_sample(prop = prop) %>%
    ungroup() %>%
    mutate(doc_id = row_number())
  saveRDS(samp, file.path(nlp_dir, sprintf("%s_sample.rds", label)))
  message(sprintf("  [%s] sample = %d docs (prop %.2f) — annotating with udpipe …",
                  label, nrow(samp), prop))
  ann <- udpipe_annotate(model, x = samp$FULL_TEXT,
                         doc_id = as.character(samp$doc_id),
                         tagger = "default", parser = "none")
  tokens <- as.data.frame(ann) %>%
    transmute(doc_id = as.integer(doc_id), token, lemma, upos)
  saveRDS(tokens, file.path(nlp_dir, sprintf("%s_tokens.rds", label)))
  message(sprintf("  [%s] tokens = %d rows over %d docs",
                  label, nrow(tokens), dplyr::n_distinct(tokens$doc_id)))
}

build_page(0.05, "mapa_stats")
build_page(0.03, "dogadjaji")
message("Done. Wrote per-page sample + token files to ", nlp_dir, "/")
