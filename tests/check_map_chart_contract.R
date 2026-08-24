#!/usr/bin/env Rscript

source("R/lib/digikat_charts.R", encoding = "UTF-8")

failures <- character()
checks <- 0L
expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) failures <<- c(failures, label)
}

pages <- c(
  mapa = "pages/mapa/mapa.qmd",
  evolucija = "pages/mapa/evolucija.qmd",
  teme = "pages/mapa/mapa_stats.qmd",
  diskurs = "pages/mapa/diskurs.qmd",
  dogadjaji = "pages/mapa/događaji.qmd"
)

figures <- list(
  mapa = c("plot-volume", "plot-interaction", "plot-shares",
           "plot-lollipops-interactions", "plot-actor-map"),
  evolucija = c("plot-rast", "plot-migracija", "plot-koncentracija", "plot-ritam"),
  teme = c("plot-wordcloud", "plot-topic-trends", "plot-topic-intensity",
           "plot-engagement-by-topic", "plot-polarization-by-topic",
           "plot-actors-in-topics", "plot-topic-network"),
  diskurs = c("plot-emotion-heatmap", "plot-rci-strategy", "plot-network"),
  dogadjaji = c("plot-volume-anomalies", "plot-conflict-anomalies",
                "event-seismograph-uskrs", "narrative-biography-robust")
)

slugs <- c(
  "mapa-platform-volume", "mapa-platform-interactions", "mapa-platform-shares",
  "mapa-top-sources", "mapa-actor-map", "evolucija-monthly-volume",
  "evolucija-interaction-shares", "evolucija-concentration", "evolucija-annual-rhythm",
  "teme-top-terms", "teme-topic-trends", "teme-topic-intensity",
  "teme-topic-interactions", "teme-facebook-reactions", "teme-actors", "teme-network",
  "diskurs-emotion-tonality", "diskurs-source-conflict", "diskurs-topic-network",
  "dogadjaji-volume-anomalies", "dogadjaji-conflict-anomalies",
  "dogadjaji-easter-window", "dogadjaji-stepinac-terms"
)

markdown_h1_count <- function(lines) {
  in_code <- FALSE
  count <- 0L
  for (line in lines) {
    if (grepl("^```", line)) {
      in_code <- !in_code
    } else if (!in_code && grepl("^# ", line)) {
      count <- count + 1L
    }
  }
  count
}

all_source <- character()
for (name in names(pages)) {
  lines <- readLines(pages[[name]], encoding = "UTF-8", warn = FALSE)
  all_source <- c(all_source, lines)
  expect_true(any(grepl("^description:", lines)), paste(name, "must have a description"))
  expect_true(any(grepl("lazy-images\\.lua", lines)), paste(name, "must lazy-load figures"))
  expect_true(any(grepl('dev = "svglite"', lines, fixed = TRUE)), paste(name, "must render vector figures"))
  expect_true(markdown_h1_count(lines) == 0L, paste(name, "must rely on the single YAML H1"))
  expect_true(any(grepl("summary-60", lines, fixed = TRUE)), paste(name, "must have a 60-second summary"))
  expect_true(any(grepl("freshness-strip", lines, fixed = TRUE)), paste(name, "must have freshness metadata"))

  widths <- as.numeric(sub(".*fig-width: *", "", grep("#\\| fig-width:", lines, value = TRUE)))
  expect_true(all(widths <= 10), paste(name, "must not request oversized figure widths"))

  for (label in figures[[name]]) {
    position <- grep(paste0("#\\| label: ", label, "$"), lines)
    expect_true(length(position) == 1L, paste(name, label, "must occur once"))
    if (length(position) == 1L) {
      options <- lines[position:min(length(lines), position + 10L)]
      expect_true(any(grepl("#\\| fig-alt:", options)), paste(label, "must have meaningful alt text"))
      expect_true(any(grepl("#\\| fig-cap:", options)), paste(label, "must have a semantic caption"))
    }
  }
}

expect_true(
  sum(grepl("digikat_chart_evidence\\(", all_source)) == length(slugs),
  "Every retained chart must have one evidence block"
)
for (slug in slugs) {
  expect_true(any(grepl(paste0('"', slug, '"'), all_source, fixed = TRUE)),
              paste(slug, "must be linked from a map page"))
  path <- file.path("assets", "downloads", "maps", paste0(slug, ".csv"))
  expect_true(file.exists(path), paste(slug, "CSV download must exist"))
  if (file.exists(path)) {
    data <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                            fileEncoding = "UTF-8")
    valid <- !inherits(try(digikat_assert_chart_download(data, slug), silent = TRUE), "try-error")
    expect_true(valid, paste(slug, "must pass aggregate disclosure validation"))
  }
}

chart_css <- paste(
  readLines("assets/css/custom.scss", encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
expect_true(
  grepl(".figure-card img,", chart_css, fixed = TRUE) &&
    grepl("max-width: 100%; height: auto", chart_css, fixed = TRUE),
  "Chart images and SVGs must stay within their responsive container"
)
expect_true(
  grepl(".reference-table { max-width: 100%; overflow-x: auto; }", chart_css, fixed = TRUE),
  "Wide chart tables must scroll inside their own container"
)
expect_true(
  grepl(".download-group", chart_css, fixed = TRUE) &&
    grepl("flex-wrap: wrap", chart_css, fixed = TRUE),
  "Chart download controls must wrap at narrow widths"
)
expect_true(
  grepl(".chart-table-view .reference-table:focus-visible", chart_css, fixed = TRUE),
  "Scrollable chart tables must expose a visible keyboard focus state"
)

rendered_required <- "--rendered" %in% commandArgs(trailingOnly = TRUE)
if (rendered_required) {
  html_paths <- sub("pages/(.*)\\.qmd$", "docs/pages/\\1.html", unname(pages))
  for (html_path in html_paths) {
    expect_true(file.exists(html_path), paste(html_path, "must exist"))
    if (!file.exists(html_path)) next
    html <- paste(readLines(html_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    expect_true(length(gregexpr("<h1([ >])", html, perl = TRUE)[[1L]]) == 1L &&
                  gregexpr("<h1([ >])", html, perl = TRUE)[[1L]][[1L]] != -1L,
                paste(html_path, "must contain exactly one H1"))
    expect_true(!grepl('<img[^>]+width="(2[0-9]{3}|[3-9][0-9]{3,})"', html, perl = TRUE),
                paste(html_path, "must not contain oversized raster figures"))
    expect_true(grepl('loading="lazy"', html, fixed = TRUE),
                paste(html_path, "must contain lazy-loaded figures"))
    expect_true(grepl("chart-accessible-summary", html, fixed = TRUE),
                paste(html_path, "must contain accessible chart summaries"))
    expect_true(grepl("Preuzmite podatke (CSV)", html, fixed = TRUE),
                paste(html_path, "must expose CSV downloads"))
  }
}

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "Run 4 chart-contract checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}

cat("All", checks, "Run 4 chart-contract checks passed.\n")
