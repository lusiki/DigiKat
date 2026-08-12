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

# A machine-wide Quarto and an older per-user one can both be installed, and the per-user copy wins
# on PATH. Its bundled Typst is too old for the caption and source-note rules in assets/paper.typ,
# and it fails with "unexpected argument: sticky" rather than with anything that names the cause.
# So the installed locations are tried FIRST and the version is asserted, not assumed.
quarto <- ""
for (p in c("C:/Program Files/Quarto/bin/quarto.exe", "/usr/local/bin/quarto", "/usr/bin/quarto")) {
  if (file.exists(p)) { quarto <- p; break }
}
if (!nzchar(quarto)) quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("Quarto not found; render where Quarto is installed.")
qver <- tryCatch(package_version(trimws(system2(quarto, "--version", stdout = TRUE)[1])),
                 error = function(e) NULL)
if (is.null(qver) || qver < package_version("1.7.0"))
  stop("Quarto ", if (is.null(qver)) "(unknown)" else format(qver), " at ", quarto,
       " bundles a Typst too old for assets/paper.typ; install 1.7 or newer.", call. = FALSE)
cat(sprintf("[quarto] %s (%s)\n", quarto, format(qver)))

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

# ---- typeset-only repairs to the build copy ----------------------------------------------------
# Everything below rewrites the THROWAWAY COPY. The manuscript is what 25_paper_checks.R measures
# against the journal's character cap and greps for 62 generated scalars printed with an ASCII
# thousands space, so none of these substitutions may ever be made in the source file.

# 1. Table and figure captions become level-4 headings. Pandoc's Typst writer DROPS a fenced div's
#    class, so a "::: {.caption}" block arrives as an anonymous #block[] that no show rule can
#    reach; a heading keeps its own type in both writers. That is what lets one rule per format
#    style every caption, and lets the PDF glue a caption to the table or figure beneath it instead
#    of stranding it at the foot of a page.
#    The class matters for the HTML edition only. The published copy also loads the site-wide
#    assets/papers/digikat-paper.css, which sets every h1-h6 to serif 600 with !important; a class
#    is what lets a caption opt out of that without restyling headings in the other seven papers.
body <- sub("^(\\*\\*(?:Table|Figure) [A-Z]?[0-9]+\\.\\*\\* .*)$", "#### \\1 {.paper-caption}",
            body, perl = TRUE)

# 2. Source notes become block quotes, for the same reason. This also retires the CSS rule that used
#    to find them as "a paragraph whose only element child is an <em>": :only-child counts elements
#    and ignores text nodes, so that selector also matched every ordinary paragraph containing a
#    single italic phrase and broke it into three pieces on the page.
#    The block quote is wrapped in a classed div for the same reason the caption carries a class:
#    digikat-paper.css gives every blockquote the site's accent rule down its left edge, which reads
#    as a pull quote rather than as a source line.
in_note <- FALSE
body <- unlist(lapply(body, function(ln) {
  if (!in_note && grepl("^\\*Source:", ln)) {
    in_note <<- TRUE
    opened <- TRUE
  } else {
    opened <- FALSE
  }
  if (!in_note) return(ln)
  closing <- grepl("\\*$", ln)
  out <- paste0("> ", sub("\\*$", "", sub("^\\*", "", ln)))
  if (opened) out <- c("::: {.paper-note}", out)
  if (closing) { in_note <<- FALSE; out <- c(out, ":::") }
  out
}), use.names = FALSE)

# 3. A thousands separator written as an ordinary space is the single worst thing on the page: a
#    justified line stretches it to word width, so "413 985" reads as two numbers, and a line break
#    may fall inside it. The same holds for "n = 660" and a day-month pair. U+00A0 is the separator
#    that survives every font used here; U+2009 is missing from parts of the stack and prints as a
#    tofu box. The manuscript keeps the plain space its journal asks for. The literal is built from
#    its code point rather than typed, so the rule cannot be lost to a re-encoding of this file.
NB <- intToUtf8(0x00A0)
tie_numbers <- function(x) {
  x <- gsub("(?<=[0-9]) (?=[0-9]{3}(?![0-9]))", NB, x, perl = TRUE)
  x <- gsub("(?<![A-Za-z])(n|κ) ([=≥]) ", paste0("\\1", NB, "\\2", NB), x, perl = TRUE)
  gsub(paste0("(?<=[0-9]) (?=(?:January|February|March|April|May|June|July|August|September|",
              "October|November|December))"), NB, x, perl = TRUE)
}
body <- tie_numbers(body)

# 4. The document is English, so Typst loads English hyphenation patterns and cannot break a single
#    Croatian word. Justified across a 44-character measure that leaves the Sažetak with visibly
#    stretched lines, which is most of what "the spacing looks wrong" means on page one. Switching
#    the language for the Croatian abstract alone fixes it. A raw typst block is used rather than a
#    fenced div because Pandoc's Typst writer drops a div's attributes; the block is invisible to
#    the HTML render, which needs no equivalent because the browser hyphenates from `lang`.
typst_raw <- function(code) c("", "```{=typst}", code, "```", "")
hr0 <- grep("^## Sažetak \\(hrvatski\\)", body)
hr1 <- grep("^\\*\\*Ključne riječi", body)
if (length(hr0) == 1L && length(hr1) == 1L && hr1 > hr0) {
  body <- append(body, typst_raw('#set text(lang: "en")'), after = hr1)
  body <- append(body, typst_raw('#set text(lang: "hr")'), after = hr0)
}
# assets/paper.typ turns hyphenation OFF so the centred title block is never broken mid-word; the
# body wants it, so it is switched back on here, at the first element after the title block.
body <- c(typst_raw("#set text(hyphenate: auto)"), body)

# The manuscript itself carries no by-line, so the submission copy stays anonymous. The PDF is a
# published artefact and names its authors in the title block. The HTML does NOT: the site
# publisher (scripts/publish_thematic_papers.ps1) injects a Croatian by-line with affiliation and
# author links into that file, and a Quarto title block would print the same two names again just
# above it. So the field is emitted per format rather than once for the document.
AUTHORS <- c(
  "author:",
  '  - name: "Luka Šikić"',
  '    affiliation: "Croatian Catholic University"',
  '  - name: "Petra Palić"',
  '    affiliation: "Croatian Catholic University"')

yaml_for <- function(fmt) c(
  "---",
  sprintf('title: "%s"', title),
  sprintf('subtitle: "%s"', tie_numbers(subtitle)),
  if (fmt == "typst") AUTHORS else NULL,
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
  "    include-in-header: assets/paper-head.html",
  "    include-before-body: assets/paper-bar.html",
  "    include-after-body: assets/paper-foot.html",
  "    toc: true",
  "    toc-depth: 2",
  '    toc-title: "Contents"',
  "    embed-resources: true",
  "    fig-align: center",
  # KaTeX renders on load with no network call once embedded, which matters because the published
  # PDF is a headless-Chrome print with a five-second budget; MathJax would still be typesetting.
  "    html-math-method: katex",
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
if (file.exists(file.path(build, "_quarto.yml")))
  stop("Build directory unexpectedly sits inside a Quarto project.")

old <- setwd(build); on.exit(setwd(old), add = TRUE)

render <- function(fmt, ext) {
  cat(sprintf("\n[render] %s\n", fmt))
  con <- file(src, open = "wt", encoding = "UTF-8")
  writeLines(c(yaml_for(fmt), body), con)
  close(con)
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
