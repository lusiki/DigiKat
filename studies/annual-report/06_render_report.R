#!/usr/bin/env Rscript
# Stage 6 — render HTML and PDF.
#
# The build happens in a temporary directory OUTSIDE the repository, and docs/ is fingerprinted
# before and after: a stray Quarto render must never be able to touch the published site.

suppressPackageStartupMessages({ library(here); library(jsonlite) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

report_path <- file.path(AR_PRIVATE, "IZVJESTAJ.qmd")
typeset_dir <- file.path(AR_DIR, "typeset")
assets <- c(css = file.path(typeset_dir, "report.css"),
            typst = file.path(typeset_dir, "typst-template.typ"),
            show = file.path(typeset_dir, "typst-show.typ"))
if (!file.exists(report_path)) stop("Run 04_sync_fragments.R first.", call. = FALSE)
if (any(!file.exists(assets))) {
  stop("Missing typeset asset: ", paste(assets[!file.exists(assets)], collapse = ", "), call. = FALSE)
}

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
check_out <- system2(rscript, file.path("studies", "annual-report", "05_report_checks.R"),
                     stdout = TRUE, stderr = TRUE)
if (!is.null(attr(check_out, "status")) && attr(check_out, "status") != 0L) {
  cat(paste(check_out, collapse = "\n"), "\n")
  stop("Mechanical checks failed; refusing to render.", call. = FALSE)
}
cat(tail(check_out, 2L), sep = "\n")

# Prefer the system installation over anything earlier on PATH: this machine also carries an older
# per-user Quarto whose bundled Typst is too old for the report template.
quarto <- ""
for (candidate in c(Sys.getenv("QUARTO_PATH", unset = ""), "C:/Program Files/Quarto/bin/quarto.exe")) {
  if (nzchar(candidate) && file.exists(candidate)) { quarto <- candidate; break }
}
if (!nzchar(quarto)) quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("Quarto is unavailable.", call. = FALSE)
quarto_version <- as.character(system2(quarto, "--version", stdout = TRUE))
cat("[quarto]", quarto, quarto_version, "\n")
if (utils::compareVersion(quarto_version, "1.8.0") < 0) {
  stop("Quarto ", quarto_version, " is too old for the report's Typst template (needs 1.8+).", call. = FALSE)
}

docs_fingerprint <- function() {
  root <- here::here("docs")
  files <- sort(list.files(root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE))
  files <- files[file.exists(files) & !dir.exists(files)]
  rel <- substring(normalizePath(files, winslash = "/", mustWork = TRUE),
                   nchar(normalizePath(root, winslash = "/", mustWork = TRUE)) + 2L)
  payload <- paste(rel, file.info(files)$size, vapply(files, ar_sha256, character(1)),
                   sep = "|", collapse = "\n")
  digest::digest(payload, algo = "sha256", serialize = FALSE)
}
docs_before <- docs_fingerprint()

repo <- normalizePath(here::here(), winslash = "/", mustWork = TRUE)
tmp_parent <- normalizePath(Sys.getenv("TEMP", unset = tempdir()), winslash = "/", mustWork = TRUE)
if (startsWith(paste0(tmp_parent, "/"), paste0(repo, "/"))) {
  stop("Temporary directory is inside the repository.", call. = FALSE)
}
build <- file.path(tmp_parent, "digikat_annual_report_build")
if (startsWith(paste0(gsub("\\\\", "/", build), "/"), paste0(repo, "/"))) {
  stop("Build path is inside the repository.", call. = FALSE)
}
if (dir.exists(build)) unlink(build, recursive = TRUE, force = TRUE)
dir.create(file.path(build, "figures"), recursive = TRUE, showWarnings = FALSE)

qmd <- readLines(report_path, encoding = "UTF-8", warn = FALSE)
qmd <- gsub("../figures/", "figures/", qmd, fixed = TRUE)
ar_write_utf8(qmd, file.path(build, "report.qmd"))
if (!all(file.copy(unname(assets), file.path(build, basename(assets)), overwrite = TRUE))) {
  stop("Could not stage the typeset assets.", call. = FALSE)
}
figures <- list.files(AR_FIGURES, pattern = "[.]png$", full.names = TRUE)
if (!all(file.copy(figures, file.path(build, "figures"), overwrite = TRUE))) {
  stop("Could not stage the report figures.", call. = FALSE)
}

old <- setwd(build)
on.exit(setwd(old), add = TRUE)
render_one <- function(format, extension) {
  cat("[render]", format, "\n")
  log <- system2(quarto, c("render", "report.qmd", "--to", format), stdout = TRUE, stderr = TRUE)
  produced <- file.path(build, paste0("report.", extension))
  if ((!is.null(attr(log, "status")) && attr(log, "status") != 0L) || !file.exists(produced)) {
    cat(paste(log, collapse = "\n"), "\n")
    stop("Quarto did not produce ", extension, ".", call. = FALSE)
  }
  produced
}
html <- render_one("html", "html")
pdf <- render_one("typst", "pdf")
setwd(old)

rendered_dir <- file.path(AR_PRIVATE, "rendered")
dir.create(rendered_dir, recursive = TRUE, showWarnings = FALSE)
stem <- sprintf("DigiKat_godisnji_pregled_%d", AR_REPORT_YEAR)
targets <- file.path(rendered_dir, paste0(stem, c(".html", ".pdf")))
if (!all(file.copy(c(html, pdf), targets, overwrite = TRUE))) {
  stop("Could not copy the rendered report.", call. = FALSE)
}

docs_after <- docs_fingerprint()
if (!identical(docs_before, docs_after)) stop("docs/ changed during an isolated render.", call. = FALSE)

# The HTML must carry literal Croatian diacritics, not numeric entities.
html_text <- paste(readLines(targets[1], encoding = "UTF-8", warn = FALSE), collapse = "\n")
if (!all(vapply(c("č", "ć", "ž", "š", "đ"), grepl, logical(1), x = html_text, fixed = TRUE))) {
  stop("Rendered HTML lost Croatian diacritics.", call. = FALSE)
}

render_manifest <- list(
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  quarto = as.character(system2(quarto, "--version", stdout = TRUE)),
  reporting_year = AR_REPORT_YEAR,
  build_outside_repository = TRUE,
  docs_sha256_before = docs_before,
  docs_sha256_after = docs_after,
  files = lapply(targets, function(path) list(file = basename(path),
                                              bytes = unname(file.info(path)$size),
                                              sha256 = ar_sha256(path)))
)
write_json(render_manifest, file.path(rendered_dir, "render_manifest.json"),
           pretty = TRUE, auto_unbox = TRUE)

unlink(build, recursive = TRUE, force = TRUE)
cat("\nRendered; docs/ fingerprint unchanged.\n")
for (t in targets) cat(sprintf("  %s  (%.1f MB)\n", t, file.info(t)$size / 1024^2))
