# Shared presentation and disclosure helpers for DigiKat analytical charts.
#
# Chart downloads are built explicitly by R/build_map_assets.R. Quarto pages
# only read those aggregate CSV files and never write into data/ while rendering.

digikat_chart_forbidden_columns <- c(
  "url", "uri", "link", "title", "full_text", "text", "body", "content",
  "context", "description"
)

digikat_assert_chart_download <- function(x, name = "chart download") {
  if (!is.data.frame(x) || nrow(x) == 0L || ncol(x) == 0L) {
    stop(name, " must be a non-empty data frame.", call. = FALSE)
  }

  normalized <- gsub("[^a-z0-9]+", "_", tolower(names(x)))
  forbidden <- normalized %in% digikat_chart_forbidden_columns |
    grepl("(^|_)(url|uri|full_text|body|content|context|description)($|_)", normalized)
  if (any(forbidden)) {
    stop(
      name, " contains a forbidden public column: ",
      paste(names(x)[forbidden], collapse = ", "), ".",
      call. = FALSE
    )
  }

  if (any(vapply(x, is.list, logical(1L)))) {
    stop(name, " must not contain list columns.", call. = FALSE)
  }

  invisible(TRUE)
}

digikat_write_chart_csv <- function(x, path) {
  digikat_assert_chart_download(x, basename(path))
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}

digikat_read_chart_csv <- function(slug, root = "../..") {
  path <- file.path(root, "assets", "downloads", "maps", paste0(slug, ".csv"))
  if (!file.exists(path)) {
    stop(
      "Missing chart download ", path,
      ". Run Rscript R/build_map_assets.R before rendering map pages.",
      call. = FALSE
    )
  }
  out <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE,
                         fileEncoding = "UTF-8")
  digikat_assert_chart_download(out, basename(path))
  out
}

.digikat_html_escape <- function(x) {
  x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

digikat_chart_table_hr <- function(x) {
  labels <- c(
    year = "Godina", date = "Datum", month = "Mjesec", calendar_month = "Mjesec",
    SOURCE_TYPE = "Platforma", platform = "Platforma", FROM = "Izvor",
    total_posts = "Objave", total_interactions = "Interakcije", total_reach = "Doseg",
    post_share = "Udio objava", interaction_share = "Udio interakcija",
    reach_share = "Udio dosega", top10_share = "Udio deset najvećih izvora",
    sources_with_interactions = "Izvori s interakcijama", average_posts = "Prosječne objave",
    lemma = "Leksička jedinica", n = "Broj", topic = "Tema",
    dominant_topic = "Dominantna tema", item1 = "Prva tema", item2 = "Druga tema",
    total_mentions = "Spominjanja", share = "Udio", intensity = "Intenzitet",
    avg_interactions = "Prosječne interakcije", total_articles = "Dokumenti",
    total_angry = "Angry reakcije", total_love = "Love reakcije",
    total_reactions = "Ukupne reakcije", angry_ratio = "Udio Angry reakcija",
    love_ratio = "Udio Love reakcija", correlation = "Korelacija",
    dominant_emotion = "Dominantna emocija", avg_sentiment = "Prosječni tonalitet",
    n_articles = "Dokumenti", avg_cli = "Gustoća konfliktnog rječnika",
    rci_sd = "Standardna devijacija RIK-a", avg_rci = "Prosječni RIK",
    z_score_volume = "Z-vrijednost volumena", is_volume_spike = "Vrh volumena",
    z_score_cli = "Z-vrijednost konfliktnog rječnika", is_cli_spike = "Vrh konfliktnog rječnika",
    duhovnost_share = "Udio teme Duhovnost i liturgija",
    total_cooccurrences = "Pojavljivanja", p10 = "10. percentil", p25 = "25. percentil",
    median = "Medijan", p75 = "75. percentil", p90 = "90. percentil"
  )

  if ("SOURCE_TYPE" %in% names(x) && exists("digikat_platform_hr", mode = "function")) {
    x$SOURCE_TYPE <- digikat_platform_hr(x$SOURCE_TYPE)
  }
  if ("platform" %in% names(x) && exists("digikat_platform_hr", mode = "function")) {
    x$platform <- digikat_platform_hr(x$platform)
  }
  topic_columns <- intersect(c("topic", "dominant_topic", "item1", "item2"), names(x))
  if (length(topic_columns) && exists("digikat_topic_label", mode = "function")) {
    for (column in topic_columns) x[[column]] <- digikat_topic_label(x[[column]])
  }

  matched <- labels[names(x)]
  names(x)[!is.na(matched)] <- unname(matched[!is.na(matched)])
  x
}

digikat_chart_evidence <- function(slug, summary, svg_href, table_caption,
                                   root = "../..", table_data = NULL,
                                   table_note = NULL) {
  download_data <- digikat_read_chart_csv(slug, root = root)
  if (is.null(table_data)) table_data <- download_data
  digikat_assert_chart_download(table_data, paste0(slug, " table"))
  table_data <- digikat_chart_table_hr(table_data)

  summary <- .digikat_html_escape(summary)
  table_caption <- .digikat_html_escape(table_caption)
  csv_href <- paste0("../../assets/downloads/maps/", slug, ".csv")

  table_html <- knitr::kable(
    table_data,
    format = "html",
    escape = TRUE,
    caption = table_caption,
    table.attr = 'class="table table-sm chart-data-table"'
  )

  note_html <- if (is.null(table_note) || !nzchar(table_note)) "" else {
    paste0('<p class="chart-table-note">', .digikat_html_escape(table_note), "</p>")
  }

  html <- paste0(
    '<div class="chart-evidence">',
    '<p class="chart-accessible-summary"><strong>Sažetak grafikona.</strong> ', summary, '</p>',
    '<div class="download-group" aria-label="Preuzimanja uz grafikon">',
    '<a href="', .digikat_html_escape(csv_href), '" download>Preuzmite podatke (CSV)</a>',
    '<a href="', .digikat_html_escape(svg_href), '" download>Preuzmite grafikon (SVG)</a>',
    '</div>',
    '<details class="reference-section chart-table-view">',
    '<summary>Prikažite podatke u tablici</summary>',
    '<div class="reference-section__content">', note_html,
    '<div class="reference-table" tabindex="0" role="region" aria-label="', table_caption, '">',
    table_html,
    '</div></div></details></div>'
  )

  knitr::asis_output(html)
}
