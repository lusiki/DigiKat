#!/usr/bin/env Rscript
# =============================================================================
# R/wiki_sources.R  --  Source Wiki generator ("Katalog izvora")
# -----------------------------------------------------------------------------
# The "ingest" operation of the DigiKat Source Wiki (Karpathy LLM-wiki pattern).
# Reads the tracked, PII-free per-platform actor aggregates + a PI-owned labels
# sidecar, and WRITES one Quarto page per published actor, three platform hubs,
# and a catalog index, then appends a run entry to the log.
#
#   INPUTS  : data/processed/{web,youtube,facebook}_actors.rds   (read-only)
#             resources/dictionaries/source_labels.csv           (PI-owned)
#   OUTPUTS : pages/izvori/<platform>-<slug>.qmd                 (one per actor)
#             pages/izvori/platforma-{web,youtube,facebook}.qmd  (hubs)
#             pages/izvori/index.qmd                             (catalog)
#             pages/izvori/_log.md                               (append-only)
#
# Numbers + typology come from the aggregates (no hand-typing); labels/keep
# decisions come from the sidecar. Typology reuses mapa.qmd's Layer-1 rule
# (per-platform median split of interactions x reach).
#
# Run from the REPO ROOT:   Rscript R/wiki_sources.R
# Writes ONLY under pages/izvori/ -- never data/processed/*.rds.
# =============================================================================

## ---- config ---------------------------------------------------------------
proc_dir <- file.path("data", "processed")
out_dir  <- file.path("pages", "izvori")
sidecar  <- file.path("resources", "dictionaries", "source_labels.csv")
log_path <- file.path(out_dir, "_log.md")

platforms <- list(
  web      = list(file = "web_actors.rds",      display = "Web",      hub = "platforma-web"),
  youtube  = list(file = "youtube_actors.rds",  display = "YouTube",  hub = "platforma-youtube"),
  facebook = list(file = "facebook_actors.rds", display = "Facebook", hub = "platforma-facebook")
)

if (!dir.exists(proc_dir)) stop("Missing ", proc_dir, " -- run from the repo root.")
if (!dir.exists(out_dir))  dir.create(out_dir, recursive = TRUE)
if (!file.exists(sidecar)) stop("Missing sidecar ", sidecar)

GEN_DATE <- format(Sys.Date(), "%Y-%m-%d")
RUN_TS   <- format(Sys.time(), "%Y-%m-%d %H:%M")

## ---- helpers --------------------------------------------------------------
# Bullet-proof UTF-8 writer (Windows-safe: explicit bytes, no locale surprises).
write_utf8  <- function(lines, path) {
  con <- file(path, open = "wb"); on.exit(close(con))
  writeLines(enc2utf8(as.character(lines)), con, useBytes = TRUE)
}
append_utf8 <- function(lines, path) {
  con <- file(path, open = "ab"); on.exit(close(con))
  writeLines(enc2utf8(as.character(lines)), con, useBytes = TRUE)
}

# Croatian thousands grouping: 56500 -> "56.500" (decimal.mark set only to avoid a formatC warning)
fmt_int <- function(x) formatC(as.numeric(x), format = "d", big.mark = ".", decimal.mark = ",")

# ASCII kebab-case slug for FILENAMES ONLY (never for displayed corpus text).
# Explicit Croatian map (no iconv//TRANSLIT, per croatian-encoding rule);
# any remaining non-alnum (incl. Cyrillic) collapses to hyphens.
slugify <- function(x) {
  x <- as.character(x)
  mf <- c("č","ć","ž","š","đ","Č","Ć","Ž","Š","Đ")
  mt <- c("c","c","z","s","dj","c","c","z","s","dj")
  for (i in seq_along(mf)) x <- gsub(mf[i], mt[i], x, fixed = TRUE)
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("(^-+)|(-+$)", "", x)
  x[x == ""] <- "izvor"
  x
}

# Per-platform typology, identical rule to pages/mapa/mapa.qmd (median split).
classify_typology <- function(df) {
  mi <- median(df$total_interactions, na.rm = TRUE)
  mr <- median(df$total_reach, na.rm = TRUE)
  hi_i <- df$total_interactions >= mi
  hi_r <- df$total_reach >= mr
  ifelse(hi_i & hi_r, "Divovi",
  ifelse(hi_i & !hi_r, "Graditelji zajednica",
  ifelse(!hi_i & hi_r, "Megafoni", "Specijalizirani akteri")))
}

typ_read <- c(
  "Divovi"                 = "visok doseg i visok angažman — među vodećim akterima ekosustava.",
  "Graditelji zajednica"   = "nizak doseg uz vrlo visok angažman — gradi dubok odnos s vjernom publikom.",
  "Megafoni"               = "visok doseg uz nizak angažman — sadržaj doseže široku publiku bez intenzivne interakcije.",
  "Specijalizirani akteri" = "umjeren doseg i angažman — usmjeren na užu, specifičnu publiku."
)
label_hr <- c(confessional = "konfesionalni izvor", secular = "sekularni izvor", other = "ostalo")

## ---- read sidecar ---------------------------------------------------------
side <- read.csv(sidecar, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                 colClasses = "character", na.strings = "NA")
names(side) <- gsub("^﻿", "", names(side))   # strip a stray BOM if present
for (col in names(side)) side[[col]] <- enc2utf8(ifelse(is.na(side[[col]]), "", trimws(side[[col]])))

## ---- clean previously generated pages (keep _schema.md / _log.md) ----------
# Remove only the pages THIS script generates (index, hubs, actor pages); keep hand-authored
# pages such as mreza.qmd and the .md schema/log.
gen_pat <- "^(index|platforma-(web|youtube|facebook)|(web|youtube|facebook)-.*)\\.qmd$"
old <- list.files(out_dir, pattern = gen_pat, full.names = TRUE)
if (length(old)) invisible(file.remove(old))

## ---- page builders --------------------------------------------------------
metric_grid <- function(posts, inter, reach) {
  c('<div class="metric-grid">',
    '<div class="metric-card">',
    paste0('<div class="metric-value">', fmt_int(posts), '</div>'),
    '<div class="metric-label">Objava</div>',
    '</div>',
    '<div class="metric-card">',
    paste0('<div class="metric-value">', fmt_int(inter), '</div>'),
    '<div class="metric-label">Interakcija</div>',
    '</div>',
    '<div class="metric-card">',
    paste0('<div class="metric-value">', fmt_int(reach), '</div>'),
    '<div class="metric-label">Doseg</div>',
    '</div>',
    '</div>')
}

neighbor_md <- function(this_from, pub) {
  others <- pub[pub$FROM != this_from, , drop = FALSE]
  if (nrow(others) == 0) return("—")
  this_rank <- pub$rank[pub$FROM == this_from]
  others <- others[order(abs(others$rank - this_rank)), , drop = FALSE]
  sel <- others[seq_len(min(3, nrow(others))), , drop = FALSE]
  paste(sprintf("[%s](%s.html)", sel$FROM, sel$slug), collapse = ", ")
}

make_actor_page <- function(row, pkey, pub) {
  plat <- platforms[[pkey]]
  name <- row$FROM; ty <- row$typology
  ipp  <- if (row$total_posts > 0) round(row$total_interactions / row$total_posts) else 0

  desc_line <- if (row$description == "")
    "*Opis još nije potvrđen — uređuje PI.*" else row$description

  if (row$label == "" || is.na(label_hr[row$label])) {
    lab_line <- "*Uređivačka oznaka (konfesionalni/sekularni izvor) još nije određena — uređuje PI.*"
  } else {
    suffix <- if (identical(row$status, "confirmed")) "" else " *(predloženo — potvrđuje PI)*"
    lab_line <- paste0("Uređivačka oznaka: **", label_hr[[row$label]], "**", suffix)
  }

  c(
    "---",
    paste0('title: "', name, '"'),
    paste0('subtitle: "', plat$display, " · ", ty, '"'),
    "date: last-modified",
    paste0('categories: ["Katalog izvora", "', plat$display, '"]'),
    "---",
    "",
    paste0("Ova stranica sažima profil izvora **", name, "** u korpusu katoličke tematike. ",
           "Dio je **Kataloga izvora**, pregleda pojedinačnih aktera koji dopunjuje ",
           "[Mapu ekosustava](../mapa/mapa.html)."),
    "",
    "## Što je",
    "",
    desc_line,
    "",
    "## Profil",
    "",
    "Ključni pokazatelji ovog izvora u korpusu:",
    "",
    metric_grid(row$total_posts, row$total_interactions, row$total_reach),
    "",
    paste0("Po volumenu objava, ", name, " je na **", row$rank, ". mjestu** od ", row$n_platform,
           " praćenih izvora na platformi ", plat$display, ". Prosječno ostvaruje **",
           fmt_int(ipp), " interakcija po objavi**."),
    "",
    "## Tipologija",
    "",
    paste0("Prema tipologiji **Mape ekosustava** (podjela po medijanu angažmana i dosega ",
           "unutar platforme), ", name, " pripada skupini **", ty, "**: ", typ_read[[ty]]),
    "",
    lab_line,
    "",
    "## Povezano",
    "",
    paste0("- [Pregled platforme ", plat$display, "](", plat$hub, ".html)"),
    paste0("- Srodni akteri: ", neighbor_md(name, pub)),
    "- [Katalog izvora — sve platforme](index.html)",
    "",
    "## Izvori podataka",
    "",
    paste0("Podaci: `data/processed/", plat$file, "` (agregat bez osobnih podataka), ",
           "generirano skriptom `R/wiki_sources.R` (", GEN_DATE, ")."),
    "",
    "::: {.callout-warning}",
    paste0("Brojke su **indikativne**. Agregati su statični snimak razdoblja **2021.–2025.** ",
           "i ne uključuju Instagram i TikTok. Volumen se zbraja preko promjene metode ",
           "prikupljanja (~2024.), pa apsolutne vrijednosti valja tumačiti oprezno."),
    ":::",
    ""
  )
}

actor_table <- function(pub, cols = c("posts", "inter")) {
  header <- "| Izvor | Tipologija | Objava | Interakcija |"
  sep    <- "|---|---|---:|---:|"
  rows <- sprintf("| [%s](%s.html) | %s | %s | %s |",
                  pub$FROM, pub$slug, pub$typology,
                  fmt_int(pub$total_posts), fmt_int(pub$total_interactions))
  c(header, sep, rows)
}

hub_table <- function(pub) {
  header <- "| Izvor | Tipologija | Objava | Interakcija | Doseg |"
  sep    <- "|---|---|---:|---:|---:|"
  rows <- sprintf("| [%s](%s.html) | %s | %s | %s | %s |",
                  pub$FROM, pub$slug, pub$typology,
                  fmt_int(pub$total_posts), fmt_int(pub$total_interactions),
                  fmt_int(pub$total_reach))
  c(header, sep, rows)
}

## ---- main loop ------------------------------------------------------------
pubs <- list(); counts_pub <- integer(); held_rows <- list(); thin_rows <- character()

for (pkey in names(platforms)) {
  plat <- platforms[[pkey]]
  path <- file.path(proc_dir, plat$file)
  df <- as.data.frame(readRDS(path), stringsAsFactors = FALSE)
  df$FROM <- enc2utf8(as.character(df$FROM))

  # typology over ALL rows (consistent with mapa.qmd), then rank by volume
  df$typology <- classify_typology(df)
  df <- df[order(-df$total_posts), , drop = FALSE]
  df$rank <- seq_len(nrow(df)); df$n_platform <- nrow(df)
  df$slug <- paste0(pkey, "-", slugify(df$FROM))

  # join sidecar
  idx <- match(df$FROM, side$from)
  df$kind        <- ifelse(is.na(idx), "unclassified", side$kind[idx])
  df$label       <- ifelse(is.na(idx), "", side$label[idx])
  df$publish     <- ifelse(is.na(idx), "no", side$publish[idx])
  df$status      <- ifelse(is.na(idx), "", side$status[idx])
  df$description <- ifelse(is.na(idx), "", side$description[idx])

  is_pub <- df$publish == "yes" & df$kind == "institution"
  pub <- df[is_pub, , drop = FALSE]
  pubs[[pkey]] <- pub
  counts_pub[pkey] <- nrow(pub)

  # write actor pages
  for (i in seq_len(nrow(pub))) {
    row <- as.list(pub[i, ])
    write_utf8(make_actor_page(row, pkey, pub), file.path(out_dir, paste0(row$slug, ".qmd")))
  }

  # lint: thin published actors
  thin <- pub$FROM[pub$total_posts < 200]
  if (length(thin)) thin_rows <- c(thin_rows, sprintf("%s (%s, %d objava)",
                                    thin, plat$display, pub$total_posts[pub$total_posts < 200]))

  # held actors for the log
  held <- df[!is_pub, c("FROM", "kind"), drop = FALSE]
  if (nrow(held)) held_rows[[pkey]] <- data.frame(FROM = held$FROM, kind = held$kind,
                                                  platform = plat$display, stringsAsFactors = FALSE)

  # ---- platform hub page ----
  hub_lines <- c(
    "---",
    paste0('title: "Izvori — ', plat$display, '"'),
    paste0('subtitle: "Praćeni akteri na platformi ', plat$display, '"'),
    "date: last-modified",
    paste0('categories: ["Katalog izvora", "', plat$display, '"]'),
    "---",
    "",
    paste0("Ova stranica okuplja praćene izvore na platformi **", plat$display,
           "** iz **Kataloga izvora**. Tipologija je izračunata jednako kao u ",
           "[Mapi ekosustava](../mapa/mapa.html) — podjelom po medijanu angažmana i dosega. ",
           "Poredano po volumenu objava."),
    "",
    hub_table(pub),
    "",
    "[Natrag na katalog izvora](index.html) · [Mapa ekosustava](../mapa/mapa.html)",
    ""
  )
  write_utf8(hub_lines, file.path(out_dir, paste0(plat$hub, ".qmd")))
}

n_pub  <- sum(counts_pub)
held_all <- if (length(held_rows)) do.call(rbind, held_rows) else
            data.frame(FROM = character(), kind = character(), platform = character())
n_held <- nrow(held_all)

## ---- index (catalog front door) -------------------------------------------
idx_lines <- c(
  "---",
  'title: "Katalog izvora"',
  'subtitle: "Profili pojedinačnih medijskih aktera"',
  "date: last-modified",
  'categories: ["Katalog izvora", "Mapa ekosustava"]',
  "---",
  "",
  paste0("**Katalog izvora** pregled je pojedinačnih medijskih aktera zastupljenih u korpusu ",
         "i dopuna je analitičkoj [Mapi ekosustava](../mapa/mapa.html). Za svaki izvor donosi ",
         "volumen, angažman i doseg te pripadnost tipologiji (Divovi, Graditelji zajednica, ",
         "Megafoni, Specijalizirani akteri), izračunatoj jednako kao u Mapi."),
  "",
  paste0("Cijeli se katalog može vidjeti i kao [mreža izvora](mreza.html) — čvorovi su izvori, ",
         "a poveznice pripadnost platformi i zajednički brend."),
  "",
  "::: {.callout-note}",
  paste0("Podaci dolaze iz agregata `data/processed/*_actors.rds` (bez osobnih podataka). ",
         "Katalog je **radna verzija**: uređivačke oznake (konfesionalni/sekularni izvor) ",
         "prijedlozi su koje potvrđuje voditelj projekta, a brojke su indikativne (agregati ",
         "**2021.–2025.**, bez Instagrama i TikToka). Trenutno je objavljeno **", n_pub,
         "** izvora; **", n_held, "** aktera zadržano je za uredničku provjeru."),
  ":::",
  ""
)
for (pkey in names(platforms)) {
  plat <- platforms[[pkey]]
  idx_lines <- c(idx_lines,
    paste0("## ", plat$display),
    "",
    paste0("Praćeni izvori na platformi ", plat$display,
           " (poredano po volumenu). Cjeloviti pregled: [", plat$display,
           "](", plat$hub, ".html)."),
    "",
    actor_table(pubs[[pkey]]),
    ""
  )
}
write_utf8(idx_lines, file.path(out_dir, "index.qmd"))

## ---- append log -----------------------------------------------------------
if (!file.exists(log_path)) {
  write_utf8(c("# Katalog izvora — dnevnik (log)", "",
               "*Append-only. Generira `R/wiki_sources.R`.*", ""), log_path)
}
kinds <- c("individual", "noise", "offtopic", "duplicate", "unclassified")
held_lines <- character()
for (k in kinds) {
  who <- held_all$FROM[held_all$kind == k]
  if (length(who)) held_lines <- c(held_lines,
      paste0("  - ", k, ": ", paste(who, collapse = ", ")))
}
entry <- c(
  paste0("## ", RUN_TS),
  "",
  paste0("- Agregati (datoteka, mtime): ",
         paste(sprintf("%s (%s)", vapply(platforms, `[[`, "", "file"),
               vapply(names(platforms), function(k)
                 format(file.info(file.path(proc_dir, platforms[[k]]$file))$mtime, "%Y-%m-%d"), "")),
               collapse = ", ")),
  paste0("- Objavljeno: ", n_pub, " (",
         paste(sprintf("%s %d", vapply(platforms, `[[`, "", "display"), counts_pub), collapse = ", "),
         ")"),
  paste0("- Zadržano / isključeno: ", n_held),
  held_lines,
  paste0("- Lint (tanak uzorak, < 200 objava): ",
         if (length(thin_rows)) paste(thin_rows, collapse = "; ") else "nema"),
  ""
)
append_utf8(entry, log_path)

## ---- console summary ------------------------------------------------------
cat("\n=== Katalog izvora generated ===\n")
cat(sprintf("Published: %d  (%s)\n", n_pub,
    paste(sprintf("%s=%d", names(counts_pub), counts_pub), collapse = ", ")))
cat(sprintf("Held/excluded: %d\n", n_held))
cat(sprintf("Pages written under: %s\n", out_dir))
cat("Wrote NOTHING under data/processed/ (aggregates read-only).\n\n")
