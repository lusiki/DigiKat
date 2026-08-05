#!/usr/bin/env Rscript
# moral-economy — TYPESET THE RSP MANUSCRIPT AS A PDF AND AS AN HTML PAGE.
#
# The manuscript itself (PAPER_RSP_v1.md) is plain markdown with no YAML front matter, because
# 25_paper_checks.R measures it against the journal's character cap and front matter is not part of
# the submission. So this script does NOT edit it. It assembles a throwaway copy that carries the
# front matter and the style assets, renders that, and copies the result into output/paper/.
#
# The copy is assembled and rendered in a TEMPORARY DIRECTORY OUTSIDE THE REPOSITORY. That is
# deliberate: this repo is a Quarto project whose render target is docs/, and MEMORY.md records that
# running quarto from inside it against a stray source scatters output and can empty docs/. A build
# directory with no _quarto.yml above it cannot do either.
#
#   Rscript studies/moral-economy/28_render_paper.R             # v1, PDF (typst) + HTML
#   Rscript studies/moral-economy/28_render_paper.R --v2        # v2, PDF + HTML
#   Rscript studies/moral-economy/28_render_paper.R --v2 --html # v2, HTML only
#   Rscript studies/moral-economy/28_render_paper.R --pdf       # PDF only
#
# Requires Quarto; Typst is bundled with it, so no LaTeX installation is needed.
suppressPackageStartupMessages({ library(here) })

args    <- commandArgs(trailingOnly = TRUE)
KEEP    <- "--keep" %in% args       # leave the build directory and the .typ file for inspection
VERSION <- if ("--v2" %in% args) "v2" else "v1"
args    <- setdiff(args, c("--keep", "--v1", "--v2"))
want    <- if (length(args)) sub("^--", "", args) else c("pdf", "html")

STUDY  <- here::here("studies/moral-economy")
STEM   <- paste0("PAPER_RSP_", VERSION)
PAPER  <- file.path(STUDY, paste0(STEM, ".md"))
if (!file.exists(PAPER)) stop("No such manuscript: ", PAPER, call. = FALSE)
OUTDIR <- file.path(STUDY, "output", "paper")
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)

quarto <- Sys.which("quarto")
if (!nzchar(quarto)) {
  for (p in c("C:/Program Files/Quarto/bin/quarto.exe", "/usr/local/bin/quarto")) {
    if (file.exists(p)) { quarto <- p; break }
  }
}
if (!nzchar(quarto)) stop("Quarto not found; render where Quarto is installed.")

txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)

# The manuscript opens with "# title" and "## subtitle". Those become front-matter fields, so the
# typeset version gets a real title block instead of two ordinary headings.
title    <- sub("^#\\s+", "", txt[1])
subtitle <- sub("^##\\s+", "", txt[2])
body     <- txt[-(1:2)]
while (length(body) && (!nzchar(trimws(body[1])) || trimws(body[1]) == "---")) body <- body[-1]

# Quarto reads a bare "---" as a YAML delimiter, so the decorative rules in the source would
# truncate the document. They carry no meaning once the title block is typeset.
body <- body[trimws(body) != "---"]

# Each figure PNG carries its own title and source line, drawn by 24_rsp_figures.R. Left as is,
# Quarto would print a second caption underneath reading "Figure 1: Figure 1", so the alt text is
# emptied for the typeset copy only.
body <- sub("^!\\[Figure [0-9]+\\]\\(", "![](", body)

yaml <- c(
  "---",
  sprintf('title: "%s"', title),
  sprintf('subtitle: "%s"', subtitle),
  "lang: en",
  "format:",
  "  typst:",
  "    papersize: a4",
  "    margin: { x: 2.2cm, y: 2.4cm }",
  '    mainfont: "Cambria"',
  "    fontsize: 10.5pt",
  "    include-in-header: assets/paper.typ",
  if (KEEP) "    keep-typ: true" else NULL,
  "  html:",
  "    theme: none",
  "    css: assets/paper.css",
  "    toc: true",
  "    toc-depth: 2",
  '    toc-title: "Contents"',
  "    embed-resources: true",
  "    fig-align: center",
  "---",
  "")

# ---- assemble the build directory outside the repository ---------------------------------------
# Not tempdir(): R deletes that on exit, which would take --keep's build directory with it.
tmproot <- Sys.getenv("TEMP", unset = Sys.getenv("TMPDIR", unset = tempdir()))
build   <- file.path(tmproot, "digikat_rsp_typeset")
unlink(build, recursive = TRUE)
dir.create(file.path(build, "output", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(build, "assets"), recursive = TRUE, showWarnings = FALSE)
file.copy(list.files(file.path(STUDY, "output", "figures"), full.names = TRUE),
          file.path(build, "output", "figures"), overwrite = TRUE)
# The style assets live in studies/moral-economy/typeset/, NOT in an "assets/" folder: the site's
# _quarto.yml carries `resources: assets/`, which globs any directory of that name anywhere in the
# repo and would copy these two files into the published docs/. They are named assets/ only inside
# the throwaway build directory, where the front matter above expects them.
file.copy(list.files(file.path(STUDY, "typeset"), full.names = TRUE),
          file.path(build, "assets"), overwrite = TRUE)

src <- file.path(build, "paper.md")
con <- file(src, open = "wt", encoding = "UTF-8"); writeLines(c(yaml, body), con); close(con)
if (file.exists(file.path(build, "_quarto.yml")))
  stop("Build directory unexpectedly sits inside a Quarto project.")

old <- setwd(build); on.exit(setwd(old), add = TRUE)

render <- function(fmt, ext) {
  cat(sprintf("\n[render] %s\n", fmt))
  st <- system2(quarto, c("render", "paper.md", "--to", fmt), stdout = TRUE, stderr = TRUE)
  produced <- file.path(build, paste0("paper.", ext))
  if (!file.exists(produced)) {
    cat(paste(st, collapse = "\n"), "\n")
    stop("Render to ", fmt, " produced no ", ext, " file.")
  }
  target <- file.path(OUTDIR, paste0(STEM, ".", ext))
  if (!file.copy(produced, target, overwrite = TRUE)) stop("Could not write ", target)
  cat(sprintf("[ok] %s  (%s KB)\n", basename(target), format(round(file.size(target) / 1024))))
  invisible(TRUE)
}

if ("pdf" %in% want)  render("typst", "pdf")
if ("html" %in% want) render("html", "html")

setwd(old)
if (KEEP) cat("\n[keep] build directory left at", build, "\n") else unlink(build, recursive = TRUE)
cat("\nTypeset output is in", OUTDIR, "\n")
