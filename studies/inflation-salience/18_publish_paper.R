#!/usr/bin/env Rscript
# 18_publish_paper.R — publish PAPER_EMIP_v2 as standalone HTML, PDF, and Word assets.
#
# The checked Markdown manuscript remains the single source of truth. A temporary Quarto document
# supplies format metadata and reuses the established DigiKat paper styles. The build happens outside
# the repository so it cannot interfere with the website output directory.

source("studies/inflation-salience/_lib.R")

rule("18_publish_paper.R")

PAPER <- file.path(STUDY, "PAPER_EMIP_v2.md")
WORD  <- file.path(OUT, "paper", "PAPER_EMIP_v2_full.docx")
PAPER_OUT <- file.path(OUT, "paper")
SITE_OUT  <- file.path("assets", "papers")
dir.create(PAPER_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(SITE_OUT, recursive = TRUE, showWarnings = FALSE)

quarto <- Sys.which("quarto")
if (!nzchar(quarto)) {
  for (p in c("C:/Program Files/Quarto/bin/quarto.exe", "/usr/local/bin/quarto")) {
    if (file.exists(p)) { quarto <- p; break }
  }
}
if (!nzchar(quarto)) stop("Quarto not found; render where Quarto is installed.")
if (!file.exists(WORD)) stop("Word manuscript is missing; run 11_render_paper.R --v2 first.")

txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)
title <- sub("^#\\s+", "", txt[1])
subtitle <- sub("^##\\s+", "", txt[grep("^## ", txt)[1]])
body_start <- grep("^\\*\\*Category:", txt)[1]
if (is.na(body_start)) stop("cannot locate manuscript category line")
body <- txt[body_start:length(txt)]
body <- body[trimws(body) != "---"]

yaml <- c(
  "---",
  sprintf('title: "%s"', title),
  sprintf('subtitle: "%s"', subtitle),
  "author:",
  "  - name: Luka Šikić",
  "    email: luka.sikic@unicath.hr",
  "    affiliations:",
  "      - name: Catholic University of Croatia",
  "        department: Department of Communication Studies",
  "        city: Zagreb",
  "  - name: Petra Palić",
  "    affiliations:",
  "      - name: Catholic University of Croatia",
  "        department: Department of Communication Studies",
  "        city: Zagreb",
  "lang: en",
  "format:",
  "  typst:",
  "    papersize: a4",
  "    margin: { x: 2.2cm, y: 2.4cm }",
  '    mainfont: "Cambria"',
  "    fontsize: 10.5pt",
  "    include-in-header: assets/paper.typ",
  "  html:",
  "    theme: none",
  "    css: assets/paper.css",
  "    include-in-header: assets/paper-head.html",
  "    include-before-body: assets/paper-bar.html",
  "    include-after-body: assets/paper-foot.html",
  "    toc: true",
  "    toc-depth: 2",
  '    toc-title: "Contents"',
  "    embed-resources: true",
  "    fig-align: center",
  "---",
  "")

tmproot <- Sys.getenv("TEMP", unset = Sys.getenv("TMPDIR", unset = tempdir()))
build <- file.path(tmproot, "digikat_inflation_paper")
unlink(build, recursive = TRUE)
dir.create(file.path(build, "assets"), recursive = TRUE, showWarnings = FALSE)
fig_dir <- file.path(build, "studies", "inflation-salience", "output")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

style_dir <- file.path("studies", "moral-economy", "typeset")
for (f in c("paper.css", "paper.typ", "paper-head.html", "paper-foot.html")) {
  src <- file.path(style_dir, f)
  if (!file.exists(src) || !file.copy(src, file.path(build, "assets", f), overwrite = TRUE))
    stop("could not copy typeset asset: ", src)
}

bar <- c(
  '<div class="dk-topbar">',
  '  <div class="dk-topbar-inner">',
  '    <a class="dk-brand" href="https://lusiki.github.io/DigiKat/">DigiKat</a>',
  '    <nav class="dk-topnav">',
  '      <a href="https://lusiki.github.io/DigiKat/pages/studije/inflacija-i-religija.html">Stranica studije</a>',
  '      <a href="https://lusiki.github.io/DigiKat/pages/baza.html">Baza podataka</a>',
  '    </nav>',
  '  </div>',
  '</div>')
con <- file(file.path(build, "assets", "paper-bar.html"), open = "wt", encoding = "UTF-8")
writeLines(bar, con); close(con)

figures <- c("fig1_event_timeline.png", "fig2_unit_responses.png")
for (f in figures) {
  src <- file.path(OUT, f)
  if (!file.exists(src) || !file.copy(src, file.path(fig_dir, f), overwrite = TRUE))
    stop("could not stage figure: ", src)
}

src <- file.path(build, "paper.md")
con <- file(src, open = "wt", encoding = "UTF-8"); writeLines(c(yaml, body), con); close(con)
if (file.exists(file.path(build, "_quarto.yml")))
  stop("temporary build unexpectedly sits inside a Quarto project")

old <- setwd(build); on.exit(setwd(old), add = TRUE)
render <- function(fmt, ext) {
  msg("  rendering ", fmt)
  log <- system2(quarto, c("render", "paper.md", "--to", fmt), stdout = TRUE, stderr = TRUE)
  produced <- file.path(build, paste0("paper.", ext))
  if (!file.exists(produced)) stop("render to ", fmt, " failed:\n", paste(log, collapse = "\n"))
  target <- file.path(normalizePath(old, winslash = "/"), PAPER_OUT,
                      paste0("PAPER_EMIP_v2_full.", ext))
  if (!file.copy(produced, target, overwrite = TRUE)) stop("could not write ", target)
  target
}

pdf_out <- render("typst", "pdf")
html_out <- render("html", "html")
setwd(old)

stem <- "inflation-information-delayed-repricing"
publish <- c(
  html_out,
  pdf_out,
  WORD,
  file.path(OUT, figures)
)
names(publish) <- c(paste0(stem, ".html"), paste0(stem, ".pdf"), paste0(stem, ".docx"),
                    paste0(stem, "-fig1.png"), paste0(stem, "-fig2.png"))
for (i in seq_along(publish)) {
  target <- file.path(SITE_OUT, names(publish)[i])
  if (!file.copy(publish[i], target, overwrite = TRUE)) stop("could not publish ", target)
  msg("  published ", target, " (", format(round(file.size(target) / 1024), big.mark = " "), " KB)")
}

unlink(build, recursive = TRUE)
msg("\ndone.")
