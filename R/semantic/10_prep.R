#!/usr/bin/env Rscript
# R/semantic/10_prep.R  —  Level 3 (Meaning search), step 1 of 3
# Slice the master into a LEAN table ready for embedding, and write it to
# data/semantic/corpus_prepared.rds. Reads the corpus READ-ONLY; writes ONLY
# into data/semantic/ (gitignored + Dropbox-ignored). Never touches the master,
# data/processed/*.rds, or docs/.
#
# Output columns (one row = one post = one future vector):
#   doc_id | platform | date | data_source | actor | url | text
#
# Run where R + the master live (see CLAUDE.local.md):
#   Rscript R/semantic/10_prep.R
suppressPackageStartupMessages({ library(here); library(dplyr) })

# --- source: master, or the synthetic sample as a fallback (like slice.R) ---------------------
USE_SAMPLE <- !file.exists(here::here("data/merged_comprehensive.rds"))
src <- if (USE_SAMPLE) here::here("data/sample/merged_sample.rds") else here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("No corpus found (need the master or data/sample/). See CLAUDE.local.md.")
cat("Reading corpus:", src, if (USE_SAMPLE) "(SAMPLE — not the full corpus)\n" else "(full master)\n")

corpus <- readRDS(src)
# master is a data.table; convert in place (setDF) — as.data.frame() deep-copies ~all columns
# and briefly doubles peak RAM on the ~1.2 GB master (same guard as studies/*/slice.R).
if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)

# --- map semantic fields -> confirmed master columns; fail LOUD if a name drifted -------------
# text/platform/date are REQUIRED; actor/url/stream are best-effort (kept if present).
colmap <- c(text = "FULL_TEXT", platform = "SOURCE_TYPE", date = "DATE",
            data_source = "data_source", actor = "FROM", url = "URL")
required <- c("text", "platform", "date")
miss_req <- setdiff(colmap[required], names(corpus))
if (length(miss_req))
  stop("Master is missing required column(s): ", paste(miss_req, collapse = ", "),
       "\n  Present columns include: ", paste(utils::head(names(corpus), 60), collapse = ", "))

have <- colmap[colmap %in% names(corpus)]
lean <- as.data.frame(corpus[, have, drop = FALSE])
names(lean) <- names(have)
for (opt in setdiff(names(colmap), names(have))) {   # fill absent optional fields with NA, note it
  cat("NOTE: optional column '", colmap[[opt]], "' absent — '", opt, "' set to NA.\n", sep = "")
  lean[[opt]] <- NA_character_
}
rm(corpus); invisible(gc())

# --- normalize + provenance -------------------------------------------------------------------
n0 <- nrow(lean)
lean$doc_id      <- sprintf("dk_%08d", seq_len(n0))            # stable within THIS build (master has no id)
lean$text        <- trimws(as.character(lean$text))
lean$date        <- as.Date(as.character(lean$date))           # DATE is CHARACTER ISO in the master
lean$platform    <- as.character(lean$platform)
lean$data_source <- as.character(lean$data_source)
lean$actor       <- as.character(lean$actor)
lean$url         <- as.character(lean$url)

# --- drop rows with no usable text (can't embed an empty string) ------------------------------
empty <- is.na(lean$text) | lean$text == ""
if (any(empty)) cat("Dropping", sum(empty), "of", n0, "rows with empty/NA FULL_TEXT.\n")
lean <- lean[!empty, , drop = FALSE]

na_date <- sum(is.na(lean$date))
if (na_date) cat("NOTE:", na_date, "rows have NA/unparseable DATE (kept; date-filtered analyses will drop them).\n")

lean <- lean[, c("doc_id", "platform", "date", "data_source", "actor", "url", "text")]

# --- write into data/semantic/ ONLY -----------------------------------------------------------
out_dir <- here::here("data/semantic")
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
out <- file.path(out_dir, "corpus_prepared.rds")
saveRDS(lean, out)

cat("\nPrepared corpus:", nrow(lean), "rows x", ncol(lean), "cols ->", out,
    if (USE_SAMPLE) "(FROM SAMPLE)\n" else "\n")
cat("  platforms:", paste(utils::head(sort(unique(lean$platform)), 12), collapse = ", "), "\n")
cat("  streams  :", paste(sort(unique(stats::na.omit(lean$data_source))), collapse = ", "), "\n")
cat("  date span:", format(min(lean$date, na.rm = TRUE)), "->", format(max(lean$date, na.rm = TRUE)), "\n")
cat("NEXT: Rscript R/semantic/11_build.R  (needs Ollama running + `ollama pull bge-m3`).\n")
