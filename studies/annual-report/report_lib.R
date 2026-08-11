#!/usr/bin/env Rscript
# Shared constants, formatters and guards for the DigiKat annual report.
#
# Everything the report chain writes lives below studies/annual-report/output/.
# Nothing here opens a dataset; the aggregate scripts do that, read-only.

suppressPackageStartupMessages({
  library(here)
  library(jsonlite)
})

source(here::here("R", "lib", "digikat_paths.R"), encoding = "UTF-8")

AR_DIR <- here::here("studies", "annual-report")

# The reporting year is the one parameter that distinguishes one edition from another. Everything
# below derives from it, so a back-edition is a different YEAR against the same chain rather than a
# copy of the chain. Set AR_YEAR in the environment to build another edition.
AR_REPORT_YEAR <- {
  requested <- Sys.getenv("AR_YEAR", unset = "2025")
  value <- suppressWarnings(as.integer(requested))
  if (is.na(value)) stop("AR_YEAR is not a year: ", requested, call. = FALSE)
  value
}
AR_BASELINE_YEAR <- AR_REPORT_YEAR - 1L

# Each edition owns a directory. Two editions in one folder look identical on disk, and the older
# generation's files get swept into the newer manifest — the failure that published the pilot's
# 236 166 after the corpus rebuild.
AR_OUT <- file.path(AR_DIR, "output", as.character(AR_REPORT_YEAR))
AR_PRIVATE <- file.path(AR_OUT, "private")
AR_TABLES <- file.path(AR_OUT, "tables")
AR_FIGURES <- file.path(AR_OUT, "figures")

# 2024 is a leap year and 2025 is not. Standardising a daily series over the wrong calendar length
# silently shifts every z-score, so the length is computed, never assumed.
AR_CALENDAR_DAYS <- as.integer(
  as.Date(sprintf("%d-12-31", AR_REPORT_YEAR)) - as.Date(sprintf("%d-01-01", AR_REPORT_YEAR)) + 1L)

# The 2024 collection seam. Everything from 2024-07-01 onward belongs to one collection stream, so
# a comparison INSIDE that window is instrument-comparable; a comparison across it is not.
AR_STREAM_ERA <- "post2024"
AR_STREAM_START <- as.Date("2024-07-01")

# Which movement THIS edition can honestly publish. The recurring chapter asks "where is the
# conversation moving?", and the answer has to come from inside one collection stream. When the
# baseline year's second half predates the stream, no year-over-year answer exists at all, and the
# edition falls back to a within-year movement measured per collected day. It is never allowed to
# reach across the seam to manufacture one.
AR_STREAM_MODE <- if (as.Date(sprintf("%d-07-01", AR_BASELINE_YEAR)) >= AR_STREAM_START) {
  "yoy_h2"
} else {
  "within_year_quarters"
}

# Named cells below this floor are suppressed.
AR_SMALL_CELL <- 5L

for (path in c(AR_OUT, AR_PRIVATE, AR_TABLES, AR_FIGURES)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

## --- IO ----------------------------------------------------------------------------------------

ar_write_utf8 <- function(lines, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(as.character(lines)), con, useBytes = TRUE)
  invisible(path)
}

ar_write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, fileEncoding = "UTF-8", na = "")
  invisible(path)
}

ar_read_csv <- function(path) {
  if (!file.exists(path)) stop("Missing report aggregate: ", path, call. = FALSE)
  utils::read.csv(path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM", check.names = FALSE)
}

ar_out_csv <- function(name) ar_read_csv(file.path(AR_OUT, name))

ar_sha256 <- function(path) {
  if (!requireNamespace("digest", quietly = TRUE)) stop("Package 'digest' is required.")
  unname(digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE))
}

## --- Croatian number formatting ----------------------------------------------------------------
# Thousands separator is a NO-BREAK SPACE (U+00A0), not a thin space: "124 346" must never break
# across a line, and U+2009 is missing from the mono face the figures use, where it renders as a
# tofu box. The decimal mark is a comma. Machine-facing CSV values stay plain.

AR_THIN <- " "

ar_fmt_int_hr <- function(x) {
  formatC(as.numeric(x), format = "d", big.mark = AR_THIN)
}

ar_fmt_int_en <- function(x) {
  formatC(as.numeric(x), format = "d", big.mark = ",")
}

ar_fmt_num_hr <- function(x, digits = 1L) {
  formatC(as.numeric(x), format = "f", digits = digits, big.mark = AR_THIN, decimal.mark = ",")
}

ar_fmt_num_en <- function(x, digits = 1L) {
  formatC(as.numeric(x), format = "f", digits = digits, big.mark = ",", decimal.mark = ".")
}

ar_fmt_pct_hr <- function(x, digits = 1L) paste0(ar_fmt_num_hr(x, digits), " %")
ar_fmt_pct_en <- function(x, digits = 1L) paste0(ar_fmt_num_en(x, digits), "%")

# A change carries its direction in the number itself, so no sentence has to supply it. The minus is
# a real minus sign (U+2212), not a hyphen.
ar_fmt_change_hr <- function(x, digits = 1L) {
  paste0(ifelse(as.numeric(x) >= 0, "+", "−"), ar_fmt_pct_hr(abs(as.numeric(x)), digits))
}
ar_fmt_change_en <- function(x, digits = 1L) {
  paste0(ifelse(as.numeric(x) >= 0, "+", "−"), ar_fmt_pct_en(abs(as.numeric(x)), digits))
}

# Croatian numeral agreement. A count ending in 1 takes the nominative singular, one ending in 2, 3
# or 4 the paucal, and everything else the genitive plural; the teens are the exception and always
# take the genitive plural. A generated report cannot print one fixed form, because the count
# changes every edition: 351 is "351 dan", 207 is "207 dana", and hard-wiring either is wrong in the
# other year.
ar_plural_hr <- function(n, forms) {
  if (length(forms) != 3L) stop("A Croatian noun needs three forms (1 / 2-4 / 5+).", call. = FALSE)
  n <- abs(as.integer(round(as.numeric(n))))
  last_two <- n %% 100L
  last <- n %% 10L
  if (last_two >= 11L && last_two <= 14L) return(forms[3])
  if (last == 1L) return(forms[1])
  if (last >= 2L && last <= 4L) return(forms[2])
  forms[3]
}

# The nouns the report counts. Keyed by the singular so a template reads {{plural:key:objava}}.
AR_NOUN_HR <- list(
  objava = c("objava", "objave", "objava"),
  dan    = c("dan", "dana", "dana"),
  izvor  = c("izvor", "izvora", "izvora"),
  medij  = c("medij", "medija", "medija"),
  akter  = c("akter", "aktera", "aktera")
)

ar_noun_hr <- function(n, noun) {
  forms <- AR_NOUN_HR[[noun]]
  if (is.null(forms)) stop("No Croatian forms registered for the noun '", noun, "'.", call. = FALSE)
  ar_plural_hr(n, forms)
}

# The pairing a sentence almost always wants: the formatted count and its agreeing noun.
ar_count_hr <- function(n, noun) paste(ar_fmt_int_hr(n), ar_noun_hr(n, noun))

ar_month_hr <- c("siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
                 "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca")

ar_date_hr <- function(x) {
  x <- as.Date(x)
  paste0(as.integer(format(x, "%d")), ". ", ar_month_hr[as.integer(format(x, "%m"))], " ",
         format(x, "%Y"), ".")
}

ar_date_short_hr <- function(x) {
  x <- as.Date(x)
  paste0(as.integer(format(x, "%d")), ". ", as.integer(format(x, "%m")), ". ", format(x, "%Y"), ".")
}

## --- Controlled vocabulary ---------------------------------------------------------------------

ar_platform_hr <- c(
  web = "Web", youtube = "YouTube", facebook = "Facebook", twitter = "Twitter/X",
  reddit = "Reddit", forum = "Forumi", instagram = "Instagram",
  comment = "Komentari", tiktok = "TikTok"
)

ar_topic_hr <- c(
  DUHOVNOST_I_LITURGIJA = "Duhovnost i liturgija",
  TEOLOGIJA_I_DOKTRINA = "Teologija i doktrina",
  CRKVENO_UPRAVLJANJE_I_STRUKTURA = "Crkveno upravljanje i struktura",
  PAPE_I_VATIKAN = "Pape i Vatikan",
  CRKVENE_FINANCIJE_I_IMOVINA = "Crkvene financije i imovina",
  GLOBALNA_CRKVA_I_MISIJE = "Globalna Crkva i misije",
  POLITIKA_I_ODNOS_S_DRZAVOM = "Politika i odnos s državom",
  BIOETIKA_I_KULTURNI_RATOVI = "Bioetika i kulturni ratovi",
  KARITAS_I_SOCIJALNA_PRAVDA = "Karitas i socijalna pravda",
  POVIJEST_I_NACIONALNI_IDENTITET = "Povijest i nacionalni identitet",
  ZNANOST_I_VJERA = "Znanost i vjera",
  MEDIJI_UMJETNOST_I_KULTURA = "Mediji, umjetnost i kultura",
  DIGITALNA_EVANGELIZACIJA_I_MLADI = "Digitalna evangelizacija i mladi",
  ZLOSTAVLJANJE_I_KRIZA_POVJERENJA = "Zlostavljanje i kriza povjerenja",
  UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE = "Unutarcrkveni prijepori i ideologije",
  ODNOS_S_DRUGIM_RELIGIJAMA_I_POGLEDIMA = "Odnos s drugim religijama i pogledima"
)

# The four quadrants are named by what they measure. The legacy interpretive names stay out of the
# public text until qualitative validation supports them (INDICATORS.md, AR04).
ar_typology_hr <- c(
  "visok_visok" = "Visoke interakcije i visok doseg",
  "visok_nizak" = "Visoke interakcije, niži doseg",
  "nizak_visok" = "Niže interakcije, visok doseg",
  "nizak_nizak" = "Niže interakcije i niži doseg"
)

## --- Per-edition registries ----------------------------------------------------------------------
# A peak in the data shows a DATE, not a cause. Naming one is an editorial act, so the names live
# here as a reviewable registry keyed by date rather than as a positional vector inside the figure
# code, where a changed peak order would silently relabel the year.
AR_EVENT_NAMES <- list(
  `2024-08-15` = "Velika Gospa",
  `2024-12-25` = "Božić",
  `2024-12-24` = "Badnjak",
  `2025-04-21` = "Smrt pape Franje",
  `2025-04-26` = "Sprovod pape Franje",
  `2025-08-15` = "Velika Gospa",
  `2025-12-25` = "Božić"
)

ar_event_name <- function(date) {
  key <- format(as.Date(date), "%Y-%m-%d")
  vapply(key, function(k) {
    if (!is.null(AR_EVENT_NAMES[[k]])) AR_EVENT_NAMES[[k]] else "neimenovano"
  }, character(1), USE.NAMES = FALSE)
}

# The rotating special chapter. The charter requires one COMPLETED study per edition, separated from
# the recurring indicators, and it rotates: reusing last edition's chapter would make the rotation
# decorative. Each entry names the study, its generated scalar registry, and the keys the chapter
# quotes — so a renamed key fails the build instead of printing a blank.
AR_SPECIAL_CHAPTERS <- list(
  `2025` = list(
    study = "moral-economy",
    registry = file.path("studies", "moral-economy", "output", "tables", "rsp_derived.csv"),
    name_column = "name",
    keys = c("linked_posts", "core_posts", "corrected_headline", "conf_share_doctrinal_labelled")
  ),
  `2024` = list(
    study = "inflation-salience",
    registry = file.path("studies", "inflation-salience", "output", "derived_v2.csv"),
    name_column = "name",
    keys = c("n_linked", "n_core", "peak_n_repricing", "v2_hicp_repricing_lag_months")
  )
)

ar_special_chapter <- function(year = AR_REPORT_YEAR) {
  spec <- AR_SPECIAL_CHAPTERS[[as.character(year)]]
  if (is.null(spec)) stop("No special chapter is registered for edition ", year, ".", call. = FALSE)
  spec
}

# A study's registry writes numbers for humans, so a value can arrive as "1 505" or "710 307" with a
# no-break space. Strip the separators before any arithmetic; a month key like "2024-06" stays text.
ar_parse_value <- function(x) {
  suppressWarnings(as.numeric(gsub("[[:space:]  ]", "", as.character(x))))
}

# Prose differs between editions even though the measures do not: one year's peak is a papal death
# and another's is Christmas. Each edition therefore owns a template; the shared one is the fallback.
ar_template_path <- function(year = AR_REPORT_YEAR) {
  specific <- file.path(AR_DIR, sprintf("REPORT_TEMPLATE_%d.qmd", year))
  if (file.exists(specific)) specific else file.path(AR_DIR, "REPORT_TEMPLATE.qmd")
}

## --- Markdown fragment helpers -----------------------------------------------------------------

ar_md_escape <- function(x) {
  x <- ifelse(is.na(x), "—", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}

ar_md_table <- function(x, headers = names(x), align = NULL) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  if (!ncol(x)) stop("Cannot render a zero-column table.")
  if (ncol(x) > 5L) stop("A report table carries at most five columns (writing guide).")
  if (is.null(align)) align <- rep(":---", ncol(x))
  if (length(align) != ncol(x)) stop("Alignment count does not match table columns.")
  cells <- lapply(x, ar_md_escape)
  body <- if (nrow(x)) {
    vapply(seq_len(nrow(x)), function(i) {
      paste0("| ", paste(vapply(cells, `[[`, character(1), i), collapse = " | "), " |")
    }, character(1))
  } else character()
  c(
    paste0("| ", paste(ar_md_escape(headers), collapse = " | "), " |"),
    paste0("|", paste(align, collapse = "|"), "|"),
    body
  )
}

# Titles and source notes are carried by two elements that survive into BOTH output formats with
# their identity intact: a level-4 heading and a block quote. A fenced div would not — Pandoc's Typst
# writer drops the class, so `::: {.source-note}` arrives as an anonymous block that cannot be styled
# and prints at full body size. Heading and quote can each be given one show rule per format, which
# is what lets a figure title, a table title and their notes be set identically everywhere.
ar_block_title <- function(title) c(paste0("#### ", title), "")

ar_block_note <- function(...) {
  note <- gsub("[*_]", "", paste(...))
  c("", paste(">", note))
}

# A generated table fragment: one question as the title, the grid, one source note.
ar_fragment <- function(path, title, table_lines, note) {
  ar_write_utf8(c(ar_block_title(title), table_lines, ar_block_note(note)), path)
}

# A generated figure block: the same title object as a table's, the image, then the measure and the
# source in one small note. Nothing is baked into the PNG, so every word in the report is set once,
# by the typesetter, in the document's own font.
ar_figure <- function(path, name, title, measure, note, alt) {
  ar_write_utf8(c(
    ar_block_title(title),
    sprintf("![](../figures/%s.png){fig-alt=\"%s\"}", name, alt),
    ar_block_note(paste0(measure, " · ", note))
  ), path)
}

## --- Guards ------------------------------------------------------------------------------------

# The exact set of aggregates this edition produces. A file left over from an earlier generation
# looks identical to a current one on disk, gets swept into the manifest, and quietly publishes the
# numbers of a dataset that no longer exists — which is how the pilot's 236 166 survived a corpus
# rebuild. Anything in output/ that is not on this list is a leftover.
AR_EXPECTED_CSV <- c(
  "annual_report_derived.csv", "actor_typology.csv", "concentration.csv", "coverage.csv",
  "coverage_gaps.csv", "engagement_benchmarks.csv", "engagement_platform.csv", "event_arcs.csv",
  "event_signature.csv", "indicator_status.csv", "league_sources.csv", "nlp_coverage.csv",
  "peaks.csv", "readiness.csv", "reconciliation.csv", "source_labels.csv", "special_chapter.csv",
  "stream_halfyear.csv", "themes.csv", "themes_coverage.csv", "tone_by_label.csv",
  "tone_by_theme.csv", "tone_emotions.csv", "tone_overall.csv", "volume_daily.csv",
  "volume_monthly.csv", "volume_platform.csv", "year_series.csv"
)

ar_stale_outputs <- function() {
  found <- basename(list.files(AR_OUT, pattern = "[.]csv$"))
  sort(setdiff(found, AR_EXPECTED_CSV))
}


ar_readiness_ok <- function() {
  path <- file.path(AR_OUT, "readiness.csv")
  if (!file.exists(path)) stop("Run 00_data_readiness.R first.", call. = FALSE)
  x <- ar_read_csv(path)
  if (any(x$status == "FAIL")) stop("Readiness contains a FAIL result.", call. = FALSE)
  invisible(TRUE)
}

ar_assert_inside <- function(path, root = AR_OUT) {
  root_n <- normalizePath(root, winslash = "/", mustWork = TRUE)
  parent_n <- normalizePath(dirname(path), winslash = "/", mustWork = TRUE)
  if (!startsWith(paste0(parent_n, "/"), paste0(root_n, "/")) && parent_n != root_n) {
    stop("Refusing output outside annual-report/output: ", path, call. = FALSE)
  }
  invisible(TRUE)
}

ar_file_inventory <- function(paths) {
  paths <- sort(paths[file.exists(paths) & !dir.exists(paths)])
  if (!length(paths)) return(data.frame(file = character(), bytes = numeric(), sha256 = character()))
  data.frame(
    file = gsub("\\\\", "/", paths),
    bytes = as.numeric(file.info(paths)$size),
    sha256 = vapply(paths, ar_sha256, character(1)),
    stringsAsFactors = FALSE
  )
}

# Wilson interval for a proportion, so a sample-based share can state its own uncertainty in the
# same units the reader sees.
ar_wilson <- function(k, n, conf = 0.95) {
  if (n <= 0) return(c(lower = NA_real_, upper = NA_real_))
  z <- stats::qnorm(1 - (1 - conf) / 2)
  p <- k / n
  d <- 1 + z^2 / n
  centre <- (p + z^2 / (2 * n)) / d
  half <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / d
  c(lower = max(0, centre - half), upper = min(1, centre + half))
}
