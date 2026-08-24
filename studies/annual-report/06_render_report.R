#!/usr/bin/env Rscript
# Stage 6 — render HTML and PDF.
#
# The build happens outside the repository. HTML uses external responsive assets; Typst keeps the
# designed PDF path. Pass --promote to refresh the already published artifacts under assets/ after
# all checks pass. The script never touches docs/.

suppressPackageStartupMessages({ library(here); library(jsonlite) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
unknown_args <- setdiff(args, "--promote")
if (length(unknown_args)) stop("Unknown argument: ", paste(unknown_args, collapse = ", "), call. = FALSE)
promote <- "--promote" %in% args

report_path <- file.path(AR_PRIVATE, "IZVJESTAJ.qmd")
report_en_path <- file.path(AR_PRIVATE, "REPORT_EN.qmd")
typeset_dir <- file.path(AR_DIR, "typeset")
web_shell_dir <- here::here("assets", "izvjestaji")
assets <- c(
  css = file.path(typeset_dir, "report.css"),
  typst = file.path(typeset_dir, "typst-template.typ"),
  show = file.path(typeset_dir, "typst-show.typ"),
  filter = file.path(typeset_dir, "report-html.lua"),
  shell_css = file.path(web_shell_dir, "report-shell.css"),
  shell_js = file.path(web_shell_dir, "report-shell.js")
)
if (!file.exists(report_path) || !file.exists(report_en_path)) {
  stop("Run 04_sync_fragments.R first.", call. = FALSE)
}
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

# Prefer the system installation over an older per-user Quarto.
quarto <- ""
for (candidate in c(Sys.getenv("QUARTO_PATH", unset = ""), "C:/Program Files/Quarto/bin/quarto.exe")) {
  if (nzchar(candidate) && file.exists(candidate)) { quarto <- candidate; break }
}
if (!nzchar(quarto)) quarto <- Sys.which("quarto")
if (!nzchar(quarto)) stop("Quarto is unavailable.", call. = FALSE)
quarto_version <- as.character(system2(quarto, "--version", stdout = TRUE))
cat("[quarto]", quarto, quarto_version, "\n")
if (utils::compareVersion(quarto_version, "1.8.0") < 0) {
  stop("Quarto ", quarto_version, " is too old for the report template (needs 1.8+).", call. = FALSE)
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
dir.create(build, recursive = TRUE, showWarnings = FALSE)

stem_hr <- sprintf("godisnji-pregled-%d", AR_REPORT_YEAR)
stem_en <- sprintf("annual-review-%d", AR_REPORT_YEAR)

if (!requireNamespace("png", quietly = TRUE) || !requireNamespace("ragg", quietly = TRUE)) {
  stop("Packages 'png' and 'ragg' are required for responsive report images.", call. = FALSE)
}

stage_responsive_figures <- function(source_dir, stem) {
  destination <- file.path(build, paste0(stem, "_files"), "figures")
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  sources <- list.files(source_dir, pattern = "[.]png$", full.names = TRUE)
  if (!length(sources)) stop("No report figures found in ", source_dir, call. = FALSE)
  if (!all(file.copy(sources, destination, overwrite = TRUE))) {
    stop("Could not stage report figures from ", source_dir, call. = FALSE)
  }

  rows <- list()
  for (source in sources[grepl("^fig[0-9]+_", basename(sources))]) {
    raster <- png::readPNG(source, native = FALSE)
    height <- dim(raster)[1]
    width <- dim(raster)[2]
    variants <- integer()
    for (target_width in c(960L, 1440L)) {
      if (target_width >= width) next
      target_height <- as.integer(round(height * target_width / width))
      target <- file.path(destination, paste0(tools::file_path_sans_ext(basename(source)),
                                               "-", target_width, ".png"))
      ragg::agg_png(target, width = target_width, height = target_height, units = "px",
                    res = 96, background = "transparent")
      grid::grid.newpage()
      grid::grid.raster(raster, width = grid::unit(1, "npc"), height = grid::unit(1, "npc"),
                        interpolate = TRUE)
      grDevices::dev.off()
      variants <- c(variants, target_width)
    }
    rows[[length(rows) + 1L]] <- data.frame(
      file = basename(source), width = width, height = height,
      variants = paste(variants, collapse = ","), stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

figures_hr <- stage_responsive_figures(AR_FIGURES, stem_hr)
figures_en <- stage_responsive_figures(AR_FIGURES_EN, stem_en)

# The Typst cover still uses this stable path. Body figures use the language-specific companion
# folders above, so the HTML can be promoted as one self-contained folder per edition.
dir.create(file.path(build, "figures"), recursive = TRUE, showWarnings = FALSE)
if (!file.copy(file.path(AR_FIGURES, "cover_spark.png"), file.path(build, "figures"), overwrite = TRUE)) {
  stop("Could not stage the Typst cover spark.", call. = FALSE)
}

prepare_qmd <- function(path, old_prefix, stem, figure_manifest) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  asset_prefix <- paste0(stem, "_files/figures/")
  lines <- gsub(old_prefix, asset_prefix, lines, fixed = TRUE)
  for (i in seq_along(lines)) {
    hit <- regmatches(lines[i], regexpr("[^/()]+[.]png(?=\\))", lines[i], perl = TRUE))
    if (!length(hit) || !nzchar(hit)) next
    row <- figure_manifest[figure_manifest$file == hit, , drop = FALSE]
    if (!nrow(row)) next
    base <- tools::file_path_sans_ext(hit)
    widths <- c(as.integer(strsplit(row$variants, ",", fixed = TRUE)[[1]]), row$width)
    widths <- widths[!is.na(widths)]
    srcset <- paste(sprintf("%s%s-%d.png %dw", asset_prefix, base, widths, widths), collapse = ", ")
    srcset <- sub(sprintf("%s%s-%d[.]png %dw$", asset_prefix, base, row$width, row$width),
                  sprintf("%s%s.png %dw", asset_prefix, base, row$width), srcset)
    attrs <- sprintf(paste0(" loading=\"lazy\" decoding=\"async\" width=\"%d\" height=\"%d\"",
                            " srcset=\"%s\" sizes=\"(max-width: 52rem) calc(100vw - 2rem), 48rem\""),
                     row$width, row$height, srcset)
    lines[i] <- sub("}$", paste0(attrs, "}"), lines[i])
  }
  lines
}

qmd_hr <- prepare_qmd(report_path, "../figures/", stem_hr, figures_hr)
qmd_en <- prepare_qmd(report_en_path, "../figures-en/", stem_en, figures_en)
ar_write_utf8(qmd_hr, file.path(build, paste0(stem_hr, ".qmd")))
ar_write_utf8(qmd_en, file.path(build, paste0(stem_en, ".qmd")))
if (!all(file.copy(unname(assets), file.path(build, basename(assets)), overwrite = TRUE))) {
  stop("Could not stage the report assets.", call. = FALSE)
}

old <- setwd(build)
on.exit(setwd(old), add = TRUE)
render_one <- function(input, format, extension) {
  cat("[render]", input, format, "\n")
  log <- system2(quarto, c("render", input, "--to", format), stdout = TRUE, stderr = TRUE)
  produced <- file.path(build, paste0(tools::file_path_sans_ext(input), ".", extension))
  if ((!is.null(attr(log, "status")) && attr(log, "status") != 0L) || !file.exists(produced)) {
    cat(paste(log, collapse = "\n"), "\n")
    stop("Quarto did not produce ", extension, ".", call. = FALSE)
  }
  produced
}
html <- render_one(paste0(stem_hr, ".qmd"), "html", "html")
pdf <- render_one(paste0(stem_hr, ".qmd"), "typst", "pdf")
html_en <- render_one(paste0(stem_en, ".qmd"), "html", "html")
pdf_en <- render_one(paste0(stem_en, ".qmd"), "typst", "pdf")
setwd(old)

# Quarto templates can emit trailing spaces on otherwise empty generated lines. Normalize the two
# publication files before validation and promotion so repository-wide whitespace checks stay useful.
normalize_generated_html <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  ar_write_utf8(sub("[[:blank:]]+$", "", lines), path)
}
normalize_generated_html(html)
normalize_generated_html(html_en)

check_html <- function(path, language) {
  text <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  count <- function(pattern) length(unlist(regmatches(text, gregexpr(pattern, text, perl = TRUE))))
  if (count("<h1(?:[[:space:]>])") != 1L) stop(language, " HTML must contain exactly one H1.", call. = FALSE)
  if (grepl("data:image/", text, fixed = TRUE)) stop(language, " HTML embeds a base64 image.", call. = FALSE)
  if (count("<img(?:[[:space:]>])") != 9L || count("srcset=") != 9L || count("loading=\"lazy\"") != 9L) {
    stop(language, " HTML does not expose nine responsive, lazy report figures.", call. = FALSE)
  }
  required <- c("rel=\"canonical\"", "property=\"og:title\"", "name=\"twitter:card\"",
                "application/ld+json", "ScholarlyArticle", "report-shell.js", ".pdf")
  missing <- required[!vapply(required, grepl, logical(1), x = text, fixed = TRUE)]
  if (length(missing)) stop(language, " HTML metadata is incomplete: ", paste(missing, collapse = ", "), call. = FALSE)
  text
}
html_text <- check_html(html, "Croatian")
html_text_en <- check_html(html_en, "English")
if (!all(vapply(c("č", "ć", "ž", "š", "đ"), grepl, logical(1), x = html_text, fixed = TRUE))) {
  stop("Rendered HTML lost Croatian diacritics.", call. = FALSE)
}
if (!grepl("Catholic themes in the digital space", html_text_en, fixed = TRUE) ||
    !grepl("Methodology", html_text_en, fixed = TRUE)) {
  stop("Rendered English HTML is incomplete or in the wrong language.", call. = FALSE)
}

copy_tree <- function(source, destination) {
  dir.create(destination, recursive = TRUE, showWarnings = FALSE)
  paths <- list.files(source, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE,
                      include.dirs = TRUE)
  rel <- substring(normalizePath(paths, winslash = "/", mustWork = TRUE),
                   nchar(normalizePath(source, winslash = "/", mustWork = TRUE)) + 2L)
  dirs <- paths[dir.exists(paths)]
  if (length(dirs)) {
    dir_rel <- rel[dir.exists(paths)]
    invisible(vapply(file.path(destination, dir_rel), dir.create, logical(1), recursive = TRUE,
                     showWarnings = FALSE))
  }
  files <- paths[file.exists(paths) & !dir.exists(paths)]
  file_rel <- rel[file.exists(paths) & !dir.exists(paths)]
  if (length(files) && !all(file.copy(files, file.path(destination, file_rel), overwrite = TRUE))) {
    stop("Could not copy web asset tree to ", destination, call. = FALSE)
  }
  invisible(destination)
}

safe_replace_tree <- function(source, destination, root) {
  root_norm <- normalizePath(root, winslash = "/", mustWork = TRUE)
  destination_norm <- gsub("\\\\", "/", normalizePath(dirname(destination), winslash = "/", mustWork = TRUE))
  candidate <- paste0(destination_norm, "/", basename(destination))
  if (!startsWith(paste0(candidate, "/"), paste0(root_norm, "/"))) {
    stop("Refusing to replace a directory outside ", root, ": ", candidate, call. = FALSE)
  }
  if (dir.exists(destination)) unlink(destination, recursive = TRUE, force = TRUE)
  copy_tree(source, destination)
}

rendered_dir <- file.path(AR_PRIVATE, "rendered")
dir.create(rendered_dir, recursive = TRUE, showWarnings = FALSE)
private_stem_hr <- sprintf("DigiKat_godisnji_pregled_%d", AR_REPORT_YEAR)
private_stem_en <- sprintf("DigiKat_annual_review_%d", AR_REPORT_YEAR)
targets <- file.path(rendered_dir, c(paste0(private_stem_hr, c(".html", ".pdf")),
                                    paste0(private_stem_en, c(".html", ".pdf"))))
if (!all(file.copy(c(html, pdf, html_en, pdf_en), targets, overwrite = TRUE))) {
  stop("Could not copy the rendered report.", call. = FALSE)
}
for (stem in c(stem_hr, stem_en)) {
  safe_replace_tree(file.path(build, paste0(stem, "_files")),
                    file.path(rendered_dir, paste0(stem, "_files")), rendered_dir)
}
if (!all(file.copy(file.path(build, c("report.css", "report-shell.css", "report-shell.js")),
                   rendered_dir, overwrite = TRUE))) {
  stop("Could not copy shared web assets beside the private render.", call. = FALSE)
}

if (promote) {
  publish_dir <- here::here("assets", "izvjestaji")
  publish_targets <- file.path(publish_dir, c(paste0(stem_hr, c(".html", ".pdf")),
                                              paste0(stem_en, c(".html", ".pdf"))))
  if (!all(file.copy(c(html, pdf, html_en, pdf_en), publish_targets, overwrite = TRUE))) {
    stop("Could not promote the rendered report.", call. = FALSE)
  }
  for (stem in c(stem_hr, stem_en)) {
    safe_replace_tree(file.path(build, paste0(stem, "_files")),
                      file.path(publish_dir, paste0(stem, "_files")), publish_dir)
  }
  if (!file.copy(file.path(build, "report.css"), file.path(publish_dir, "report.css"), overwrite = TRUE)) {
    stop("Could not promote report.css.", call. = FALSE)
  }
  cat("[promote] refreshed assets/izvjestaji report artifacts\n")
}

docs_after <- docs_fingerprint()
if (!identical(docs_before, docs_after)) stop("docs/ changed during an isolated render.", call. = FALSE)

render_manifest <- list(
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  quarto = as.character(system2(quarto, "--version", stdout = TRUE)),
  reporting_year = AR_REPORT_YEAR,
  build_outside_repository = TRUE,
  responsive_widths = c(960L, 1440L),
  promoted = promote,
  docs_sha256_before = docs_before,
  docs_sha256_after = docs_after,
  files = lapply(seq_along(targets), function(i) list(
    file = basename(targets[i]), language = if (i <= 2L) "hr" else "en",
    bytes = unname(file.info(targets[i])$size), sha256 = ar_sha256(targets[i])))
)
write_json(render_manifest, file.path(rendered_dir, "render_manifest.json"),
           pretty = TRUE, auto_unbox = TRUE)

if (dir.exists(build)) unlink(build, recursive = TRUE, force = TRUE)
cat("\nRendered; docs/ fingerprint unchanged.\n")
for (target in targets) cat(sprintf("  %s  (%.1f MB)\n", target, file.info(target)$size / 1024^2))
