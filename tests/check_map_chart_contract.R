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
  expect_true(any(grepl("^body-classes: map-page$", lines)), paste(name, "must use map-page styling"))
  expect_true(any(grepl("lazy-images\\.lua", lines)), paste(name, "must lazy-load figures"))
  expect_true(any(grepl("digikat_map_setup()", lines, fixed = TRUE)), paste(name, "must use shared map export settings"))
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
      expect_true(any(grepl("#\\| column: page", options)), paste(label, "must use the wide figure column"))
      expect_true(any(grepl("#\\| fig-alt:", options)), paste(label, "must have meaningful alt text"))
      expect_true(any(grepl("#\\| fig-cap:", options)), paste(label, "must have a semantic caption"))
    }
  }
}

expect_true(
  sum(grepl("digikat_chart_evidence\\(", all_source)) == sum(lengths(figures)),
  "Every retained chart must have one visible summary block"
)
expect_true(
  sum(grepl("digikat_render_map_plot\\(", all_source)) == sum(lengths(figures)),
  "Every retained chart must provide a dedicated narrow export"
)
expect_true(
  !length(list.files(file.path("assets", "downloads", "maps"), pattern = "\\.csv$")),
  "Map CSV downloads must not be published"
)

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
  grepl("body.map-page .cell.page-full figure.figure", chart_css, fixed = TRUE) &&
    grepl("body.map-page .cell.page-full .figure-img", chart_css, fixed = TRUE),
  "Map figures must use the wide editorial card treatment"
)
expect_true(
  grepl("width: min(960px, calc(100vw - 3rem))", chart_css, fixed = TRUE) &&
    grepl("justify-self: center", chart_css, fixed = TRUE) &&
    grepl("margin-inline: auto", chart_css, fixed = TRUE),
  "Map figures must be capped and centered on the editorial column"
)
expect_true(
  !grepl("min-width: 44rem", chart_css, fixed = TRUE) &&
    grepl("min-width: 0", chart_css, fixed = TRUE) &&
    grepl("overflow-x: visible", chart_css, fixed = TRUE),
  "Map figures must fit narrow screens without an internal scroller"
)
expect_true(
  grepl("background: var(--dk-color-paper)", chart_css, fixed = TRUE) &&
    grepl("box-shadow: none", chart_css, fixed = TRUE),
  "Map figures must share the page paper without card chrome"
)

chart_helpers <- paste(
  readLines("R/lib/digikat_charts.R", encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
expect_true(
  grepl('dev = "ragg_png"', chart_helpers, fixed = TRUE) &&
    grepl('dev.args = list(bg = "#F5F4F0")', chart_helpers, fixed = TRUE),
  "Shared map export settings must use ragg and the exact paper colour"
)

map_theme <- paste(
  readLines("R/theme_digikat.R", encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
expect_true(
  grepl("plot.background  = ggplot2::element_rect(fill = dk_col$paper", map_theme, fixed = TRUE) &&
    grepl("panel.background = ggplot2::element_rect(fill = dk_col$paper", map_theme, fixed = TRUE),
  "The shared map theme must use the paper colour for plot and panel backgrounds"
)

lazy_filter <- paste(
  readLines("assets/filters/lazy-images.lua", encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
expect_true(
  grepl('image.attributes.width', lazy_filter, fixed = TRUE) &&
    grepl('image.attributes.height', lazy_filter, fixed = TRUE),
  "Lazy-loaded PNGs must receive intrinsic width and height"
)
expect_true(
  grepl('data-mobile-src', lazy_filter, fixed = TRUE) &&
    grepl('data-mobile-width', lazy_filter, fixed = TRUE) &&
    grepl('data-mobile-height', lazy_filter, fixed = TRUE),
  "Map PNGs must expose narrow-source metadata"
)

mobile_assets <- list.files(
  file.path("assets", "images", "maps", "mobile"),
  pattern = "\\.png$",
  full.names = TRUE
)
expect_true(
  length(mobile_assets) == sum(lengths(figures)),
  "Every retained chart must have one generated mobile PNG"
)

if (length(mobile_assets) && requireNamespace("png", quietly = TRUE)) {
  for (image_path in mobile_assets) {
    image <- png::readPNG(image_path)
    corner <- as.integer(round(image[1, 1, 1:3] * 255))
    expect_true(
      identical(corner, c(245L, 244L, 240L)),
      paste(basename(image_path), "must use #F5F4F0 at its corner")
    )
  }
}

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
    image_matches <- gregexpr('<img[^>]+_files/figure-html/[^>]+>', html, perl = TRUE)[[1L]]
    image_tags <- if (length(image_matches) == 1L && image_matches[[1L]] == -1L) {
      character()
    } else {
      regmatches(html, list(image_matches))[[1L]]
    }
    expect_true(length(image_tags) == length(figures[[names(pages)[match(html_path, html_paths)]]]),
                paste(html_path, "must contain the expected figure count"))
    expect_true(length(image_tags) > 0L && all(grepl(' width="[0-9]+"', image_tags)) &&
                  all(grepl(' height="[0-9]+"', image_tags)),
                paste(html_path, "must give every lazy figure intrinsic dimensions"))
    expect_true(length(image_tags) > 0L && all(grepl('data-mobile-src=', image_tags, fixed = TRUE)) &&
                  all(grepl('data-mobile-width=', image_tags, fixed = TRUE)) &&
                  all(grepl('data-mobile-height=', image_tags, fixed = TRUE)),
                paste(html_path, "must give every figure a narrow source and dimensions"))
    expect_true(grepl("chart-accessible-summary", html, fixed = TRUE),
                paste(html_path, "must contain accessible chart summaries"))
    expect_true(grepl('class="[^\"]*map-page', html, perl = TRUE),
                paste(html_path, "must expose the map page class"))
    expect_true(grepl('_files/figure-html/[^\"]+\\.png', html, perl = TRUE),
                paste(html_path, "must contain raster figures with embedded fonts"))
    expect_true(!grepl("Preuzmite podatke (CSV)|Preuzmite grafikon (SVG)|Prikažite podatke u tablici", html),
                paste(html_path, "must not expose chart downloads or data tables"))
  }
}

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "Run 4 chart-contract checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}

cat("All", checks, "Run 4 chart-contract checks passed.\n")
