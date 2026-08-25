# Shared presentation helpers for DigiKat analytical charts.

.digikat_html_escape <- function(x) {
  x <- gsub("&", "&amp;", as.character(x), fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

digikat_chart_evidence <- function(slug, summary, ...) {
  summary <- .digikat_html_escape(summary)
  knitr::asis_output(paste0(
    '<div class="chart-evidence">',
    '<p class="chart-accessible-summary"><strong>Sažetak grafikona.</strong> ', summary, '</p>',
    '</div>'
  ))
}
