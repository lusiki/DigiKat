#!/usr/bin/env Rscript
# Stage 5 — mechanical checks. Everything the definition of done can test without a human.
#
# Fails CLOSED: the render stage refuses to run if any check here fails.

suppressPackageStartupMessages({ library(here); library(jsonlite) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

template_path <- ar_template_path()
report_path <- file.path(AR_PRIVATE, "IZVJESTAJ.qmd")
derived_path <- file.path(AR_OUT, "annual_report_derived.csv")
manifest_path <- file.path(AR_OUT, "manifest.json")
needed <- c(template_path, report_path, derived_path, manifest_path)
if (any(!file.exists(needed))) {
  stop("Missing artifact: ", paste(needed[!file.exists(needed)], collapse = ", "), call. = FALSE)
}

template <- paste(readLines(template_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
report <- paste(readLines(report_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
derived <- ar_read_csv(derived_path)
manifest <- fromJSON(manifest_path, simplifyDataFrame = TRUE)

checks <- list()
ok <- function(condition, label, detail = "") {
  pass <- isTRUE(condition)
  checks[[length(checks) + 1L]] <<- data.frame(check = label, status = if (pass) "PASS" else "FAIL",
                                               detail = as.character(detail), stringsAsFactors = FALSE)
  cat(sprintf("[%s] %-46s %s\n", if (pass) "PASS" else "FAIL", label, detail))
  invisible(pass)
}

cat("=== DigiKat annual report — mechanical checks ===\n\n")

## --- Generation integrity -----------------------------------------------------------------------
ok(!grepl("\\{\\{[^{}]+\\}\\}", report, perl = TRUE), "no unresolved tokens")

token_keys <- unique(gsub("^\\{\\{scalar:|\\}\\}$", "",
                          unlist(regmatches(template, gregexpr("\\{\\{scalar:([^{}]+)\\}\\}", template,
                                                               perl = TRUE))), perl = TRUE))
unknown <- setdiff(token_keys, derived$key)
ok(!length(unknown), "every prose scalar is generated",
   if (length(unknown)) paste(unknown, collapse = ", ") else paste(length(token_keys), "keys used"))
ok(!anyDuplicated(derived$key), "scalar registry keys are unique", paste(nrow(derived), "scalars"))

fragment_paths <- c(list.files(AR_TABLES, pattern = "[.]md$", full.names = TRUE),
                    list.files(file.path(AR_PRIVATE, "profiles"), pattern = "[.]md$", full.names = TRUE))
for (path in fragment_paths) {
  fragment <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  used <- grepl(paste0("{{fragment:", tools::file_path_sans_ext(basename(path)), "}}"), template, fixed = TRUE)
  if (used) ok(grepl(fragment, report, fixed = TRUE), paste0("fragment installed intact: ", basename(path)))
}

## --- The summary --------------------------------------------------------------------------------
summary_hr <- readLines(file.path(AR_TABLES, "summary_hr.md"), encoding = "UTF-8", warn = FALSE)
summary_en <- readLines(file.path(AR_TABLES, "summary_en.md"), encoding = "UTF-8", warn = FALSE)
ok(length(summary_hr) >= 8L && length(summary_hr) <= 10L, "summary holds at most ten findings",
   paste(length(summary_hr), "findings"))
ok(length(summary_en) == length(summary_hr), "English summary mirrors the Croatian one",
   paste(length(summary_en), "findings"))

number_count <- function(line) {
  hits <- regmatches(line, gregexpr("[0-9]+(?:[., ][0-9]+)*(?:[[:space:] ]*%)?", line, perl = TRUE))[[1]]
  hits <- hits[nzchar(hits)]
  length(hits)
}
# The year is a date, not a finding, so it does not count against the one-number rule.
strip_year <- function(x) gsub("^- ", "", gsub(as.character(AR_REPORT_YEAR), "", x, fixed = TRUE))
hr_counts <- vapply(strip_year(summary_hr), number_count, integer(1))
en_counts <- vapply(strip_year(summary_en), number_count, integer(1))
ok(all(hr_counts == 1L), "one number per Croatian finding", paste(hr_counts, collapse = ","))
ok(all(en_counts == 1L), "one number per English finding", paste(en_counts, collapse = ","))

headline <- derived[derived$summary %in% TRUE, , drop = FALSE]
hr_missing <- headline$key[!vapply(headline$display_hr,
                                   function(x) any(grepl(x, summary_hr, fixed = TRUE)), logical(1))]
en_missing <- headline$key[!vapply(headline$display_en,
                                   function(x) any(grepl(x, summary_en, fixed = TRUE)), logical(1))]
ok(!length(hr_missing), "headline scalars all appear in the Croatian summary",
   if (length(hr_missing)) paste(hr_missing, collapse = ", ") else paste(nrow(headline), "scalars"))
ok(!length(en_missing), "headline scalars all appear in the English summary",
   if (length(en_missing)) paste(en_missing, collapse = ", ") else paste(nrow(headline), "scalars"))

## --- Figures ------------------------------------------------------------------------------------
# The cover spark is a typeset asset referenced by the Typst template, not a report figure, so it is
# checked separately rather than being expected to appear in the manuscript.
figure_paths <- list.files(AR_FIGURES, pattern = "^fig[0-9]+_.*[.]png$", full.names = TRUE)
ok(length(figure_paths) == 9L, "nine report figures exist", paste(length(figure_paths), "figures"))
spark <- file.path(AR_FIGURES, "cover_spark.png")
ok(file.exists(spark) && file.info(spark)$size > 5000, "the cover spark is generated",
   if (file.exists(spark)) paste(round(file.info(spark)$size / 1024), "KB") else "missing")
for (path in figure_paths) {
  ok(file.info(path)$size > 20000 && grepl(basename(path), report, fixed = TRUE),
     paste0("figure present, referenced: ", basename(path)),
     paste(round(file.info(path)$size / 1024), "KB"))
}
titles_typeset <- length(unlist(regmatches(report, gregexpr("
#### ", report, fixed = TRUE))))
ok(titles_typeset >= 18L, "figure and table titles are typeset text, not baked into images",
   paste(titles_typeset, "level-4 titles"))
notes_typeset <- length(unlist(regmatches(report, gregexpr("
> ", report, fixed = TRUE))))
ok(notes_typeset >= 18L, "every figure and table carries a typeset source note",
   paste(notes_typeset, "notes"))

alt_count <- length(unlist(regmatches(report, gregexpr("fig-alt=", report, fixed = TRUE))))
ok(alt_count == length(figure_paths), "every figure carries alternative text",
   paste(alt_count, "of", length(figure_paths)))

## --- Honesty guards -------------------------------------------------------------------------------
# Phrase guards run against a whitespace-flattened copy. The manuscript is hard-wrapped, so a
# required sentence can be split across two lines by an ordinary edit and the guard then reports the
# caveat missing when it is present a few characters away.
report_flat <- gsub("[[:space:]]+", " ", report)

# The forbidden sentence is any growth claim measured across the collection seam. The baseline year
# is derived, so a back-edition guards against ITS predecessor rather than against 2023 forever.
unsafe <- c("porast u odnosu na 2021", "pad u odnosu na 2021", "raste od 2021", "od 2021. raste",
            "u odnosu na prošlu godinu",
            sprintf("u odnosu na %d", AR_BASELINE_YEAR),
            sprintf("u odnosu na %d", AR_BASELINE_YEAR - 1L))
unsafe_hits <- unsafe[vapply(unsafe, grepl, logical(1), x = report_flat, fixed = TRUE)]
ok(!length(unsafe_hits), "no comparison crosses the collection seam",
   if (length(unsafe_hits)) paste(unsafe_hits, collapse = "; ") else "clean")
ok(grepl("unutar istoga toka prikupljanja", report_flat, fixed = TRUE) ||
     grepl("Unutar istoga toka prikupljanja", report_flat, fixed = TRUE),
   "the only comparison is named as within-stream")
# The noun agrees with the count, so the phrase is "351 dan" in one edition and "207 dana" in
# another. Match any inflected form rather than one year's.
ok(grepl("prekid", report_flat, fixed = TRUE) &&
     grepl("dan[a-z]* s prikupljanjem", report_flat, perl = TRUE),
   "the collection interruption is disclosed in prose")
ok(grepl("status prijedloga", report_flat, fixed = TRUE) ||
     grepl("prijedlog, a ne konačna", report_flat, fixed = TRUE),
   "editorial source labels are marked as indicative")
ok(grepl("Vrh u podacima pokazuje", report_flat, fixed = TRUE),
   "event naming states that a peak shows a date, not a cause")
ok(grepl("Kompozitni indeks", report_flat, fixed = TRUE) && grepl("Publika", report_flat, fixed = TRUE),
   "missing measures appear as gap panels")

## --- The Wall -------------------------------------------------------------------------------------
# Selling is allowed only inside marked boxes and on the back page. Everything before the first
# marked box must be free of promotional vocabulary.
sell_words <- c("naručena analiza", "naručenu analizu", "cijene na upit", "Cijene na upit",
                "kontaktirajte", "ponuda", "usluga", "usluge", "besplatno")
# PI decision, 2026-08-10: the report carries no service menu and no back page at all. The Wall is
# therefore absolute rather than positional — promotional language is allowed nowhere, and the only
# surviving conversion element is the single marked teaser line.
demo_box <- regexpr("Primjer dubinske analize", report, fixed = TRUE)
teaser <- regexpr(".teaser", report, fixed = TRUE)
findings_prose <- gsub("[[:space:]]+", " ",
                       substr(report, 1, if (teaser > 0) teaser - 1L else nchar(report)))
leak <- sell_words[vapply(sell_words, grepl, logical(1), x = findings_prose, fixed = TRUE)]
ok(!length(leak), "no promotional language before the first marked box",
   if (length(leak)) paste(leak, collapse = "; ") else "clean")
ok(!grepl("Što možemo napraviti za vas", report, fixed = TRUE),
   "the report carries no service menu")
ok(!grepl("Usluga", report, fixed = TRUE) && !grepl("Radionica za tiskovne urede", report, fixed = TRUE),
   "no service is named anywhere in the report")

# Editorial decision, PI, 2026-08-10: the report names no prices anywhere, not even "na upit".
# The word boundary matters — "ocijeniti" contains "cijen" and is ordinary methods prose.
price_words <- c("\bcijen", "\bna upit", "€", "\beura\b", "\bkuna\b", "\bkošta",
                 "\bnaplać", "\btarif", "\bhonorar", "\bpopust")
price_hits <- price_words[vapply(price_words, grepl, logical(1), x = report, perl = TRUE)]
ok(!length(price_hits), "no pricing anywhere in the report",
   if (length(price_hits)) paste(price_hits, collapse = "; ") else "clean")

## --- Disclosure -------------------------------------------------------------------------------------
league <- ar_out_csv("league_sources.csv")
ok(all(league$posts >= AR_SMALL_CELL), "every named outlet clears the small-cell floor",
   paste("minimum", min(league$posts), "posts"))
private_csv <- ar_read_csv(file.path(AR_PRIVATE, "profiles.csv"))
ok(all(private_csv$kind == "institution"), "every profiled actor is an institution",
   paste(nrow(private_csv), "profiles"))
ok(all(private_csv$publish == "yes"), "every profiled actor passes the sidecar publish gate")
ok(!any(grepl("output/private", manifest$outputs$file, fixed = TRUE)),
   "the public manifest lists no private artifact")
ok(!any(grepl("^[A-Za-z]:[/\\\\]", unlist(manifest$outputs), perl = TRUE)),
   "the public manifest holds no absolute local path")
ok(!grepl("http://www\\.|https://www\\.[a-z]+\\.hr/[a-z]", report, perl = TRUE),
   "no row-level source URL reached the manuscript")

## --- Reconciliation ----------------------------------------------------------------------------------
stale <- ar_stale_outputs()
ok(!length(stale), "no aggregate survives from an earlier generation",
   if (length(stale)) paste(stale, collapse = ", ") else paste(length(AR_EXPECTED_CSV), "expected files"))
missing_expected <- setdiff(AR_EXPECTED_CSV, basename(list.files(AR_OUT, pattern = "[.]csv$")))
ok(!length(missing_expected), "every expected aggregate was produced",
   if (length(missing_expected)) paste(missing_expected, collapse = ", ") else "complete")

recon <- ar_out_csv("reconciliation.csv")
ok(all(recon$report_posts == recon$reference_posts), "every aggregate reconciles to the annual total",
   paste(unique(recon$reference_posts), "posts"))
coverage <- ar_out_csv("coverage.csv")
# The calendar length is computed, never assumed: 2024 has 366 days and 2025 has 365.
ok(coverage$calendar_days == AR_CALENDAR_DAYS &&
     coverage$collected_days + coverage$gap_days == AR_CALENDAR_DAYS,
   "the calendar accounts for every day",
   paste(coverage$collected_days, "collected +", coverage$gap_days, "interrupted"))
nlp_cov <- ar_out_csv("nlp_coverage.csv")
ok(all(nlp_cov$in_corpus_rows_year > 0) && all(nlp_cov$effective_rate > 0.01),
   "sample layers retain a usable share of the corpus year",
   paste(sprintf("%s %.1f%%", nlp_cov$layer, 100 * nlp_cov$effective_rate), collapse = "; "))

## --- Encoding and style -------------------------------------------------------------------------------
# The signatures are built from code points rather than typed as literals. R/check_sources.R scans
# every tracked source for exactly these byte patterns, so a literal list here makes the repository's
# mojibake guard fail on the mojibake guard - which is what turned CI red on 2026-08-11.
mojibake <- c(
  intToUtf8(0x00C3),                                # A-tilde
  intToUtf8(0x00C2),                                # A-circumflex
  paste0(intToUtf8(0x00E2), intToUtf8(0x20AC)),     # a-circumflex + euro sign
  paste0(intToUtf8(0x00C5), intToUtf8(0x00A1)),     # A-ring + inverted exclamation  (s-caron misread)
  paste0(intToUtf8(0x00C4), intToUtf8(0x2021))      # A-diaeresis + double dagger    (c-acute misread)
)
moji_hits <- mojibake[vapply(mojibake, grepl, logical(1), x = report, fixed = TRUE)]
ok(!length(moji_hits), "no mojibake signature",
   if (length(moji_hits)) paste(moji_hits, collapse = ", ") else "clean")
ok(all(vapply(c("č", "ć", "ž", "š", "đ"), grepl, logical(1), x = report, fixed = TRUE)),
   "Croatian diacritics intact")
english_leak <- c(" dashboard", " insight", " engagement rate", " benchmark", " reach ", " sample size")
leak_en <- english_leak[vapply(english_leak, grepl, logical(1), x = report, fixed = TRUE)]
ok(!length(leak_en), "no untranslated English in the Croatian body",
   if (length(leak_en)) paste(leak_en, collapse = ", ") else "clean")

asset_script <- paste(readLines(file.path(AR_DIR, "03_report_assets.R"), encoding = "UTF-8", warn = FALSE),
                      collapse = "\n")
ok(!grepl("#[0-9A-Fa-f]{6}", asset_script, perl = TRUE), "figures use theme tokens, not literal colours")

pipeline_scripts <- list.files(AR_DIR, pattern = "^[0-9]{2}_.*[.]R$", full.names = TRUE)
pipeline_scripts <- pipeline_scripts[basename(pipeline_scripts) != "05_report_checks.R"]
protected <- character()
for (path in pipeline_scripts) {
  code <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  if (grepl("write[^\n]*(data/processed|docs/|merged_comprehensive|digikat_corpus[.]rds)", code, perl = TRUE)) {
    protected <- c(protected, basename(path))
  }
}
ok(!length(protected), "no script writes to a protected path",
   if (length(protected)) paste(protected, collapse = ", ") else "clean")

## --- Manifest ------------------------------------------------------------------------------------------
manifest_files <- file.path(AR_DIR, manifest$outputs$file)
hash_ok <- file.exists(manifest_files) &
  vapply(seq_along(manifest_files),
         function(i) ar_sha256(manifest_files[i]) == manifest$outputs$sha256[i], logical(1))
ok(all(hash_ok), "manifest output hashes match",
   if (all(hash_ok)) paste(length(hash_ok), "files") else paste(manifest$outputs$file[!hash_ok], collapse = ", "))
ok(identical(manifest$dataset$sha256,
             fromJSON(here::here("data", "digikat_corpus_manifest.json"))$corpus$sha256),
   "the report was built from the current corpus")

result <- do.call(rbind, checks)
ar_write_csv(result, file.path(AR_PRIVATE, "review", "mechanical_checks.csv"))
cat(sprintf("\n%d of %d checks pass.\n", sum(result$status == "PASS"), nrow(result)))
if (any(result$status == "FAIL")) stop("Annual report failed mechanical checks.", call. = FALSE)
