#!/usr/bin/env Rscript
# Assemble identity-verified reused decisions and newly coded official-corpus TSV parts.
suppressPackageStartupMessages({ library(here) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
rsp_assert_official_inputs()

refresh_path <- file.path(RSP_OUT, "rsp_audit_refresh_manifest.json")
if (!file.exists(refresh_path)) stop("Audit refresh manifest is missing; run step 30.", call. = FALSE)
refresh <- jsonlite::fromJSON(refresh_path, simplifyVector = TRUE)
checks <- c(r4_sheet = RSP_R4_SHEET, r1_sheet = RSP_R1_SHEET)
for (nm in names(checks)) {
  expected <- as.character(refresh$outputs[[paste0(nm, "_sha256")]])
  if (length(expected) != 1L || !identical(digikat_hash_file(checks[[nm]]), expected)) {
    stop(nm, " does not match the current refresh manifest.", call. = FALSE)
  }
}
if (!identical(digikat_hash_file(RSP_CORE_CACHE), as.character(refresh$inputs$core_sha256)) ||
    !identical(digikat_hash_file(RSP_STAGEA_CANDIDATES),
               as.character(refresh$inputs$candidates_sha256))) {
  stop("Audit refresh inputs no longer match the current core/candidate files.", call. = FALSE)
}

# Keys and allocation tables determine domain assignment, R1 post-stratification weights, and the
# repeat-pass sample. They are private or aggregate design inputs rather than annotations, but they
# are just as consequential and therefore must be present, structurally reconciled, and hash-bound.
r4_alloc_path <- file.path(RSP_OUT, "r4_sample_allocation.csv")
r1_alloc_path <- file.path(RSP_OUT, "r1_sample_allocation.csv")
provenance_path <- file.path(RSP_OUT, "rsp_annotation_provenance.csv")
design_paths <- c(r4_key = RSP_R4_KEY, r1_key = RSP_R1_KEY,
                  r4_allocation = r4_alloc_path, r1_allocation = r1_alloc_path,
                  provenance = provenance_path,
                  r4_reused = RSP_R4_ANN_REUSED, r1_reused = RSP_R1_ANN_REUSED)
missing_design <- design_paths[!file.exists(design_paths)]
if (length(missing_design)) {
  stop("Audit design input(s) are missing: ", paste(missing_design, collapse = ", "), call. = FALSE)
}

r4_sheet_design <- read.csv(RSP_R4_SHEET, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
r1_sheet_design <- read.csv(RSP_R1_SHEET, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
r4_key_design <- read.csv(RSP_R4_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
r1_key_design <- read.csv(RSP_R1_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
digikat_require_columns(r4_key_design, c("item", "rid", "domain"), "R4 key")
digikat_require_columns(r1_key_design, c("item", "rid", "era", "band"), "R1 key")
for (z in list(r4_sheet_design, r1_sheet_design, r4_key_design, r1_key_design)) {
  if (anyDuplicated(z$item)) stop("An audit sheet/key has duplicate item IDs.", call. = FALSE)
}
reconcile_key <- function(sheet, key, label, extra = character()) {
  m <- match(sheet$item, key$item)
  if (nrow(sheet) != nrow(key) || anyNA(m) ||
      any(as.integer(sheet$rid) != as.integer(key$rid[m])) ||
      any(vapply(extra, function(nm) any(as.character(sheet[[nm]]) != as.character(key[[nm]][m])),
                 logical(1)))) {
    stop(label, " sheet and key do not reconcile exactly.", call. = FALSE)
  }
}
reconcile_key(r4_sheet_design, r4_key_design, "R4", "domain")
reconcile_key(r1_sheet_design, r1_key_design, "R1")
if (nrow(r4_sheet_design) != 660L || anyDuplicated(r4_sheet_design[c("rid", "domain")]) ||
    length(unique(r4_sheet_design$domain)) != 11L ||
    any(as.integer(table(r4_sheet_design$domain)) != 60L) ||
    nrow(r1_sheet_design) != 150L || anyDuplicated(r1_sheet_design$rid)) {
  stop("Fresh audit design must contain 660 unique R4 pairs (60 x 11 domains) and 150 unique R1 posts.",
       call. = FALSE)
}

for (p in c(RSP_R4_ANN_REUSED, RSP_R1_ANN_REUSED)) {
  reused_check <- read.delim(p, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  if (nrow(reused_check) != 0L) {
    stop("The declared fresh full-recode design requires an exactly empty reused-label file: ", p,
         call. = FALSE)
  }
}

r4_alloc <- read.csv(r4_alloc_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
r1_alloc <- read.csv(r1_alloc_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
digikat_require_columns(r4_alloc, c("domain", "frame_pairs", "sampled", "reused", "new"),
                        "R4 allocation")
digikat_require_columns(r1_alloc, c("era", "outlet_band", "population", "target", "reused", "new"),
                        "R1 allocation")
if (anyDuplicated(r4_alloc$domain) ||
    sum(as.integer(r4_alloc$sampled)) != nrow(r4_sheet_design) ||
    sum(as.integer(r1_alloc$target)) != nrow(r1_sheet_design) ||
    sum(as.integer(r4_alloc$reused)) != 0L || sum(as.integer(r1_alloc$reused)) != 0L ||
    sum(as.integer(r4_alloc$new)) != nrow(r4_sheet_design) ||
    sum(as.integer(r1_alloc$new)) != nrow(r1_sheet_design)) {
  stop("Audit allocation tables do not reconcile with the fresh sheets.", call. = FALSE)
}

read_parts <- function(dir, cols, label) {
  fs <- list.files(dir, pattern = "\\.tsv$", full.names = TRUE)
  if (!length(fs)) return(data.frame(matrix(nrow = 0, ncol = length(cols), dimnames = list(NULL, cols))))
  out <- do.call(rbind, lapply(fs, function(f)
    read.delim(f, fileEncoding = "UTF-8", stringsAsFactors = FALSE, check.names = FALSE)))
  digikat_require_columns(out, cols, label)
  out[, cols, drop = FALSE]
}
write_tsv <- function(x, path) {
  staged <- tempfile(pattern = paste0(".", basename(path), "-"), tmpdir = dirname(path))
  on.exit(if (file.exists(staged)) unlink(staged), add = TRUE)
  write.table(x, staged, sep = "\t", row.names = FALSE, col.names = TRUE,
              quote = FALSE, fileEncoding = "UTF-8", na = "")
  check <- read.delim(staged, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                      check.names = FALSE)
  if (nrow(check) != nrow(x) || !identical(names(check), names(x))) {
    stop("Staged annotation TSV did not round-trip: ", path, call. = FALSE)
  }
  digikat_atomic_replace_file(staged, path)
}

assemble <- function(sheet_path, reused_path, parts_dir, final_path, cols, allowed, nested = FALSE, label) {
  sheet <- read.csv(sheet_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  reused <- read.delim(reused_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  fresh <- read_parts(parts_dir, cols, paste(label, "new annotation parts"))
  ann <- rbind(reused[, cols, drop = FALSE], fresh[, cols, drop = FALSE])
  ann$item <- as.integer(ann$item); ann$rid <- as.integer(ann$rid)
  if (anyDuplicated(ann$item)) stop(label, " has duplicate item IDs.", call. = FALSE)
  m <- match(ann$item, sheet$item)
  if (anyNA(m) || any(ann$rid != as.integer(sheet$rid[m]))) stop(label, " rid/item mismatch.", call. = FALSE)
  missing <- setdiff(sheet$item, ann$item)
  if (length(missing)) stop(label, " is incomplete; missing item(s): ", paste(missing, collapse = ", "), call. = FALSE)
  for (nm in names(allowed)) if (!all(ann[[nm]] %in% allowed[[nm]]))
    stop(label, " has invalid values in ", nm, call. = FALSE)
  if (isTRUE(nested) && any(ann$ax1_strict == "genuine" & ann$ax1_link_genuine == "incidental"))
    stop(label, " violates strict-genuine nesting.", call. = FALSE)
  ann <- ann[order(ann$item), , drop = FALSE]
  write_tsv(ann, final_path)
  cat(sprintf("[ok] %s: %d complete identity-matched rows -> %s\n", label, nrow(ann), final_path))
  invisible(ann)
}

r4_cols <- c("item", "rid", "ax1_link_genuine", "ax1_strict")
r4 <- assemble(RSP_R4_SHEET, RSP_R4_ANN_REUSED, RSP_R4_NEW_ANN, RSP_R4_ANN, r4_cols,
  list(ax1_link_genuine = c("genuine", "incidental"), ax1_strict = c("genuine", "incidental")),
  nested = TRUE, label = "R4 official")
r1_cols <- c("item", "rid", "r1_invocation", "r2_econ_true")
r1 <- assemble(RSP_R1_SHEET, RSP_R1_ANN_REUSED, RSP_R1_NEW_ANN, RSP_R1_ANN, r1_cols,
  list(r1_invocation = c("genuine", "mention", "false"), r2_econ_true = c("yes", "no")),
  label = "R1 official")

file_records <- function(dir, pattern) {
  fs <- sort(list.files(dir, pattern = pattern, full.names = TRUE))
  lapply(fs, function(f) list(file = basename(f), bytes = unname(file.info(f)$size),
                              sha256 = digikat_hash_file(f)))
}

# The main pass used two non-overlapping Codex contexts. Record the exact batch assignment so the
# context diagnostic is reproducible rather than inferred later from file order.
context_batches <- list(
  A = list(r4 = sprintf("r4_official_batch_%02d", 1:8),
           r1 = sprintf("r1_official_batch_%02d", 1:2), r4_rows = 320L, r1_rows = 80L),
  B = list(r4 = sprintf("r4_official_batch_%02d", 9:17),
           r1 = sprintf("r1_official_batch_%02d", 3:4), r4_rows = 340L, r1_rows = 70L)
)
expected_stems <- function(audit) unlist(lapply(context_batches, `[[`, audit), use.names = FALSE)
assert_batch_set <- function(dir, ext, audit, label) {
  got <- tools::file_path_sans_ext(basename(list.files(dir, pattern = paste0("\\.", ext, "$"),
                                                       full.names = TRUE)))
  expected <- expected_stems(audit)
  if (!setequal(got, expected) || anyDuplicated(got)) {
    stop(label, " batch set does not match the declared coder-context assignment.", call. = FALSE)
  }
}
assert_batch_set(RSP_R4_BATCHES, "md", "r4", "R4 prompt")
assert_batch_set(RSP_R1_BATCHES, "md", "r1", "R1 prompt")
assert_batch_set(RSP_R4_NEW_ANN, "tsv", "r4", "R4 annotation")
assert_batch_set(RSP_R1_NEW_ANN, "tsv", "r1", "R1 annotation")
assert_prompt_annotation_identity <- function(prompt_dir, ann_dir, stems, label) {
  for (stem in stems) {
    lines <- readLines(file.path(prompt_dir, paste0(stem, ".md")), encoding = "UTF-8", warn = FALSE)
    headers <- grep("^### (ITEM|CARD) [0-9]+ \\| rid=[0-9]+", lines, value = TRUE)
    item <- as.integer(sub("^### (?:ITEM|CARD) ([0-9]+) \\|.*$", "\\1", headers, perl = TRUE))
    rid <- as.integer(sub("^.*\\| rid=([0-9]+).*$", "\\1", headers, perl = TRUE))
    ann_part <- read.delim(file.path(ann_dir, paste0(stem, ".tsv")), fileEncoding = "UTF-8",
                           stringsAsFactors = FALSE)
    if (!length(item) || anyNA(item) || anyNA(rid) || anyDuplicated(item) ||
        nrow(ann_part) != length(item) || anyDuplicated(ann_part$item) ||
        !setequal(paste(item, rid), paste(as.integer(ann_part$item), as.integer(ann_part$rid)))) {
      stop(label, " prompt/annotation identity mismatch in ", stem, ".", call. = FALSE)
    }
  }
}
assert_prompt_annotation_identity(RSP_R4_BATCHES, RSP_R4_NEW_ANN, expected_stems("r4"), "R4")
assert_prompt_annotation_identity(RSP_R1_BATCHES, RSP_R1_NEW_ANN, expected_stems("r1"), "R1")
batch_rows <- function(dir, stems) sum(vapply(stems, function(stem)
  nrow(read.delim(file.path(dir, paste0(stem, ".tsv")), fileEncoding = "UTF-8",
                  stringsAsFactors = FALSE)), integer(1)))
for (ctx in names(context_batches)) {
  z <- context_batches[[ctx]]
  if (batch_rows(RSP_R4_NEW_ANN, z$r4) != z$r4_rows ||
      batch_rows(RSP_R1_NEW_ANN, z$r1) != z$r1_rows) {
    stop("Coder-context ", ctx, " row counts disagree with the declared assignment.", call. = FALSE)
  }
}
coding_manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/31_assemble_rsp_annotations.R",
  database_sha256 = rsp_read_input_manifest()$database$sha256,
  sample = list(r4_sheet_sha256 = digikat_hash_file(RSP_R4_SHEET),
                r1_sheet_sha256 = digikat_hash_file(RSP_R1_SHEET),
                r4_key_sha256 = digikat_hash_file(RSP_R4_KEY),
                r1_key_sha256 = digikat_hash_file(RSP_R1_KEY),
                r4_allocation_sha256 = digikat_hash_file(r4_alloc_path),
                r1_allocation_sha256 = digikat_hash_file(r1_alloc_path),
                provenance_sha256 = digikat_hash_file(provenance_path),
                r4_reused_sha256 = digikat_hash_file(RSP_R4_ANN_REUSED),
                r1_reused_sha256 = digikat_hash_file(RSP_R1_ANN_REUSED),
                refresh_manifest_sha256 = digikat_hash_file(refresh_path)),
  coding = list(
    system = "OpenAI Codex bounded subagents",
    backend_model_identifier = "not exposed to this session",
    decoding_settings = "not exposed to this session",
    date = as.character(Sys.Date()),
    passes = 1L,
    independence = "two disjoint batch assignments; coders instructed to use only blind batch files",
    context_batches = context_batches,
    raw_outputs_retained = "restricted per-batch TSV files in output/private",
    caveat = paste("Stable row IDs were visible and answer keys existed in the same restricted workspace;",
                   "procedural blinding therefore depends on the enforced task instructions.")),
  prompts = list(r4 = file_records(RSP_R4_BATCHES, "\\.md$"),
                 r1 = file_records(RSP_R1_BATCHES, "\\.md$")),
  raw_annotations = list(r4 = file_records(RSP_R4_NEW_ANN, "\\.tsv$"),
                         r1 = file_records(RSP_R1_NEW_ANN, "\\.tsv$")),
  assembled = list(r4_rows = nrow(r4), r4_sha256 = digikat_hash_file(RSP_R4_ANN),
                   r1_rows = nrow(r1), r1_sha256 = digikat_hash_file(RSP_R1_ANN))
)
digikat_write_json_atomic(coding_manifest, file.path(RSP_OUT, "rsp_coding_manifest.json"))

cat(sprintf("assembled %d R4 pairs and %d R1 cards\n", nrow(r4), nrow(r1)))
cat("coding provenance -> output/rsp_coding_manifest.json\n")
