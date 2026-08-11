#!/usr/bin/env Rscript
# Blind repeat-pass check for the fresh official-corpus audit labels.
#
# Default mode draws 6 R4 pairs per domain plus 30 R1 cards and emits three blind
# batches. `--score` joins returned TSV parts to the withheld labels and fails if raw agreement on
# any axis is below 0.80. This measures model-pass stability, not independent human reliability.
suppressPackageStartupMessages({ library(here) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
rsp_assert_official_inputs()

ARGS <- commandArgs(trailingOnly = TRUE)
SCORE <- "--score" %in% ARGS
ALLOW_FAILED <- "--allow-failed-gate" %in% ARGS
BDIR <- file.path(RSP_PRIVATE, "rsp_stability_batches_full_recode")
ADIR <- file.path(RSP_PRIVATE, "rsp_stability_annotations_full_recode")
KEY <- file.path(RSP_PRIVATE, "rsp_stability_key_full_recode.tsv")
CODING_MANIFEST <- file.path(RSP_OUT, "rsp_coding_manifest.json")
STABILITY_OUT <- file.path(ME_OUT, "rsp_annotation_stability.csv")
TRANSITION_OUT <- file.path(ME_OUT, "rsp_stability_transitions.csv")
DOMAIN_OUT <- file.path(ME_OUT, "rsp_stability_r1_by_domain.csv")
dir.create(BDIR, recursive = TRUE, showWarnings = FALSE)
dir.create(ADIR, recursive = TRUE, showWarnings = FALSE)

if (ALLOW_FAILED && !SCORE) {
  stop("--allow-failed-gate is valid only together with --score.", call. = FALSE)
}
if (!file.exists(CODING_MANIFEST)) {
  stop("Current coding manifest is missing; run step 31.", call. = FALSE)
}
coding_manifest <- jsonlite::fromJSON(CODING_MANIFEST, simplifyVector = TRUE)
if (!identical(as.character(coding_manifest$database_sha256),
               as.character(rsp_read_input_manifest()$database$sha256))) {
  stop("Coding manifest is not bound to the current official database.", call. = FALSE)
}
assert_hash <- function(path, expected, label) {
  expected <- as.character(expected)
  if (!file.exists(path) || length(expected) != 1L || is.na(expected) || !nzchar(expected) ||
      !identical(digikat_hash_file(path), expected)) {
    stop(label, " does not match the current coding manifest.", call. = FALSE)
  }
}
r4_alloc_path <- file.path(RSP_OUT, "r4_sample_allocation.csv")
r1_alloc_path <- file.path(RSP_OUT, "r1_sample_allocation.csv")
assert_hash(RSP_R4_SHEET, coding_manifest$sample$r4_sheet_sha256, "R4 sheet")
assert_hash(RSP_R1_SHEET, coding_manifest$sample$r1_sheet_sha256, "R1 sheet")
assert_hash(RSP_R4_KEY, coding_manifest$sample$r4_key_sha256, "R4 key")
assert_hash(RSP_R1_KEY, coding_manifest$sample$r1_key_sha256, "R1 key")
assert_hash(r4_alloc_path, coding_manifest$sample$r4_allocation_sha256, "R4 allocation")
assert_hash(r1_alloc_path, coding_manifest$sample$r1_allocation_sha256, "R1 allocation")
assert_hash(RSP_R4_ANN, coding_manifest$assembled$r4_sha256, "R4 main annotation")
assert_hash(RSP_R1_ANN, coding_manifest$assembled$r1_sha256, "R1 main annotation")

write_tsv <- function(x, p) write.table(x, p, sep = "\t", row.names = FALSE, col.names = TRUE,
                                        quote = FALSE, fileEncoding = "UTF-8", na = "")
flat <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
draw_rows <- function(x, n) {
  n <- as.integer(n)
  if (nrow(x) < n) stop("Repeat-pass sampling pool has ", nrow(x), " rows; expected at least ", n,
                        ".", call. = FALSE)
  x[sample.int(nrow(x), n), , drop = FALSE]
}

if (!SCORE) {
  stale_annotations <- list.files(ADIR, pattern = "\\.tsv$", full.names = TRUE)
  if (length(stale_annotations)) {
    stop("Repeat annotation directory is not empty. Archive or remove its TSV files before drawing ",
         "a new key; refusing to overwrite a key that stale annotations could be scored against.",
         call. = FALSE)
  }
  r4s <- read.csv(RSP_R4_SHEET, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  r4k <- read.csv(RSP_R4_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  r4a <- read.delim(RSP_R4_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  if (anyDuplicated(r4s$item) || anyDuplicated(r4k$item) || anyDuplicated(r4a$item) ||
      nrow(r4s) != 660L || nrow(r4k) != 660L || nrow(r4a) != 660L) {
    stop("Current R4 sheet/key/annotation must be one-to-one and contain exactly 660 rows.",
         call. = FALSE)
  }
  r4 <- merge(r4s, r4k[, c("item", "domain", "provenance")], by = c("item", "domain"))
  r4 <- r4[, setdiff(names(r4), c("ax1_link_genuine", "ax1_strict")), drop = FALSE]
  r4 <- merge(r4, r4a, by = c("item", "rid"))
  if (nrow(r4) != 660L || anyDuplicated(r4$item) ||
      !setequal(names(table(r4$domain)), ME_DOMAINS) ||
      any(as.integer(table(factor(r4$domain, levels = ME_DOMAINS))) != 60L)) {
    stop("Current R4 merge must contain exactly 60 unique pairs in each of 11 domains.",
         call. = FALSE)
  }
  set.seed(ME_SEED + 501L)
  r4 <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
    draw_rows(r4[r4$domain == d, , drop = FALSE], 6L)
  }))
  if (nrow(r4) != 66L || anyDuplicated(r4$item) ||
      any(as.integer(table(factor(r4$domain, levels = ME_DOMAINS))) != 6L)) {
    stop("R4 repeat draw must contain exactly 6 unique pairs per domain (66 total).", call. = FALSE)
  }

  r1s <- read.csv(RSP_R1_SHEET, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  r1k <- read.csv(RSP_R1_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  r1a <- read.delim(RSP_R1_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  if (anyDuplicated(r1s$item) || anyDuplicated(r1k$item) || anyDuplicated(r1a$item) ||
      nrow(r1s) != 150L || nrow(r1k) != 150L || nrow(r1a) != 150L) {
    stop("Current R1 sheet/key/annotation must be one-to-one and contain exactly 150 rows.",
         call. = FALSE)
  }
  r1 <- merge(r1s, r1k[, c("item", "era", "band", "provenance")], by = "item")
  r1 <- r1[, setdiff(names(r1), c("r1_invocation", "r2_econ_true")), drop = FALSE]
  r1 <- merge(r1, r1a, by = c("item", "rid"))
  if (nrow(r1) != 150L || anyDuplicated(r1$item)) {
    stop("Current R1 merge must contain all 150 unique main-pass cards.", call. = FALSE)
  }
  set.seed(ME_SEED + 502L)
  r1 <- draw_rows(r1, 30L)
  if (nrow(r1) != 30L || anyDuplicated(r1$item)) {
    stop("R1 repeat draw must contain exactly 30 unique cards.", call. = FALSE)
  }

  key <- rbind(
    data.frame(audit = "R4", item = r4$item, rid = r4$rid, expected1 = r4$ax1_link_genuine,
               expected2 = r4$ax1_strict, stringsAsFactors = FALSE),
    data.frame(audit = "R1", item = r1$item, rid = r1$rid, expected1 = r1$r1_invocation,
               expected2 = r1$r2_econ_true, stringsAsFactors = FALSE))
  if (nrow(key) != 96L || anyDuplicated(paste(key$audit, key$item)) ||
      sum(key$audit == "R4") != 66L || sum(key$audit == "R1") != 30L) {
    stop("Repeat key cardinality failed.", call. = FALSE)
  }
  write_tsv(key, KEY)

  # Allocate each audit round-robin so every pass sees both coding tasks.
  r4$batch <- rep(1:3, length.out = nrow(r4)); r1$batch <- rep(1:3, length.out = nrow(r1))
  for (b in 1:3) {
    a <- r4[r4$batch == b, ]; c <- r1[r1$batch == b, ]
    lines <- c(sprintf("# Repeat-pass stability batch %d of 3", b), "",
      "Return one TSV row per item with: audit<TAB>item<TAB>rid<TAB>code1<TAB>code2", "",
      "For R4: code1 = ax1_link_genuine and code2 = ax1_strict, each genuine|incidental.",
      "Strict-genuine requires link-genuine. Default to incidental when uncertain.",
      "For R1: code1 = r1_invocation (genuine|mention|false); code2 = r2_econ_true (yes|no).", "")
    for (i in seq_len(nrow(a))) lines <- c(lines,
      sprintf("### R4 | ITEM %d | rid=%s | domain=%s", a$item[i], a$rid[i], a$domain[i]),
      sprintf("WINDOW: %s", flat(a$window[i])), sprintf("TEXT: %s", flat(a$text_800[i])), "")
    for (i in seq_len(nrow(c))) lines <- c(lines,
      sprintf("### R1 | ITEM %d | rid=%s", c$item[i], c$rid[i]), flat(c$excerpt[i]), "")
    writeLines(lines, file.path(BDIR, sprintf("stability_batch_%02d.md", b)), useBytes = FALSE)
  }
  cat(sprintf("built three stability batches: %d R4 + %d R1 items\n", nrow(r4), nrow(r1)))
  cat("annotations -> ", ADIR, "\n", sep = "")
  quit(save = "no")
}

expected_prompt_names <- sprintf("stability_batch_%02d.md", 1:3)
expected_annotation_names <- sprintf("stability_batch_%02d.tsv", 1:3)
prompt_fs <- sort(list.files(BDIR, pattern = "\\.md$", full.names = TRUE))
fs <- sort(list.files(ADIR, pattern = "\\.tsv$", full.names = TRUE))
if (!identical(basename(prompt_fs), expected_prompt_names)) {
  stop("Repeat prompt directory must contain exactly stability_batch_01.md through _03.md.",
       call. = FALSE)
}
if (!identical(basename(fs), expected_annotation_names)) {
  stop("Repeat annotation directory must contain exactly stability_batch_01.tsv through _03.tsv.",
       call. = FALSE)
}
if (!file.exists(KEY)) stop("Repeat-pass key is missing; run the draw mode first.", call. = FALSE)

parse_prompt_cards <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  headers <- grep("^### R[14] \\| ITEM [0-9]+ \\| rid=[0-9]+", lines, value = TRUE)
  data.frame(
    audit = sub("^### (R[14]) \\|.*$", "\\1", headers),
    item = as.integer(sub("^.*\\| ITEM ([0-9]+) \\|.*$", "\\1", headers)),
    rid = as.integer(sub("^.*\\| rid=([0-9]+).*$", "\\1", headers)),
    stringsAsFactors = FALSE)
}
ann_parts <- vector("list", length(fs))
prompt_parts <- vector("list", length(prompt_fs))
for (i in seq_along(fs)) {
  ann_parts[[i]] <- read.delim(fs[[i]], fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  prompt_parts[[i]] <- parse_prompt_cards(prompt_fs[[i]])
  digikat_require_columns(ann_parts[[i]], c("audit", "item", "rid", "code1", "code2"),
                          paste("stability annotation", basename(fs[[i]])))
  if (nrow(ann_parts[[i]]) != 32L || nrow(prompt_parts[[i]]) != 32L ||
      anyNA(prompt_parts[[i]]$item) || anyNA(prompt_parts[[i]]$rid) ||
      !setequal(paste(ann_parts[[i]]$audit, ann_parts[[i]]$item, ann_parts[[i]]$rid),
                paste(prompt_parts[[i]]$audit, prompt_parts[[i]]$item, prompt_parts[[i]]$rid))) {
    stop("Repeat prompt/annotation identity mismatch in batch ", i, ".", call. = FALSE)
  }
}
ann <- do.call(rbind, ann_parts)
digikat_require_columns(ann, c("audit", "item", "rid", "code1", "code2"), "stability annotation")
key <- read.delim(KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
digikat_require_columns(key, c("audit", "item", "rid", "expected1", "expected2"), "stability key")
ann$item <- as.integer(ann$item); ann$rid <- as.integer(ann$rid)
key$item <- as.integer(key$item); key$rid <- as.integer(key$rid)
if (anyDuplicated(paste(ann$audit, ann$item)) || anyDuplicated(paste(key$audit, key$item)) ||
    nrow(ann) != 96L || nrow(key) != 96L || sum(key$audit == "R4") != 66L ||
    sum(key$audit == "R1") != 30L) stop("Stability coding/key cardinality is incomplete or duplicated.")
m <- match(paste(ann$audit, ann$item), paste(key$audit, key$item))
if (anyNA(m) || any(ann$rid != key$rid[m])) stop("Stability item/rid identity mismatch.")

# Bind the withheld labels directly to the final main annotations covered by the current coding
# manifest. This makes a stale repeat key fail even if it happens to have the expected row count.
main_r4 <- read.delim(RSP_R4_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
main_r1 <- read.delim(RSP_R1_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
design_r4 <- read.csv(RSP_R4_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
design_r1 <- read.csv(RSP_R1_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
kr4 <- key[key$audit == "R4", ]; kr1 <- key[key$audit == "R1", ]
mr4 <- match(kr4$item, main_r4$item); mr1 <- match(kr1$item, main_r1$item)
dr4 <- match(kr4$item, design_r4$item); dr1 <- match(kr1$item, design_r1$item)
if (anyNA(c(mr4, mr1, dr4, dr1)) ||
    any(kr4$rid != as.integer(main_r4$rid[mr4])) || any(kr1$rid != as.integer(main_r1$rid[mr1])) ||
    any(kr4$rid != as.integer(design_r4$rid[dr4])) || any(kr1$rid != as.integer(design_r1$rid[dr1])) ||
    any(kr4$expected1 != main_r4$ax1_link_genuine[mr4]) ||
    any(kr4$expected2 != main_r4$ax1_strict[mr4]) ||
    any(kr1$expected1 != main_r1$r1_invocation[mr1]) ||
    any(kr1$expected2 != main_r1$r2_econ_true[mr1])) {
  stop("Repeat key is not an exact subset of the current main annotations/design keys.", call. = FALSE)
}
r4_repeat_domain <- as.character(design_r4$domain[dr4])
if (!setequal(unique(r4_repeat_domain), ME_DOMAINS) ||
    any(as.integer(table(factor(r4_repeat_domain, levels = ME_DOMAINS))) != 6L)) {
  stop("Repeat key must carry exactly six current R4 pairs in each domain.", call. = FALSE)
}

if (!all(ann$audit %in% c("R4", "R1")) || !all(key$audit %in% c("R4", "R1"))) {
  stop("Stability files contain an unknown audit label.", call. = FALSE)
}
r4_ann <- ann$audit == "R4"; r1_ann <- ann$audit == "R1"
r4_key <- key$audit == "R4"; r1_key <- key$audit == "R1"
if (!all(ann$code1[r4_ann] %in% c("genuine", "incidental")) ||
    !all(ann$code2[r4_ann] %in% c("genuine", "incidental")) ||
    !all(key$expected1[r4_key] %in% c("genuine", "incidental")) ||
    !all(key$expected2[r4_key] %in% c("genuine", "incidental"))) {
  stop("R4 stability labels must be genuine or incidental.", call. = FALSE)
}
if (!all(ann$code1[r1_ann] %in% c("genuine", "mention", "false")) ||
    !all(ann$code2[r1_ann] %in% c("yes", "no")) ||
    !all(key$expected1[r1_key] %in% c("genuine", "mention", "false")) ||
    !all(key$expected2[r1_key] %in% c("yes", "no"))) {
  stop("R1 stability labels are outside the permitted codebook.", call. = FALSE)
}
if (any(ann$code2[r4_ann] == "genuine" & ann$code1[r4_ann] != "genuine") ||
    any(key$expected2[r4_key] == "genuine" & key$expected1[r4_key] != "genuine")) {
  stop("R4 strict-genuine labels require a genuine link.", call. = FALSE)
}

kappa <- function(a, b) {
  lev <- union(a, b); tab <- table(factor(a, lev), factor(b, lev)); n <- sum(tab)
  po <- sum(diag(tab)) / n; pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  if (pe == 1) NA_real_ else (po - pe) / (1 - pe)
}
rows_raw <- do.call(rbind, lapply(c("R4", "R1"), function(audit) {
  z <- ann[ann$audit == audit, ]; kk <- key[m[ann$audit == audit], ]
  rbind(data.frame(audit = audit, axis = if (audit == "R4") "ax1_link_genuine" else "r1_invocation",
                   n = nrow(z), agreement = mean(z$code1 == kk$expected1), kappa = kappa(z$code1, kk$expected1)),
        data.frame(audit = audit, axis = if (audit == "R4") "ax1_strict" else "r2_econ_true",
                   n = nrow(z), agreement = mean(z$code2 == kk$expected2), kappa = kappa(z$code2, kk$expected2)))
}))
rows <- rows_raw
rows$agreement <- round(rows$agreement, 3); rows$kappa <- round(rows$kappa, 3)
sem_write_shareable(rows, STABILITY_OUT)

transition_grid <- function(audit, axis, main, repeat_code, levels) {
  tab <- as.data.frame(table(main_label = factor(main, levels = levels),
                             repeat_label = factor(repeat_code, levels = levels)),
                       stringsAsFactors = FALSE)
  data.frame(audit = audit, axis = axis, main_label = as.character(tab$main_label),
             repeat_label = as.character(tab$repeat_label), n = as.integer(tab$Freq),
             stringsAsFactors = FALSE)
}
r4z <- ann[ann$audit == "R4", ]; r4kk <- key[m[ann$audit == "R4"], ]
r1z <- ann[ann$audit == "R1", ]; r1kk <- key[m[ann$audit == "R1"], ]
transitions <- rbind(
  transition_grid("R4", "ax1_link_genuine", r4kk$expected1, r4z$code1,
                  c("genuine", "incidental")),
  transition_grid("R4", "ax1_strict", r4kk$expected2, r4z$code2,
                  c("genuine", "incidental")),
  transition_grid("R1", "r1_invocation", r1kk$expected1, r1z$code1,
                  c("genuine", "mention", "false")),
  transition_grid("R1", "r2_econ_true", r1kk$expected2, r1z$code2, c("yes", "no")))
transition_total <- function(audit, axis)
  sum(transitions$n[transitions$audit == audit & transitions$axis == axis])
if (transition_total("R4", "ax1_link_genuine") != 66L ||
    transition_total("R4", "ax1_strict") != 66L ||
    transition_total("R1", "r1_invocation") != 30L ||
    transition_total("R1", "r2_econ_true") != 30L) {
  stop("Aggregate transition cells do not reconcile to repeat sample cardinalities.", call. = FALSE)
}
sem_write_shareable(transitions, TRANSITION_OUT)

# The R1 gate concerns the economic subject nearest the adjacent teaching marker. Reconstruct that
# subject from the current pair-specific core and publish counts only; no row IDs or excerpts leave
# the private layer. which.min supplies a deterministic first-domain tie rule.
source(here::here("studies/moral-economy/cst_core.R"))
core <- cst_build_core(verbose = FALSE)
ci <- match(r1z$rid, core$rid)
if (anyNA(ci)) stop("A repeated R1 post is absent from the current core.", call. = FALSE)
r1_domain <- vapply(core$domain_gaps[ci], function(g) names(g)[which.min(g)], character(1))
r1_by_domain <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
  take <- r1_domain == d
  data.frame(domain = d, n = sum(take), main_yes = sum(r1kk$expected2[take] == "yes"),
             repeat_yes = sum(r1z$code2[take] == "yes"),
             agreement = if (any(take)) mean(r1kk$expected2[take] == r1z$code2[take]) else NA_real_,
             main_yes_repeat_no = sum(r1kk$expected2[take] == "yes" & r1z$code2[take] == "no"),
             main_no_repeat_yes = sum(r1kk$expected2[take] == "no" & r1z$code2[take] == "yes"),
             stringsAsFactors = FALSE)
}))
r1_by_domain$agreement <- round(r1_by_domain$agreement, 3)
if (sum(r1_by_domain$n) != 30L ||
    sum(r1_by_domain$main_yes_repeat_no) !=
      transitions$n[transitions$audit == "R1" & transitions$axis == "r2_econ_true" &
                    transitions$main_label == "yes" & transitions$repeat_label == "no"] ||
    sum(r1_by_domain$main_no_repeat_yes) !=
      transitions$n[transitions$audit == "R1" & transitions$axis == "r2_econ_true" &
                    transitions$main_label == "no" & transitions$repeat_label == "yes"]) {
  stop("R1 nearest-domain diagnostics do not reconcile to the overall transitions.", call. = FALSE)
}
sem_write_shareable(r1_by_domain, DOMAIN_OUT)

STABILITY_THRESHOLD <- 0.80
failed <- rows_raw[rows_raw$agreement < STABILITY_THRESHOLD, c("audit", "axis", "agreement", "kappa")]
failed$agreement <- round(failed$agreement, 3); failed$kappa <- round(failed$kappa, 3)
gate <- list(threshold = STABILITY_THRESHOLD, passed = nrow(failed) == 0L,
             failed_axes = failed)
digikat_write_json_atomic(list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/32_rsp_reuse_stability.R --score",
  database_sha256 = rsp_read_input_manifest()$database$sha256,
  coding_manifest_sha256 = digikat_hash_file(CODING_MANIFEST),
  coding = list(system = "OpenAI Codex bounded subagent",
                backend_model_identifier = "not exposed to this session",
                decoding_settings = "not exposed to this session",
                relation_to_main_pass = "same model workflow, separate blind repeat pass"),
  sample = list(key_sha256 = digikat_hash_file(KEY), r4_n = sum(key$audit == "R4"),
                r1_n = sum(key$audit == "R1"), r4_per_domain = 6L),
  main_inputs = list(
    r4_sheet_sha256 = digikat_hash_file(RSP_R4_SHEET),
    r1_sheet_sha256 = digikat_hash_file(RSP_R1_SHEET),
    r4_key_sha256 = digikat_hash_file(RSP_R4_KEY),
    r1_key_sha256 = digikat_hash_file(RSP_R1_KEY),
    r4_allocation_sha256 = digikat_hash_file(r4_alloc_path),
    r1_allocation_sha256 = digikat_hash_file(r1_alloc_path),
    r4_annotation_sha256 = digikat_hash_file(RSP_R4_ANN),
    r1_annotation_sha256 = digikat_hash_file(RSP_R1_ANN)),
  prompts = lapply(prompt_fs,
                   function(f) list(file = basename(f), sha256 = digikat_hash_file(f))),
  annotations = lapply(sort(fs), function(f)
    list(file = basename(f), sha256 = digikat_hash_file(f))),
  outputs = list(
    stability = list(path = "output/rsp_annotation_stability.csv",
                     sha256 = digikat_hash_file(STABILITY_OUT)),
    transitions = list(path = "output/rsp_stability_transitions.csv",
                       sha256 = digikat_hash_file(TRANSITION_OUT)),
    r1_by_domain = list(path = "output/rsp_stability_r1_by_domain.csv",
                        sha256 = digikat_hash_file(DOMAIN_OUT))),
  output_sha256 = digikat_hash_file(STABILITY_OUT),
  gate = gate
), file.path(ME_OUT, "rsp_stability_manifest.json"))
print(rows, row.names = FALSE)
if (!gate$passed && !ALLOW_FAILED)
  stop("Repeat-pass stability gate failed (<0.80 raw agreement). Outputs were retained; review the failure or rerun with --allow-failed-gate to continue with downgraded claims.", call. = FALSE)
if (!gate$passed) {
  cat("[EXPECTED FAILURE ACCEPTED] continuing only with downgraded claims; see manifest gate.failed_axes\n")
} else cat("[PASS] all repeat-pass stability axes reach >=0.80 raw agreement\n")
