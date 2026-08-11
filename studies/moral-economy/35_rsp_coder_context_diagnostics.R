#!/usr/bin/env Rscript
# Aggregate-only diagnostic for the two disjoint Codex contexts used in the fresh R4/R1 main pass.
#
# The context split was operational rather than randomized and contains no overlapping cards. These
# rates therefore diagnose batch/context sensitivity; they are not inter-coder reliability or causal
# coder effects. Private item labels are read only to produce grouped counts and rates.
suppressPackageStartupMessages({ library(here) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/cst_core.R"))
rsp_assert_official_inputs()

CODING_PATH <- file.path(RSP_OUT, "rsp_coding_manifest.json")
OUT <- file.path(RSP_OUT, "rsp_coder_context_diagnostics.csv")
MANIFEST_OUT <- file.path(RSP_OUT, "rsp_coder_context_manifest.json")
if (!file.exists(CODING_PATH)) stop("Coding manifest is missing; run step 31.", call. = FALSE)
coding <- jsonlite::fromJSON(CODING_PATH, simplifyVector = FALSE)
if (!identical(as.character(coding$database_sha256),
               as.character(rsp_read_input_manifest()$database$sha256))) {
  stop("Coding manifest does not belong to the current official database.", call. = FALSE)
}

assert_hash <- function(path, expected, label) {
  expected <- as.character(expected)
  if (!file.exists(path) || length(expected) != 1L || is.na(expected) || !nzchar(expected) ||
      !identical(digikat_hash_file(path), expected)) {
    stop(label, " does not match the coding manifest.", call. = FALSE)
  }
}
assert_hash(RSP_R4_SHEET, coding$sample$r4_sheet_sha256, "R4 sheet")
assert_hash(RSP_R1_SHEET, coding$sample$r1_sheet_sha256, "R1 sheet")
assert_hash(RSP_R4_KEY, coding$sample$r4_key_sha256, "R4 key")
assert_hash(RSP_R1_KEY, coding$sample$r1_key_sha256, "R1 key")
assert_hash(RSP_R4_ANN, coding$assembled$r4_sha256, "R4 assembled annotation")
assert_hash(RSP_R1_ANN, coding$assembled$r1_sha256, "R1 assembled annotation")

contexts <- coding$coding$context_batches
if (!setequal(names(contexts), c("A", "B"))) {
  stop("Coding manifest must declare exactly coder contexts A and B.", call. = FALSE)
}

verify_raw_records <- function(records, dir, label) {
  for (z in records) assert_hash(file.path(dir, z$file), z$sha256,
                                 paste(label, z$file))
}
verify_raw_records(coding$raw_annotations$r4, RSP_R4_NEW_ANN, "R4 raw annotation")
verify_raw_records(coding$raw_annotations$r1, RSP_R1_NEW_ANN, "R1 raw annotation")

read_context <- function(context, audit) {
  z <- contexts[[context]]
  stems <- unlist(z[[audit]], use.names = FALSE)
  dir <- if (audit == "r4") RSP_R4_NEW_ANN else RSP_R1_NEW_ANN
  parts <- lapply(stems, function(stem) {
    p <- file.path(dir, paste0(stem, ".tsv"))
    x <- read.delim(p, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
    x$batch <- stem
    x
  })
  out <- do.call(rbind, parts)
  out$context <- context
  expected_n <- as.integer(z[[paste0(audit, "_rows")]])
  if (nrow(out) != expected_n || anyDuplicated(out$item)) {
    stop("Coder context ", context, " has an invalid ", toupper(audit), " allocation.",
         call. = FALSE)
  }
  out
}

r4 <- do.call(rbind, lapply(names(contexts), read_context, audit = "r4"))
r1 <- do.call(rbind, lapply(names(contexts), read_context, audit = "r1"))
rownames(r4) <- NULL; rownames(r1) <- NULL

# Reconcile every private batch decision to the final assembled file, then discard row identities
# from the object that is written publicly.
final_r4 <- read.delim(RSP_R4_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
final_r1 <- read.delim(RSP_R1_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
reconcile_final <- function(parts, final, label, code_cols) {
  m <- match(parts$item, final$item)
  if (nrow(parts) != nrow(final) || anyNA(m) ||
      any(as.integer(parts$rid) != as.integer(final$rid[m])) ||
      any(vapply(code_cols, function(nm) any(as.character(parts[[nm]]) !=
                                               as.character(final[[nm]][m])), logical(1)))) {
    stop(label, " batch decisions do not reconcile to the assembled annotation.", call. = FALSE)
  }
}
reconcile_final(r4, final_r4, "R4", c("ax1_link_genuine", "ax1_strict"))
reconcile_final(r1, final_r1, "R1", c("r1_invocation", "r2_econ_true"))

r4_key <- read.csv(RSP_R4_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
m4 <- match(r4$item, r4_key$item)
if (anyNA(m4) || any(as.integer(r4$rid) != as.integer(r4_key$rid[m4]))) {
  stop("R4 context decisions do not match the current design key.", call. = FALSE)
}
r4$domain <- as.character(r4_key$domain[m4])

summary_row <- function(context, audit, metric, hit) {
  data.frame(section = "context_overall", context = context, audit = audit, metric = metric,
             domain = "all", n = length(hit), k = sum(hit), rate_pct = 100 * mean(hit),
             linked_pairs = NA_integer_, marked_pairs = NA_integer_,
             denominator_sensitivity_pct = NA_real_, rank = NA_integer_,
             stringsAsFactors = FALSE)
}
summary_rows <- do.call(rbind, lapply(names(contexts), function(ctx) {
  a4 <- r4[r4$context == ctx, ]; a1 <- r1[r1$context == ctx, ]
  rbind(
    summary_row(ctx, "R4", "ax1_link_genuine", a4$ax1_link_genuine == "genuine"),
    summary_row(ctx, "R4", "ax1_strict", a4$ax1_strict == "genuine"),
    summary_row(ctx, "R1", "r1_invocation", a1$r1_invocation == "genuine"),
    summary_row(ctx, "R1", "r2_econ_true", a1$r2_econ_true == "yes"))
}))

cand <- readRDS(RSP_STAGEA_CANDIDATES)
frame <- unique(cand[, c("rid", "domain")])
linked <- as.data.frame(table(domain = frame$domain), stringsAsFactors = FALSE)
names(linked)[2] <- "linked_pairs"
core <- cst_build_core(verbose = FALSE)
pairs <- cst_core_pairs(core)
marked <- as.data.frame(table(domain = factor(pairs$domain, levels = ME_DOMAINS)),
                        stringsAsFactors = FALSE)
names(marked) <- c("domain", "marked_pairs")
marked$domain <- as.character(marked$domain)
census <- merge(linked, marked, by = "domain", all = TRUE)
census$linked_pairs[is.na(census$linked_pairs)] <- 0L
census$marked_pairs[is.na(census$marked_pairs)] <- 0L
if (!setequal(census$domain, ME_DOMAINS) || sum(census$linked_pairs) != 79439L ||
    sum(census$marked_pairs) != 1290L) {
  stop("Current domain census does not reconcile to the official pair populations.", call. = FALSE)
}

domain_rows <- do.call(rbind, lapply(names(contexts), function(ctx) {
  z <- r4[r4$context == ctx, ]
  out <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
    take <- z$domain == d
    n <- sum(take); k <- sum(z$ax1_link_genuine[take] == "genuine")
    j <- match(d, census$domain)
    precision <- if (n) k / n else NA_real_
    sensitivity <- if (is.finite(precision) && precision > 0)
      100 * census$marked_pairs[j] / (census$linked_pairs[j] * precision) else NA_real_
    data.frame(section = "r4_domain", context = ctx, audit = "R4",
               metric = "ax1_link_genuine", domain = d, n = n, k = k,
               rate_pct = 100 * precision, linked_pairs = as.integer(census$linked_pairs[j]),
               marked_pairs = as.integer(census$marked_pairs[j]),
               denominator_sensitivity_pct = sensitivity, rank = NA_integer_,
               stringsAsFactors = FALSE)
  }))
  out$rank <- rank(-out$denominator_sensitivity_pct, ties.method = "min", na.last = "keep")
  out
}))

diagnostic <- rbind(summary_rows, domain_rows)
diagnostic$rate_pct <- round(diagnostic$rate_pct, 3)
diagnostic$denominator_sensitivity_pct <- round(diagnostic$denominator_sensitivity_pct, 3)
if (nrow(diagnostic) != 30L ||
    any(domain_rows$n <= 0L) ||
    anyNA(domain_rows$denominator_sensitivity_pct) ||
    any(domain_rows$rank[domain_rows$domain == "green_energy"] != 1L)) {
  stop("Coder-context aggregate diagnostics are incomplete or do not reproduce the domain ranking.",
       call. = FALSE)
}
sem_write_shareable(diagnostic, OUT)

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/35_rsp_coder_context_diagnostics.R",
  inputs = list(
    database_sha256 = rsp_read_input_manifest()$database$sha256,
    coding_manifest_sha256 = digikat_hash_file(CODING_PATH),
    candidates_sha256 = digikat_hash_file(RSP_STAGEA_CANDIDATES),
    core_sha256 = digikat_hash_file(RSP_CORE_CACHE),
    r4_key_sha256 = digikat_hash_file(RSP_R4_KEY),
    r1_key_sha256 = digikat_hash_file(RSP_R1_KEY),
    r4_annotation_sha256 = digikat_hash_file(RSP_R4_ANN),
    r1_annotation_sha256 = digikat_hash_file(RSP_R1_ANN)),
  context_batches = contexts,
  output = list(path = "output/rsp_coder_context_diagnostics.csv",
                sha256 = digikat_hash_file(OUT), rows = nrow(diagnostic)),
  interpretation = paste(
    "Descriptive model-context diagnostic only. Contexts received disjoint, non-randomized batches",
    "with no common cards, so context differences combine batch composition and model-pass variation."))
digikat_write_json_atomic(manifest, MANIFEST_OUT)

cat("wrote aggregate coder-context diagnostic: ", OUT, "\n", sep = "")
cat("context provenance -> ", MANIFEST_OUT, "\n", sep = "")
