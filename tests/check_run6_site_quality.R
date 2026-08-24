#!/usr/bin/env Rscript

failures <- character()
checks <- 0L
expect_true <- function(value, message) {
  checks <<- checks + 1L
  if (!isTRUE(value)) failures <<- c(failures, message)
}

read_utf8 <- function(path) paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
front_matter <- function(path) {
  text <- readLines(path, encoding = "UTF-8", warn = FALSE)
  fences <- which(text == "---")
  if (length(fences) < 2L || fences[1L] != 1L) return(character())
  text[seq.int(fences[1L] + 1L, fences[2L] - 1L)]
}

page_sources <- c("index.qmd", list.files("pages", pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE))
page_sources <- page_sources[!grepl("_mreza_graf\\.qmd$", page_sources)]
for (path in page_sources) {
  yaml <- front_matter(path)
  expect_true(any(grepl("^description:[[:space:]]*[^[:space:]]", yaml)),
              paste("Substantial page must have a description:", path))
  expect_true(any(grepl("^status:[[:space:]]*[^[:space:]]", yaml)),
              paste("Substantial page must have a current status:", path))
  expect_true(!any(grepl("^date:[[:space:]]*last-modified[[:space:]]*$", yaml)),
              paste("Page must distinguish modification date from publication date:", path))
}

generator <- read_utf8("R/wiki_sources.R")
expect_true(all(vapply(c("description:", "date-modified:", "data-cutoff:", "show-freshness: true",
                         "ProfilePage", "CollectionPage", "image: false", "Metodologija prikupljanja"),
                       grepl, logical(1L), x = generator, fixed = TRUE)),
            "Source-profile generator must own metadata, freshness, schema and methodology links")
expect_true(!grepl("provisional|vendorsk", generator, ignore.case = TRUE),
            "Source-profile generator must use controlled Croatian terminology")

news <- read_utf8("pages/news.qmd")
expect_true(!grepl("Uskoro|kick off", news, ignore.case = TRUE),
            "News must not contain expired upcoming items or unexplained English terms")

croatian_sweep <- paste(vapply(c(
  "pages/about.qmd", "pages/metodologija.qmd", "pages/news.qmd",
  "pages/mapa/mapa.qmd", "pages/pregled/agentski-sloj.qmd"
), read_utf8, character(1L)), collapse = "\n")
expect_true(!grepl("vendorsk|kick off|provisional|R & Python|Big Data|Text Mining",
                   croatian_sweep, ignore.case = TRUE),
            "Active Croatian prose must pass the controlled-term sweep")

quarto <- read_utf8("_quarto.yml")
expect_true(grepl("https://lusiki.github.io/DigiKat/assets/images/digikat-social-card.png", quarto, fixed = TRUE) &&
              grepl("aria-label: \"GitHub repozitorij projekta DigiKat\"", quarto, fixed = TRUE),
            "Shared metadata must use an absolute social image and name the GitHub icon")
expect_true(grepl("page-freshness.lua", quarto, fixed = TRUE) && grepl("site-end.html", quarto, fixed = TRUE),
            "Quarto must load shared freshness and runtime accessibility hardening")

scss <- read_utf8("assets/css/custom.scss")
site_end <- read_utf8("assets/includes/site-end.html")
expect_true(grepl("prefers-reduced-motion", scss, fixed = TRUE) &&
              grepl("focus-visible", scss, fixed = TRUE) &&
              grepl("table-responsive", scss, fixed = TRUE),
            "Shared CSS must cover reduced motion, visible focus and responsive tables")
expect_true(grepl("scope", site_end, fixed = TRUE) && grepl("aria-label", site_end, fixed = TRUE),
            "Runtime table hardening must add scopes and accessible region names")

package <- jsonlite::fromJSON("package.json")
expect_true(identical(unname(package$devDependencies[["axe-core"]]), "4.13.0"),
            "axe-core must remain pinned for reproducible accessibility results")
expect_true(file.exists("scripts/check_site_quality.mjs") && file.exists("scripts/check_site_browser.mjs"),
            "Static and browser release checks must exist")
static_check <- read_utf8("scripts/check_site_quality.mjs")
expect_true(grepl('file === "pages/izvori/mreza.html"', static_check, fixed = TRUE) &&
              grepl('["mreža izvora", 2_000_000]', static_check, fixed = TRUE),
            "The interactive source network must have an explicit two-megabyte budget")
expect_true(file.exists("site-governance/RELEASE_CHECKLIST.md"),
            "The repeatable release checklist must exist")
expect_true(!file.exists("assets/images/photo_.png") && file.exists("archive/design-prototype/photo_.png"),
            "The unused ten-megabyte prototype raster must stay outside published assets")

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "Run 6 checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}
cat("All", checks, "Run 6 source-quality checks passed.\n")
