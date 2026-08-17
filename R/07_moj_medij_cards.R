#!/usr/bin/env Rscript
# Build one disclosure-safe PDF card for every source already exposed by Moj medij.
#
# The script reads only data/page-ready/moj_medij.json. It never opens the corpus, source URLs or
# private editorial files. Default mode validates and previews the intended output; --apply writes
# the reproducible cards to assets/outlet-cards/.

suppressPackageStartupMessages({
  library(grid)
  library(jsonlite)
  library(digest)
})

# A batch of hundreds of cards must not hide the first warning behind R's end-of-session summary.
options(warn = 1)

args <- commandArgs(trailingOnly = TRUE)
apply_ <- "--apply" %in% args
input_path <- file.path("data", "page-ready", "moj_medij.json")
target_dir <- file.path("assets", "outlet-cards")

if (!file.exists(input_path)) {
  stop("Missing data/page-ready/moj_medij.json. Run R/06_moj_medij.R --apply first.", call. = FALSE)
}

raw <- paste(readLines(input_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
payload <- fromJSON(raw, simplifyVector = FALSE)
sources <- payload$sources
if (!length(sources)) stop("Moj medij contains no public sources.", call. = FALSE)

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
card_files <- vapply(sources, function(x) as.character(x$c %||% ""), character(1L))
if (any(!nzchar(card_files)) || anyDuplicated(card_files) ||
    any(!grepl("^[a-z0-9-]+[.]pdf$", card_files))) {
  stop("Every public source must have one unique, safe PDF filename in key 'c'.", call. = FALSE)
}

fmt_int <- function(x) formatC(as.numeric(x), format = "d", big.mark = ".", decimal.mark = ",")
fmt_num <- function(x, digits = 1L) {
  formatC(as.numeric(x), format = "f", digits = digits, big.mark = ".", decimal.mark = ",")
}
wrap_text <- function(x, width) paste(strwrap(as.character(x), width = width), collapse = "\n")

platform_hr <- c(web = "Web", youtube = "YouTube", facebook = "Facebook",
                 instagram = "Instagram", tiktok = "TikTok", twitter = "Twitter / X")
label_hr <- c(confessional = "konfesionalni izvor", secular = "sekularni izvor", other = "ostalo")

paper <- "#f5f4f0"
panel <- "#ffffff"
ink <- "#14181d"
body <- "#4f535a"
muted <- "#6b6f76"
line <- "#e4e2da"
accent <- "#0f4c5c"
accent_soft <- "#5a949f"

draw_text <- function(label, x, y, size, colour = ink, face = "plain", just = c("left", "top"),
                      family = "Segoe UI") {
  grid.text(label, x = unit(x, "npc"), y = unit(y, "npc"), just = just,
            gp = gpar(fontsize = size, col = colour, fontface = face, fontfamily = family,
                      lineheight = 1.12))
}

draw_card <- function(source, path) {
  cairo_pdf(path, width = 8.27, height = 11.69, family = "Segoe UI", onefile = FALSE)
  on.exit(dev.off(), add = TRUE)
  grid.newpage()
  grid.rect(gp = gpar(fill = paper, col = NA))
  grid.rect(x = unit(0, "npc"), width = unit(0.018, "npc"), just = "left",
            gp = gpar(fill = accent, col = NA))

  draw_text("DigiKat", 0.075, 0.945, 17, accent, "bold")
  draw_text("MOJ MEDIJ · PROFIL IZVORA", 0.925, 0.945, 9, muted, "bold", c("right", "top"))
  grid.lines(x = unit(c(0.075, 0.925), "npc"), y = unit(c(0.91, 0.91), "npc"),
             gp = gpar(col = line, lwd = 1))

  name <- wrap_text(source$n, 36)
  draw_text(name, 0.075, 0.865, ifelse(nchar(source$n) > 34, 24, 30), ink, "bold",
            family = "Palatino Linotype")
  meta <- character()
  if (nzchar(source$t %||% "")) meta <- c(meta, source$t)
  if (nzchar(source$pl %||% "")) meta <- c(meta, platform_hr[[source$pl]] %||% source$pl)
  if (nzchar(source$lb %||% "")) meta <- c(meta, label_hr[[source$lb]] %||% source$lb)
  if (!length(meta)) meta <- "izvor iz korpusa"
  years <- unlist(source$y$g, use.names = FALSE)
  draw_text(paste(c(meta, paste0(min(years), ".–", max(years), ".")), collapse = " · "),
            0.075, 0.775, 10, muted)

  kpi_x <- c(0.075, 0.29, 0.505, 0.72)
  kpi_value <- c(fmt_int(source$p), fmt_int(source$i), fmt_int(source$x), fmt_num(source$e, 1))
  kpi_label <- c("objava ukupno", "zabilježenih interakcija", "procijenjeni doseg",
                 "interakcija po objavi")
  for (i in seq_along(kpi_x)) {
    grid.roundrect(x = unit(kpi_x[i], "npc"), y = unit(0.715, "npc"),
                   width = unit(0.19, "npc"), height = unit(0.09, "npc"),
                   just = c("left", "top"), r = unit(4, "pt"),
                   gp = gpar(fill = panel, col = line, lwd = 0.8))
    draw_text(kpi_value[i], kpi_x[i] + 0.016, 0.695, 18, ink, "bold", family = "Palatino Linotype")
    draw_text(kpi_label[i], kpi_x[i] + 0.016, 0.65, 8.2, muted)
  }

  draw_text("Objave po godini", 0.075, 0.585, 13, ink, "bold")
  posts <- as.numeric(unlist(source$y$p, use.names = FALSE))
  max_posts <- max(c(posts, 1))
  left <- 0.095
  right <- 0.905
  base_y <- 0.38
  chart_h <- 0.155
  slot <- (right - left) / length(years)
  for (i in seq_along(years)) {
    height <- chart_h * posts[i] / max_posts
    x <- left + (i - 1) * slot + slot * 0.18
    width <- slot * 0.64
    grid.rect(x = unit(x, "npc"), y = unit(base_y, "npc"), width = unit(width, "npc"),
              height = unit(max(height, 0.002), "npc"), just = c("left", "bottom"),
              gp = gpar(fill = ifelse(i == which.max(posts), accent, accent_soft), col = NA))
    draw_text(fmt_int(posts[i]), x + width / 2, base_y + height + 0.012, 8.2, body,
              just = c("centre", "bottom"))
    draw_text(paste0(years[i], "."), x + width / 2, base_y - 0.018, 8.2, muted,
              just = c("centre", "top"))
  }
  grid.lines(x = unit(c(left, right), "npc"), y = unit(c(base_y, base_y), "npc"),
             gp = gpar(col = line, lwd = 0.8))

  draw_text("Položaj među prikazanim izvorima", 0.075, 0.325, 13, ink, "bold")
  rank_text <- c(
    paste0("Po broju objava  ", fmt_int(source$rp), ". od ", fmt_int(payload$totals$sources_listed),
           "  ·  ", fmt_num(source$sp, 2), " % svih objava u korpusu"),
    paste0("Po interakcijama  ", fmt_int(source$ri), ".  ·  po procijenjenom dosegu  ",
           fmt_int(source$rx), ".")
  )
  if (nzchar(source$tp %||% "")) {
    rank_text <- c(rank_text, paste0("Tipologija unutar platforme  ", source$tp))
  }
  draw_text(paste(rank_text, collapse = "\n"), 0.075, 0.287, 10.5, body)

  grid.roundrect(x = unit(0.075, "npc"), y = unit(0.19, "npc"), width = unit(0.85, "npc"),
                 height = unit(0.10, "npc"), just = c("left", "top"), r = unit(4, "pt"),
                 gp = gpar(fill = "#eaf0f2", col = NA))
  note <- paste(
    "Brojke opisuju samo objave o katoličkim temama koje su ušle u službeni korpus.",
    "Interakcije i doseg vrijednosti su servisa za praćenje medija i uspoređuju se unutar iste platforme.",
    "Zadnja godina može biti nepotpuna."
  )
  draw_text(wrap_text(note, 112), 0.095, 0.168, 8.7, body)

  grid.lines(x = unit(c(0.075, 0.925), "npc"), y = unit(c(0.07, 0.07), "npc"),
             gp = gpar(col = line, lwd = 1))
  draw_text("Izvor  DigiKat · službeni korpus · CC BY 4.0", 0.075, 0.05, 8.2, muted)
  draw_text("lusiki.github.io/DigiKat/pages/moj-medij.html", 0.925, 0.05, 8.2, accent,
            just = c("right", "top"))
}

cat("\n=== PDF kartice za Moj medij ===\n")
cat("javni JSON :", input_path, "\n")
cat("izvora     :", length(sources), "\n")
cat("odredište  :", target_dir, "\n")

if (!apply_) {
  cat("\nPREGLED. Ništa nije zapisano. Za izradu pokreni:\n  Rscript R/07_moj_medij_cards.R --apply\n\n")
  quit(save = "no", status = 0L)
}

dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
for (i in seq_along(sources)) {
  draw_card(sources[[i]], file.path(target_dir, card_files[i]))
}

paths <- file.path(target_dir, card_files)
bad <- !file.exists(paths) | file.info(paths)$size < 5000
if (any(bad)) stop("One or more outlet cards are missing or implausibly small.", call. = FALSE)

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/07_moj_medij_cards.R",
  input = list(file = input_path, sha256 = digest(input_path, algo = "sha256", file = TRUE),
               corpus_sha256 = payload$input$corpus_sha256),
  cards = lapply(seq_along(paths), function(i) list(
    source = sources[[i]]$n,
    file = card_files[i],
    bytes = unname(file.info(paths[i])$size),
    sha256 = digest(paths[i], algo = "sha256", file = TRUE)
  ))
)
write_json(manifest, file.path(target_dir, "manifest.json"), pretty = TRUE, auto_unbox = TRUE)
cat("\nZAPISANO:", length(paths), "PDF kartica i manifest.\n\n")
