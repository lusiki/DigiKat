#!/usr/bin/env Rscript
# Stage 3 — the visual system, the generated table fragments and the scalar registry.
#
# One chart FORM per recurring topic. Only the numbers change between editions. Every figure states
# its finding in the title, its measure in the subtitle and its source in the footer, and every one
# must read as a standalone screenshot. Colour is never the only encoding.

suppressPackageStartupMessages({
  library(here); library(dplyr); library(ggplot2); library(scales); library(jsonlite)
})
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")
source(here::here("R", "theme_digikat.R"), encoding = "UTF-8")
ar_readiness_ok()

# showtext rasterises text at a fixed dpi. The theme sets it for the site's 200 dpi chunks; report
# figures are saved at 300, and without this line every label would come out a third too small.
AR_DPI <- 300
if (requireNamespace("showtext", quietly = TRUE)) showtext::showtext_opts(dpi = AR_DPI)

# The report is set in Palatino and Segoe UI, so the figures are drawn in them too. The site's own
# Source Serif / Source Sans stay untouched — this override is local to the report, and the site
# figures keep the web design. Falls back silently to the theme's fonts if a face is unavailable.
if (requireNamespace("sysfonts", quietly = TRUE) && requireNamespace("showtext", quietly = TRUE)) {
  win_font <- function(...) {
    files <- file.path(Sys.getenv("WINDIR", "C:/Windows"), "Fonts", c(...))
    if (all(file.exists(files))) files else NULL
  }
  serif_files <- win_font("pala.ttf", "palab.ttf", "palai.ttf", "palabi.ttf")
  sans_files <- win_font("segoeui.ttf", "segoeuib.ttf", "segoeuii.ttf", "segoeuiz.ttf")
  if (!is.null(serif_files)) {
    sysfonts::font_add("ar_serif", regular = serif_files[1], bold = serif_files[2],
                       italic = serif_files[3], bolditalic = serif_files[4])
    dk_serif <- "ar_serif"
  }
  if (!is.null(sans_files)) {
    sysfonts::font_add("ar_sans", regular = sans_files[1], bold = sans_files[2],
                       italic = sans_files[3], bolditalic = sans_files[4])
    dk_sans <- "ar_sans"
    # Value labels and axis ticks move off the monospace face: in a report set in Palatino, a
    # typewriter number reads as a machine artefact rather than as part of the sentence.
    dk_mono <- "ar_sans"
  }
  showtext::showtext_auto()
}
# theme_digikat() reads dk_serif/dk_sans/dk_mono at call time, so the overrides above take effect.
ggplot2::theme_set(theme_digikat())
# The grid is scaffolding, not data. On cream at 0.4 it was still the loudest non-data ink in every
# figure; at 0.25 in the hairline tone it holds the eye's level without competing with the marks.
ggplot2::theme_update(
  panel.grid.major = ggplot2::element_line(colour = dk_col$hairline, linewidth = 0.25),
  panel.grid.minor = ggplot2::element_blank()
)

YEAR <- AR_REPORT_YEAR
cm <- digikat_read_corpus_manifest(here::here("data", "digikat_corpus_manifest.json"))
readiness <- fromJSON(file.path(AR_OUT, "readiness_manifest.json"))

platform <- ar_out_csv("volume_platform.csv")
monthly <- ar_out_csv("volume_monthly.csv")
daily <- ar_out_csv("volume_daily.csv")
arcs <- ar_out_csv("event_arcs.csv")
signature <- ar_out_csv("event_signature.csv")
stream <- ar_out_csv("stream_halfyear.csv")
concentration <- ar_out_csv("concentration.csv")
labels_tab <- ar_out_csv("source_labels.csv")
league <- ar_out_csv("league_sources.csv")
typology <- ar_out_csv("actor_typology.csv")
benchmarks <- ar_out_csv("engagement_benchmarks.csv")
eng_platform <- ar_out_csv("engagement_platform.csv")
themes <- ar_out_csv("themes.csv")
themes_cov <- ar_out_csv("themes_coverage.csv")
tone_overall <- ar_out_csv("tone_overall.csv")
tone_theme <- ar_out_csv("tone_by_theme.csv")
tone_label <- ar_out_csv("tone_by_label.csv")
nlp_cov <- ar_out_csv("nlp_coverage.csv")
special <- ar_out_csv("special_chapter.csv")
special_spec <- ar_special_chapter()
coverage <- ar_out_csv("coverage.csv")
gaps <- ar_out_csv("coverage_gaps.csv")

# Captions are read at figure width, not page width: wrap them so nothing runs off the paper.
cap <- function(...) paste(strwrap(paste(...), width = 96), collapse = "\n")
subt <- function(...) paste(strwrap(paste(...), width = 92), collapse = "\n")
# Titles are set in Palatino at 1.5x the base size, which is wider than it looks in the source:
# an unwrapped title runs off the edge of the canvas and is silently clipped.
ttl <- function(...) paste(strwrap(paste(...), width = 50), collapse = "\n")

total_posts <- sum(platform$total_posts)
sources_lab <- "Izvor: DigiKat, službeni korpus (%s objava, pravilo uključivanja v4 + drugi prolaz @0,70)."
src_note_corpus <- sprintf("Izvor: DigiKat, službeni korpus. Kalendarska %d.", YEAR)
src_note_theme <- sprintf(paste("Izvor: DigiKat, %s iz korpusa za %d. u tematskom uzorku",
                                "(%s posto korpusne godine; TikTok i tekstovi kraći od 101 znaka nisu obuhvaćeni)."),
                          ar_count_hr(nlp_cov$in_corpus_rows_year[nlp_cov$layer == "teme"], "objava"), YEAR,
                          ar_fmt_num_hr(100 * nlp_cov$effective_rate[nlp_cov$layer == "teme"], 1))
src_note_tone <- sprintf(paste("Izvor: DigiKat, %s iz korpusa za %d. u tonskom uzorku",
                               "(%s posto korpusne godine). Crte prikazuju 95-postotni interval."),
                         ar_count_hr(nlp_cov$in_corpus_rows_year[nlp_cov$layer == "ton"], "objava"), YEAR,
                         ar_fmt_num_hr(100 * nlp_cov$effective_rate[nlp_cov$layer == "ton"], 1))

# Titles, measures and source notes no longer live inside the PNGs. Each figure registers its words
# here; 04_sync installs them as real text, so they are set by the typesetter in the document's own
# font at page resolution instead of being rasterised at 300 dpi in a slightly different face.
FIG_WORDS <- list()
register_fig <- function(name, title, measure, note, alt) {
  FIG_WORDS[[name]] <<- list(title = title, measure = measure, note = note, alt = alt)
  invisible(name)
}

# Editorial wording is edition-specific even where the measure is not: one year's peak is a papal
# death, another's is Christmas. Each such site states every edition's sentence, keyed by reporting
# year, so a new edition fails loudly here instead of quietly reprinting last year's claim over this
# year's number.
ed <- function(...) {
  choices <- list(...)
  key <- as.character(YEAR)
  if (is.null(choices[[key]])) {
    stop("No edition wording for ", key, "; add it at this call site in 03_report_assets.R.", call. = FALSE)
  }
  choices[[key]]
}

fig <- function(name) file.path(AR_FIGURES, paste0(name, ".png"))
save_fig <- function(plot, name, width, height) {
  ggsave(fig(name), plot, width = width, height = height, dpi = AR_DPI, bg = dk_col$paper)
  invisible(fig(name))
}
# Figures are read on paper as often as on screen: every one keeps a second, non-colour encoding
# (position, direct label, or facet), so nothing depends on hue alone.
lab_mono <- function(...) geom_text(..., family = dk_mono, size = 3.0, colour = dk_col$body)

## === Figure 1 — the ten numbers of the year ======================================================
# A designed spread rather than a chart: ten generated numbers, each with one plain sentence.
make_tiles <- function(tiles) {
  n <- nrow(tiles)
  cols <- 2L
  tiles$row <- rep(seq_len(ceiling(n / cols)), each = cols)[seq_len(n)]
  tiles$col <- rep(seq_len(cols), times = ceiling(n / cols))[seq_len(n)]
  tiles$x <- tiles$col - 1
  tiles$y <- -tiles$row
  ggplot(tiles) +
    geom_rect(aes(xmin = x + 0.012, xmax = x + 0.988, ymin = y + 0.06, ymax = y + 0.97),
              fill = dk_col$panel, colour = dk_col$hairline, linewidth = 0.4) +
    geom_text(aes(x = x + 0.075, y = y + 0.72, label = value), hjust = 0, vjust = 0.5,
              family = dk_serif, fontface = "bold", size = 9.8, colour = dk_col$accent) +
    geom_text(aes(x = x + 0.075, y = y + 0.45, label = label), hjust = 0, vjust = 1,
              family = dk_sans, size = 3.4, colour = dk_col$body, lineheight = 1.35) +
    scale_x_continuous(expand = expansion(mult = 0.005)) +
    scale_y_continuous(expand = expansion(mult = 0.01)) +
    labs(title = NULL, subtitle = NULL, caption = NULL) +
    theme_digikat_void(base_size = 12) +
    theme(plot.margin = margin(10, 10, 8, 10),
          panel.grid.major = element_blank(), panel.grid.minor = element_blank())
}

wrap <- function(x, width = 42) vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"),
                                       character(1), USE.NAMES = FALSE)

web_share <- 100 * platform$post_share[platform$SOURCE_TYPE == "web"]
fb_share <- 100 * platform$post_share[platform$SOURCE_TYPE == "facebook"]
lead_theme <- themes[1, ]
abuse_share <- 100 * themes$share_of_mentions[themes$topic == "ZLOSTAVLJANJE_I_KRIZA_POVJERENJA"]
peak <- arcs[which.max(arcs$peak_posts), ]
conf_cli <- tone_label$cli_mean[tone_label$label == "confessional"]
sec_cli <- tone_label$cli_mean[tone_label$label == "secular"]
cli_ratio <- sec_cli / conf_cli
web_stream <- stream[stream$SOURCE_TYPE == "web", ]
classified_pct <- 100 * sum(labels_tab$posts[labels_tab$label %in% c("confessional", "secular")]) / total_posts

# The tenth tile is the one that changes shape between editions. In 2025 it is the year-over-year
# movement; 2024 has none to report, and the fact that most explains its year is how many days the
# collection actually covered — so that is what the spread carries instead.
tile_last <- ed(
  `2024` = list(value = ar_fmt_int_hr(coverage$collected_days),
                label = "dana u godini ima prikupljene podatke; ostatak kalendara je prekid"),
  `2025` = list(value = ar_fmt_change_hr(web_stream$change_pct),
                label = "više objava na webu u istom toku prikupljanja, uz manje praćenih izvora"))
tiles <- data.frame(
  value = c(ar_fmt_int_hr(total_posts),
            ar_fmt_pct_hr(web_share),
            ar_fmt_int_hr(concentration$distinct_sources),
            ar_fmt_int_hr(concentration$sources_to_half),
            ar_fmt_pct_hr(100 * lead_theme$share_of_docs),
            ar_fmt_pct_hr(abuse_share),
            ar_fmt_int_hr(peak$peak_posts),
            ar_fmt_pct_hr(100 * tone_overall$share_positive),
            paste0(ar_fmt_num_hr(cli_ratio, 2), "×"),
            tile_last$value),
  label = wrap(c(
    sprintf("%s o katoličkim temama zabilježeno je u %d. godini",
            ar_noun_hr(total_posts, "objava"), YEAR),
    "godišnjeg volumena nastalo je na webu, a ne na društvenim mrežama",
    "različitih izvora objavilo je barem jednu takvu objavu",
    "izvora čini polovicu cjelogodišnjeg volumena",
    "objava u tematskom uzorku vodi duhovnost i liturgija",
    "svih tematskih spominjanja odnosi se na zlostavljanje i krizu povjerenja",
    paste(ar_noun_hr(peak$peak_posts, "objava"),
          ed(`2024` = "zabilježeno je na Božić, 25. prosinca, najviše u cijeloj godini",
             `2025` = "zabilježeno je 21. travnja, na dan smrti pape Franje, najviše u cijeloj godini")),
    "objava u tonskom uzorku koristi pretežno pozitivan rječnik",
    "više riječi sukoba nose sekularni nego konfesionalni izvori",
    tile_last$label
  )),
  stringsAsFactors = FALSE
)
save_fig(make_tiles(tiles), "fig01_deset_brojeva", width = 7.4, height = 6.8)
register_fig("fig01_deset_brojeva", sprintf("Deset brojeva %d. godine", YEAR),
             "Svaki je broj izračunan iz korpusa; nijedan nije upisan rukom.",
             src_note_corpus,
             "Deset istaknutih brojeva godine, svaki s jednom rečenicom objašnjenja.")

## === Cover spark — the year in one line ==========================================================
# Not a chart: no axes, no labels, no grid. The reader sees the shape of the argument before the
# first word — one spike in April, everything else the ordinary rhythm of a liturgical year.
spark <- ar_out_csv("volume_daily.csv")
spark$date <- as.Date(spark$date)
spark$drawn <- ifelse(spark$collected, spark$posts, NA_real_)
spark_peak <- spark[which.max(spark$posts), ]
p_spark <- ggplot(spark, aes(date, drawn)) +
  geom_line(colour = dk_col$accent_200, linewidth = 0.55, na.rm = TRUE) +
  geom_point(data = spark_peak, aes(date, posts), colour = dk_col$alert, size = 1.9) +
  scale_y_continuous(limits = c(0, max(spark$posts) * 1.08), expand = expansion(mult = 0)) +
  scale_x_date(expand = expansion(mult = 0.005)) +
  labs(x = NULL, y = NULL) +
  theme_digikat_void(base_size = 10) +
  # theme_digikat sets panel.grid.major explicitly, so clearing the parent alone leaves it behind.
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        plot.margin = margin(0, 0, 0, 0))
save_fig(p_spark, "cover_spark", width = 7.4, height = 0.85)

## === Figure 2 — platform composition (ranked bars) ===============================================
plat <- platform |> filter(total_posts > 0) |> arrange(total_posts)
plat$platform_hr <- factor(plat$platform_hr, levels = plat$platform_hr)
plat$emphasis <- plat$SOURCE_TYPE == plat$SOURCE_TYPE[which.max(plat$total_posts)]
p2 <- ggplot(plat, aes(platform_hr, post_share)) +
  geom_col(aes(fill = emphasis), width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = paste0(ar_fmt_pct_hr(100 * post_share), "  ·  ", ar_fmt_int_hr(total_posts))),
            hjust = -0.08, family = dk_mono, size = 3.05, colour = dk_col$body) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = c(`TRUE` = dk_col$accent, `FALSE` = dk_col$accent_200)) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","),
                     expand = expansion(mult = c(0, 0.30))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12) +
  theme(panel.grid.major.y = element_blank())
save_fig(p2, "fig02_platforme", width = 7.2, height = 4.2)
register_fig("fig02_platforme", "Web nosi više od polovice zabilježenih objava",
             sprintf("Udio platforme u %s objava iz %d. godine, uz apsolutni broj.",
                     ar_fmt_int_hr(total_posts), YEAR),
             src_note_corpus,
             "Vodoravni stupci s udjelom svake platforme u godišnjem broju objava.")

## === Figure 3 — monthly rhythm (time lines, direct labels) =======================================
top3 <- head(platform$SOURCE_TYPE[order(-platform$total_posts)], 3L)
monthly$group <- ifelse(monthly$SOURCE_TYPE %in% top3, monthly$SOURCE_TYPE, "ostalo")
monthly$date <- as.Date(monthly$month)
mplot <- monthly |> group_by(date, group) |> summarise(posts = sum(total_posts), .groups = "drop")
group_cols <- c(dk_platform_colors[top3], ostalo = dk_col$muted)
group_lab <- c(unname(ar_platform_hr[top3]), "ostalo")
names(group_lab) <- c(top3, "ostalo")
ends <- mplot |> group_by(group) |> filter(date == max(date)) |> ungroup()
p3 <- ggplot(mplot, aes(date, posts, colour = group)) +
  geom_line(linewidth = 0.9, show.legend = FALSE) +
  geom_point(size = 1.5, show.legend = FALSE) +
  geom_text(data = ends, aes(label = group_lab[group]), hjust = -0.12, vjust = 0.4,
            family = dk_sans, size = 3.2, show.legend = FALSE) +
  scale_colour_manual(values = group_cols) +
  scale_x_date(breaks = seq(as.Date(sprintf("%d-01-01", YEAR)), as.Date(sprintf("%d-12-01", YEAR)), by = "month"),
               date_labels = "%b", expand = expansion(mult = c(0.02, 0.24))) +
  scale_y_continuous(labels = label_number(big.mark = AR_THIN, decimal.mark = ","),
                     limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12)
save_fig(p3, "fig03_mjeseci", width = 7.2, height = 4.2)
register_fig("fig03_mjeseci",
             ed(`2024` = "Krivulja počinje tek u lipnju, jer ranijih mjeseci u podacima nema",
                `2025` = "Travanj nosi vrh godine, a rujanski pad je prekid u prikupljanju"),
             "Mjesečni broj objava, tri najveće platforme i zbroj svih ostalih.",
             ed(`2024` = paste(src_note_corpus,
                               "Od 9. siječnja do 31. svibnja prikupljanja nema, pa te mjesece krivulja",
                               "ne prikazuje; rujan je nepotpun jer je prikupljanje stajalo od 16. do 30.",
                               "Nazivi platformi stoje uz krivulju, pa se čita i bez boje."),
                `2025` = paste(src_note_corpus,
                               "Rujan je nepotpun jer je prikupljanje stajalo prvih četrnaest dana.",
                               "Nazivi platformi stoje uz krivulju, pa se čita i bez boje.")),
             "Krivulje mjesečnog broja objava za web, Facebook, YouTube i zbroj ostalih platformi.")

## === Figure 4 — the year as a line, with named arcs ==============================================
daily$date <- as.Date(daily$date)
# The interruption is drawn as a break in the line, never as fourteen zero-days: a flat line at zero
# would tell the reader that nothing was published, which is not what the data says.
daily$drawn <- ifelse(daily$collected, daily$posts, NA_real_)
arc_points <- daily[daily$date %in% as.Date(arcs$peak_day), ]
# Names come from the reviewed registry in report_lib.R, matched on the date itself. A positional
# vector would relabel every peak the moment one year's arcs came out in a different order.
arc_points$label <- paste0(ar_event_name(arc_points$date), "\n",
                           as.integer(format(arc_points$date, "%d")), ". ",
                           ar_month_hr[as.integer(format(arc_points$date, "%m"))])
ymax <- max(daily$posts) * 1.30
p4 <- ggplot(daily, aes(date, drawn)) +
  {
    if (nrow(gaps)) annotate("rect", xmin = as.Date(gaps$start), xmax = as.Date(gaps$end),
                             ymin = 0, ymax = ymax, fill = dk_col$hairline, alpha = 0.65)
  } +
  {
    # The label belongs to the widest interruption; a fifteen-day band has no room to carry text.
    if (nrow(gaps)) {
      widest <- which.max(gaps$days)
      annotate("text",
               x = as.Date(gaps$start[widest]) + as.integer(gaps$days[widest] / 2),
               y = ymax * 0.52, label = "prekid u\nprikupljanju", hjust = 0.5, vjust = 1,
               family = dk_sans, size = 2.8, colour = dk_col$muted, lineheight = 1.05)
    }
  } +
  geom_line(colour = dk_col$accent_300, linewidth = 0.4, na.rm = TRUE) +
  geom_point(data = arc_points, colour = dk_col$alert, size = 2.6) +
  # Peaks late in the year need their label pulled left or it runs off the panel; the nudge is a
  # function of where the day falls, so it holds however many arcs an edition turns out to have.
  geom_text(data = arc_points, aes(label = label), vjust = -0.55,
            hjust = as.integer(format(arc_points$date, "%j")) / AR_CALENDAR_DAYS,
            family = dk_sans, size = 2.9, colour = dk_col$body, lineheight = 1.05) +
  scale_x_date(breaks = seq(as.Date(sprintf("%d-01-01", YEAR)), as.Date(sprintf("%d-12-01", YEAR)), by = "month"),
               date_labels = "%b",
               limits = c(as.Date(sprintf("%d-01-01", YEAR)), as.Date(sprintf("%d-12-31", YEAR))),
               expand = expansion(mult = 0.01)) +
  scale_y_continuous(labels = label_number(big.mark = AR_THIN, decimal.mark = ","),
                     limits = c(0, ymax), expand = expansion(mult = c(0, 0))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12)
save_fig(p4, "fig04_godina", width = 7.4, height = 4.2)
register_fig("fig04_godina",
             ed(`2024` = "Oba vrha godine su blagdani, a Uskrs je ostao izvan prikupljanja",
                `2025` = "Godina ima jedan vrh, i on nije bio sporan"),
             sprintf("Broj objava po danu, %s s prikupljanjem; označeni su dani iznad tri standardne devijacije.",
                     ar_count_hr(coverage$collected_days, "dan")),
             ed(`2024` = paste(src_note_corpus,
                               "Prag za vrhunac postavljen je prije pregleda podataka, a prosjek i",
                               "raspršenost računaju se samo nad danima s prikupljanjem. Uskrs 2024.",
                               "pada 31. ožujka, unutar dugoga prekida, pa ga u podacima nema.",
                               "Sivo su označena razdoblja bez prikupljanja."),
                `2025` = paste(src_note_corpus,
                               "Prag za vrhunac postavljen je prije pregleda podataka, a prosjek i raspršenost",
                               "računaju se samo nad danima s prikupljanjem.")),
             "Dnevni broj objava kroz cijelu godinu s označenim vrhuncima i prekidom u prikupljanju.")

## === Figure 5 — the sixteen categories (ranked bars) =============================================
th <- themes |> arrange(share_of_mentions)
th$topic_hr <- factor(th$topic_hr, levels = th$topic_hr)
th$emphasis <- th$rank == 1
p5 <- ggplot(th, aes(topic_hr, share_of_mentions)) +
  geom_col(aes(fill = emphasis), width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = ar_fmt_pct_hr(100 * share_of_mentions)), hjust = -0.12,
            family = dk_mono, size = 2.95, colour = dk_col$body) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = c(`TRUE` = dk_col$accent, `FALSE` = dk_col$accent_200)) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","),
                     expand = expansion(mult = c(0, 0.22))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.y = element_blank())
save_fig(p5, "fig05_teme", width = 7.2, height = 5.8)
register_fig("fig05_teme", "Godinu vodi ono što Crkva radi svaki tjedan",
             "Udio svih rječničkih spominjanja po kategoriji; prikazano je svih šesnaest kategorija.",
             src_note_theme,
             "Vodoravni stupci s udjelom svih šesnaest tematskih kategorija.")

## === Figure 6 — tone by theme (dot plot with intervals) ==========================================
tt <- tone_theme |> filter(reportable) |> arrange(sentiment_mean)
tt$topic_hr <- factor(tt$topic_hr, levels = tt$topic_hr)
p6 <- ggplot(tt, aes(sentiment_mean, topic_hr)) +
  geom_vline(xintercept = 0, colour = dk_col$line, linewidth = 0.4, linetype = "22") +
  geom_segment(aes(x = sentiment_lower, xend = sentiment_upper, yend = topic_hr),
               colour = dk_col$accent_200, linewidth = 1.1) +
  geom_point(aes(colour = sentiment_mean >= 0), size = 3.1, show.legend = FALSE) +
  geom_text(aes(label = ar_fmt_num_hr(sentiment_mean, 2)), vjust = -1.05,
            family = dk_mono, size = 2.85, colour = dk_col$body) +
  scale_colour_manual(values = c(`TRUE` = dk_col$pos, `FALSE` = dk_col$neg)) +
  scale_x_continuous(labels = label_number(decimal.mark = ","),
                     expand = expansion(mult = c(0.10, 0.10))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.y = element_blank())
save_fig(p6, "fig06_ton_teme", width = 7.2, height = 4.2)
register_fig("fig06_ton_teme", "Nijedna tema godine nije u prosjeku negativna",
             "Prosječan tonski rezultat po vodećoj temi objave, od −1 do +1; kategorije s najmanje 30 objava.",
             src_note_tone,
             "Točkasti prikaz prosječnog tonskog rezultata po vodećim temama, s intervalima pouzdanosti.")

## === Figure 7 — confessional vs secular (small multiples) ========================================
tl <- tone_label |> filter(label != "unclassified")
tl_long <- rbind(
  data.frame(label_hr = tl$label_hr, panel = "Tonski rezultat (−1 do +1)",
             value = tl$sentiment_mean, lower = tl$sentiment_lower, upper = tl$sentiment_upper,
             n = tl$n_docs, stringsAsFactors = FALSE),
  data.frame(label_hr = tl$label_hr, panel = "Riječi sukoba na 1 000 riječi",
             value = tl$cli_mean, lower = tl$cli_lower, upper = tl$cli_upper,
             n = tl$n_docs, stringsAsFactors = FALSE)
)
tl_long$panel <- factor(tl_long$panel, levels = c("Tonski rezultat (−1 do +1)", "Riječi sukoba na 1 000 riječi"))
tl_long$mark <- ifelse(tl_long$panel == "Tonski rezultat (−1 do +1)",
                       ar_fmt_num_hr(tl_long$value, 2), ar_fmt_num_hr(tl_long$value, 0))
p7 <- ggplot(tl_long, aes(value, label_hr)) +
  geom_segment(aes(x = lower, xend = upper, yend = label_hr), colour = dk_col$accent_200, linewidth = 1.2) +
  geom_point(size = 3.2, colour = dk_col$accent) +
  geom_text(aes(label = mark), vjust = -1.1, family = dk_mono, size = 2.9, colour = dk_col$body) +
  facet_wrap(~ panel, scales = "free_x") +
  scale_x_continuous(labels = label_number(decimal.mark = ","), expand = expansion(mult = 0.18)) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.y = element_blank(), panel.spacing.x = unit(16, "pt"))
save_fig(p7, "fig07_ton_oznake", width = 7.4, height = 2.6)
register_fig("fig07_ton_oznake", "Sekularni izvori pišu o istoj temi oštrijim rječnikom",
             sprintf("Konfesionalni (%s objava) i sekularni izvori (%s objava) u tonskom uzorku.",
                     ar_fmt_int_hr(tl$n_docs[tl$label == "confessional"]),
                     ar_fmt_int_hr(tl$n_docs[tl$label == "secular"])),
             paste(src_note_tone,
                   "Uredničke oznake izvora imaju status prijedloga, pa je usporedba indikativna."),
             "Usporedba tonskog rezultata i indeksa riječi sukoba za konfesionalne i sekularne izvore.")

## === Figure 8 — the movement inside one collection stream (slope chart) ==========================
# One chart FORM per recurring topic: a two-point slope, whatever the two points are this edition.
# What changes between editions is which periods the stream aggregate could honestly pair, and in
# what unit — both of which arrive as columns, so the drawing code stays edition-blind.
stream_is_rate <- stream$unit[1] != "objave"
stream_floor <- if (stream_is_rate) 3 else 300
stream_fmt <- function(x) if (stream_is_rate) ar_fmt_num_hr(x, 1) else ar_fmt_int_hr(x)
sl <- stream |> filter(report_value >= stream_floor | base_value >= stream_floor)
sl_long <- rbind(
  data.frame(platform_hr = sl$platform_hr, x = sl$base_label, posts = sl$base_value, stringsAsFactors = FALSE),
  data.frame(platform_hr = sl$platform_hr, x = sl$report_label, posts = sl$report_value, stringsAsFactors = FALSE)
)
sl_long$x <- factor(sl_long$x, levels = c(sl$base_label[1], sl$report_label[1]))
# Both endpoints ride on the right-hand label. Printing the opening value beside its own point put
# Facebook's 7 447 on top of YouTube's 7 025 on the log scale.
sl_end <- sl_long[sl_long$x == sl$report_label[1], ]
sl_end$mark <- paste0("  ", sl$platform_hr[match(sl_end$platform_hr, sl$platform_hr)], " · ",
                      stream_fmt(sl$base_value[match(sl_end$platform_hr, sl$platform_hr)]), " → ",
                      stream_fmt(sl_end$posts))
# Two platforms can finish the period within a hair of each other, and on a log axis their labels
# then print on top of one another. The MARK is nudged apart; the point itself never moves, so the
# chart still shows the true value and only the text is allowed to breathe.
sl_end <- sl_end[order(sl_end$posts), ]
label_y <- log10(sl_end$posts)
min_sep <- diff(range(log10(sl_long$posts))) * 0.045
for (i in seq_along(label_y)[-1]) {
  label_y[i] <- max(label_y[i], label_y[i - 1] + min_sep)
}
sl_end$label_y <- 10^label_y
p8 <- ggplot(sl_long, aes(x, posts, group = platform_hr)) +
  geom_line(colour = dk_col$accent_300, linewidth = 0.9) +
  geom_point(size = 2.6, colour = dk_col$accent) +
  geom_text(data = sl_end, aes(y = label_y, label = mark), hjust = 0, family = dk_sans, size = 3.1,
            colour = dk_col$body) +
  scale_y_continuous(trans = "log10", labels = label_number(big.mark = AR_THIN, decimal.mark = ",")) +
  scale_x_discrete(expand = expansion(mult = c(0.18, 0.86))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.x = element_blank(), axis.text.y = element_blank())
save_fig(p8, "fig08_tok", width = 7.2, height = 4.2)
register_fig("fig08_tok",
             ed(`2024` = "Facebook se gotovo udvostručuje, ali s njim raste i popis praćenih stranica",
                `2025` = "Web raste iako pratimo manje izvora nego godinu prije"),
             ed(`2024` = paste("Objave po danu s prikupljanjem, treće prema četvrtom tromjesečju,",
                               "unutar toka prikupljanja koji teče od srpnja 2024.; logaritamska skala."),
                `2025` = paste("Objave u drugoj polovici godine, unutar toka prikupljanja koji teče",
                               "od srpnja 2024.; logaritamska skala.")),
             ed(`2024` = paste("Izvor: DigiKat, službeni korpus, tok post2024.",
                               "Ovo je kretanje unutar godine, a ne usporedba s prethodnom godinom:",
                               "tok prikupljanja počinje u srpnju 2024., pa 2024. nema usporedivu",
                               "prethodnu godinu. Četvrto tromjesečje nosi advent i Božić, što dio",
                               "porasta objašnjava sezonom. Dijeljenjem s brojem dana s prikupljanjem",
                               "rujanski prekid ne može izgledati kao pad."),
                `2025` = paste("Izvor: DigiKat, službeni korpus, tok post2024.",
                               "Usporedba ne prelazi prijelom u prikupljanju iz 2024., a iz obiju polovica",
                               "uklonjeni su isti kalendarski dani prekida.")),
             ed(`2024` = paste("Nagibni prikaz broja objava po danu s prikupljanjem, po platformama,",
                               "u trećem i četvrtom tromjesečju 2024."),
                `2025` = "Nagibni prikaz broja objava po platformama u drugoj polovici 2024. i 2025."))

## === Figure 9 — concentration curve ==============================================================
src_private <- ar_read_csv(file.path(AR_PRIVATE, "sources_private.csv"))
by_source <- src_private |> group_by(source_key) |> summarise(posts = sum(posts), .groups = "drop") |>
  arrange(desc(posts))
curve <- data.frame(rank = seq_len(nrow(by_source)),
                    cum = cumsum(by_source$posts) / sum(by_source$posts))
half_rank <- concentration$sources_to_half
p9 <- ggplot(curve, aes(rank, cum)) +
  geom_line(colour = dk_col$accent, linewidth = 0.9) +
  geom_segment(x = log10(1), xend = log10(half_rank), y = 0.5, yend = 0.5,
               colour = dk_col$alert, linewidth = 0.4, linetype = "22") +
  geom_point(x = log10(half_rank), y = 0.5, colour = dk_col$alert, size = 2.8) +
  annotate("text", x = half_rank * 1.25, y = 0.5,
           label = sprintf("%s izvora → polovica godine", ar_fmt_int_hr(half_rank)),
           hjust = 0, vjust = -0.7, family = dk_sans, size = 3.2, colour = dk_col$body) +
  scale_x_log10(breaks = c(1, 10, 100, 1000, 5000),
                labels = label_number(big.mark = AR_THIN, decimal.mark = ",")) +
  scale_y_continuous(labels = label_percent(decimal.mark = ","), limits = c(0, 1),
                     expand = expansion(mult = c(0.01, 0.03))) +
  labs(title = NULL, subtitle = NULL, caption = NULL,
       x = "Rang izvora (logaritamska skala)", y = NULL) +
  theme_digikat(base_size = 11)
save_fig(p9, "fig09_koncentracija", width = 7.2, height = 4.2)
register_fig("fig09_koncentracija", "Malo izvora nosi mnogo, ali rep je vrlo dug",
             sprintf("Kumulativni udio godišnjeg volumena po rangu izvora; ukupno %s izvora.",
                     ar_fmt_int_hr(concentration$distinct_sources)),
             src_note_corpus,
             "Krivulja kumulativnog udjela godišnjeg volumena po rangu izvora.")

## === Figure word blocks ==========================================================================
for (nm in names(FIG_WORDS)) {
  w <- FIG_WORDS[[nm]]
  ar_figure(file.path(AR_TABLES, paste0("block_", nm, ".md")), nm, w$title, w$measure, w$note, w$alt)
}

## === Scalar registry =============================================================================
derived <- data.frame(key = character(), value = character(), display_hr = character(),
                      display_en = character(), source = character(), scope = character(),
                      unit = character(), summary = logical(), stringsAsFactors = FALSE)
add <- function(key, value, hr, en, source, scope, unit, summary = FALSE) {
  derived <<- rbind(derived, data.frame(key = key, value = as.character(value), display_hr = hr,
                                        display_en = en, source = source, scope = scope, unit = unit,
                                        summary = summary, stringsAsFactors = FALSE))
}
add_int <- function(key, x, source, scope, summary = FALSE)
  add(key, x, ar_fmt_int_hr(x), ar_fmt_int_en(x), source, scope, "posts", summary)
add_pct <- function(key, x, source, scope, summary = FALSE, digits = 1L)
  add(key, x, ar_fmt_pct_hr(x, digits), ar_fmt_pct_en(x, digits), source, scope, "percent", summary)

add("report_year", YEAR, as.character(YEAR), as.character(YEAR), "report contract", "annual", "year")
add("baseline_year", AR_BASELINE_YEAR, as.character(AR_BASELINE_YEAR), as.character(AR_BASELINE_YEAR),
    "report contract", "series rule", "year")
add_int("corpus_rows", cm$corpus$rows, "data/digikat_corpus_manifest.json", "all period")
add("corpus_span", paste(cm$corpus$date_min, cm$corpus$date_max),
    paste0("od 1. siječnja 2021. do ", ar_date_hr(cm$corpus$date_max)),
    paste0("1 January 2021 to ", format(as.Date(cm$corpus$date_max), "%d %B %Y")),
    "data/digikat_corpus_manifest.json", "all period", "span")
add("corpus_terms", cm$rule$terms_count, ar_fmt_int_hr(cm$rule$terms_count),
    ar_fmt_int_en(cm$rule$terms_count), "data/digikat_corpus_manifest.json", "inclusion rule", "terms")
add("corpus_threshold", cm$rule$threshold, ar_fmt_num_hr(cm$rule$threshold, 2),
    ar_fmt_num_en(cm$rule$threshold, 2), "data/digikat_corpus_manifest.json", "inclusion rule", "score")
add("corpus_precision", 84.5, ar_fmt_pct_hr(84.5), ar_fmt_pct_en(84.5),
    "data/digikat_corpus_manifest.json", "measured on hand-read samples", "percent")
add("corpus_sha_short", substr(cm$corpus$sha256, 1, 12), substr(cm$corpus$sha256, 1, 12),
    substr(cm$corpus$sha256, 1, 12), "data/digikat_corpus_manifest.json", "fingerprint", "sha256")

add_int("total_posts", total_posts, "output/volume_platform.csv", as.character(YEAR), TRUE)
# In 2025 the collected-day count is context; in 2024 it is one of the ten findings, because 159 of
# 366 days carry nothing and no reading of that year survives without it.
add("collected_days", coverage$collected_days, ar_fmt_int_hr(coverage$collected_days),
    ar_fmt_int_en(coverage$collected_days), "output/coverage.csv", as.character(YEAR), "days",
    ed(`2024` = TRUE, `2025` = FALSE))
add("gap_days", coverage$gap_days, ar_fmt_int_hr(coverage$gap_days), ar_fmt_int_en(coverage$gap_days),
    "output/coverage.csv", as.character(YEAR), "days")
# Every interruption is named, not just the first: 2024 has two, and printing one of them would
# understate the hole by fifteen days.
add("gap_span", coverage$gap_spans,
    paste(sprintf("od %s do %s", ar_date_hr(gaps$start), ar_date_hr(gaps$end)), collapse = " i "),
    paste(sprintf("%s to %s", format(as.Date(gaps$start), "%d %B"),
                  format(as.Date(gaps$end), "%d %B %Y")), collapse = " and "),
    "output/coverage_gaps.csv", as.character(YEAR), "span")
add_int("gap_estimated_posts", coverage$estimated_missing_posts, "output/coverage.csv", as.character(YEAR))
add("median_day", coverage$median_collected_day, ar_fmt_int_hr(coverage$median_collected_day),
    ar_fmt_int_en(coverage$median_collected_day), "output/coverage.csv", "days around the gap", "posts")
add_pct("web_share", web_share, "output/volume_platform.csv", as.character(YEAR), TRUE)
add_pct("facebook_share", fb_share, "output/volume_platform.csv", as.character(YEAR))
add_pct("youtube_share", 100 * platform$post_share[platform$SOURCE_TYPE == "youtube"],
        "output/volume_platform.csv", as.character(YEAR))
add_pct("facebook_reach_share", 100 * platform$reach_share[platform$SOURCE_TYPE == "facebook"],
        "output/volume_platform.csv", as.character(YEAR))
add_int("distinct_sources", concentration$distinct_sources, "output/concentration.csv", as.character(YEAR), TRUE)
add("sources_to_half", concentration$sources_to_half, ar_fmt_int_hr(concentration$sources_to_half),
    ar_fmt_int_en(concentration$sources_to_half), "output/concentration.csv", as.character(YEAR), "sources", TRUE)
add_pct("top10_share", concentration$top10_share, "output/concentration.csv", as.character(YEAR))
add_pct("classified_coverage", classified_pct, "output/source_labels.csv", as.character(YEAR))
add_pct("confessional_share_classified",
        100 * labels_tab$share_of_classified[labels_tab$label == "confessional"],
        "output/source_labels.csv", "classified posts")
add_int("league_outlets", nrow(league), "output/league_sources.csv", as.character(YEAR))
add_pct("league_share", sum(league$share_of_year), "output/league_sources.csv", as.character(YEAR))
add("actors_scored", sum(typology$actors), ar_fmt_int_hr(sum(typology$actors)),
    ar_fmt_int_en(sum(typology$actors)), "output/actor_typology.csv", as.character(YEAR), "actors")

add_pct("lead_theme_docs", 100 * lead_theme$share_of_docs, "output/themes.csv", "theme sample", TRUE)
add("lead_theme_hr", lead_theme$topic_hr, lead_theme$topic_hr, "spirituality and liturgy",
    "output/themes.csv", "theme sample", "category")
add_pct("lead_theme_mentions", 100 * lead_theme$share_of_mentions, "output/themes.csv", "theme sample")
add_pct("abuse_share", abuse_share, "output/themes.csv", "theme sample", TRUE)
add_pct("disputes_share", 100 * themes$share_of_mentions[themes$topic == "UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE"],
        "output/themes.csv", "theme sample")
add_int("theme_docs", nlp_cov$in_corpus_rows_year[nlp_cov$layer == "teme"], "output/nlp_coverage.csv", "theme sample")
add_pct("theme_rate", 100 * nlp_cov$effective_rate[nlp_cov$layer == "teme"], "output/nlp_coverage.csv", "theme sample")
add_int("tone_docs", nlp_cov$in_corpus_rows_year[nlp_cov$layer == "ton"], "output/nlp_coverage.csv", "tone sample")
add_pct("tone_rate", 100 * nlp_cov$effective_rate[nlp_cov$layer == "ton"], "output/nlp_coverage.csv", "tone sample")

add("tone_mean", tone_overall$sentiment_mean, ar_fmt_num_hr(tone_overall$sentiment_mean, 2),
    ar_fmt_num_en(tone_overall$sentiment_mean, 2), "output/tone_overall.csv", "tone sample", "score")
add_pct("tone_positive_share", 100 * tone_overall$share_positive, "output/tone_overall.csv", "tone sample", TRUE)
add("cli_mean", tone_overall$cli_mean, ar_fmt_num_hr(tone_overall$cli_mean, 0),
    ar_fmt_num_en(tone_overall$cli_mean, 0), "output/tone_overall.csv", "tone sample", "per 1000 words")
add("cli_confessional", conf_cli, ar_fmt_num_hr(conf_cli, 0), ar_fmt_num_en(conf_cli, 0),
    "output/tone_by_label.csv", "tone sample", "per 1000 words")
add("cli_secular", sec_cli, ar_fmt_num_hr(sec_cli, 0), ar_fmt_num_en(sec_cli, 0),
    "output/tone_by_label.csv", "tone sample", "per 1000 words")
add("cli_ratio", cli_ratio, paste0(ar_fmt_num_hr(cli_ratio, 2), "×"),
    paste0(ar_fmt_num_en(cli_ratio, 2), "×"), "output/tone_by_label.csv", "tone sample", "ratio", TRUE)

add_int("peak_posts", peak$peak_posts, "output/event_arcs.csv", "peak day", TRUE)
add("peak_day", peak$peak_day, ar_date_hr(peak$peak_day),
    format(as.Date(peak$peak_day), "%d %B %Y"), "output/event_arcs.csv", "peak day", "date")
add("peak_z", peak$peak_z, ar_fmt_num_hr(peak$peak_z, 1), ar_fmt_num_en(peak$peak_z, 1),
    "output/event_arcs.csv", "peak day", "sd")
add_int("peak_arc_posts", peak$arc_posts, "output/event_arcs.csv", "peak arc")
add("peak_arc_span", paste(peak$start, peak$end),
    paste0("od ", ar_date_short_hr(peak$start), " do ", ar_date_short_hr(peak$end)),
    paste(format(as.Date(peak$start), "%d %B"), "to", format(as.Date(peak$end), "%d %B %Y")),
    "output/event_arcs.csv", "peak arc", "span")
add("arcs_n", nrow(arcs), ar_fmt_int_hr(nrow(arcs)), ar_fmt_int_en(nrow(arcs)),
    "output/event_arcs.csv", as.character(YEAR), "arcs")

# The stream movement is a headline finding only where it is a year-over-year one. In 2024 it is a
# within-year quarter step that carries the Advent season inside it, so it stays in the chapter body.
add("web_stream_change", web_stream$change_pct, ar_fmt_change_hr(web_stream$change_pct),
    ar_fmt_change_en(web_stream$change_pct), "output/stream_halfyear.csv", "post-2024 stream", "percent",
    ed(`2024` = FALSE, `2025` = TRUE))
add("web_stream_sources_change", web_stream$sources_change_pct, ar_fmt_change_hr(web_stream$sources_change_pct),
    ar_fmt_change_en(web_stream$sources_change_pct), "output/stream_halfyear.csv", "post-2024 stream", "percent")
add("facebook_stream_change", stream$change_pct[stream$SOURCE_TYPE == "facebook"],
    ar_fmt_change_hr(stream$change_pct[stream$SOURCE_TYPE == "facebook"]),
    ar_fmt_change_en(stream$change_pct[stream$SOURCE_TYPE == "facebook"]),
    "output/stream_halfyear.csv", "post-2024 stream", "percent")
add("facebook_stream_sources_change", stream$sources_change_pct[stream$SOURCE_TYPE == "facebook"],
    ar_fmt_change_hr(stream$sources_change_pct[stream$SOURCE_TYPE == "facebook"]),
    ar_fmt_change_en(stream$sources_change_pct[stream$SOURCE_TYPE == "facebook"]),
    "output/stream_halfyear.csv", "post-2024 stream", "percent")
add("stream_base_label", stream$base_label[1], stream$base_label[1], stream$base_label[1],
    "output/stream_halfyear.csv", "post-2024 stream", "period")
add("stream_report_label", stream$report_label[1], stream$report_label[1], stream$report_label[1],
    "output/stream_halfyear.csv", "post-2024 stream", "period")

special_val <- function(k) ar_parse_value(special$value[special[[special_spec$name_column]] == k])
special_source <- file.path("studies", special_spec$study)
if (YEAR == 2025L) {
  add("special_linked", special_val("linked_posts"), ar_fmt_int_hr(special_val("linked_posts")),
      ar_fmt_int_en(special_val("linked_posts")), special_source, "study period", "posts")
  # The corrected headline is a SHARE of post-domain pairs. Printed bare it read as a count of
  # pairs in the sentence that quotes it, so the unit travels with the value.
  add("special_headline", special_val("corrected_headline"),
      ar_fmt_pct_hr(special_val("corrected_headline"), 2), ar_fmt_pct_en(special_val("corrected_headline"), 2),
      special_source, "study period", "percent")
} else {
  add("special_linked", special_val("n_linked"), ar_fmt_int_hr(special_val("n_linked")),
      ar_fmt_int_en(special_val("n_linked")), special_source, "study period", "posts")
  add("special_core", special_val("n_core"), ar_fmt_int_hr(special_val("n_core")),
      ar_fmt_int_en(special_val("n_core")), special_source, "study period", "posts")
  add("special_peak_posts", special_val("peak_n_repricing"), ar_fmt_int_hr(special_val("peak_n_repricing")),
      ar_fmt_int_en(special_val("peak_n_repricing")), special_source, "study period", "posts")
  add("special_lag_months", special_val("v2_hicp_repricing_lag_months"),
      ar_fmt_int_hr(special_val("v2_hicp_repricing_lag_months")),
      ar_fmt_int_en(special_val("v2_hicp_repricing_lag_months")),
      special_source, "study period", "months")
}

if (anyDuplicated(derived$key)) stop("Duplicate scalar key.")
if (any(!nzchar(derived$display_hr))) stop("A scalar has no Croatian display value.")
ar_write_csv(derived, file.path(AR_OUT, "annual_report_derived.csv"))

val <- function(key, lang = "hr") {
  col <- if (lang == "hr") "display_hr" else "display_en"
  i <- match(key, derived$key)
  if (is.na(i)) stop("Unknown scalar: ", key)
  derived[[col]][i]
}

## === Summary: ten findings, one generated number each ============================================
summary_hr <- c(
  paste0("Zabilježili smo **", ar_count_hr(total_posts, "objava"), "** o katoličkim temama u ", YEAR, ". godini."),
  paste0("Web je i dalje glavno mjesto rasprave i nosi **", val("web_share"), "** godišnjeg volumena."),
  paste0("Objave dolaze iz **", val("distinct_sources"), " različitih izvora**, što je vrlo raspršen prostor."),
  paste0("Na samo **", ar_count_hr(concentration$sources_to_half, "izvor"),
         "** otpada polovica cjelogodišnjeg volumena."),
  paste0("Duhovnost i liturgija vode godinu i glavna su tema u **", val("lead_theme_docs"), " objava**."),
  paste0("Zlostavljanje i kriza povjerenja čine **", val("abuse_share"), "** svih tematskih spominjanja."),
  ed(`2024` = paste0("Najjači dan godine bio je Božić, s **", ar_count_hr(peak$peak_posts, "objava"), "**."),
     `2025` = paste0("Na dan smrti pape Franje zabilježili smo **",
                     ar_count_hr(peak$peak_posts, "objava"), "**, najviše u cijeloj godini.")),
  paste0("Pretežno pozitivan rječnik koristi **", val("tone_positive_share"), " objava**."),
  paste0("Sekularni izvori nose **", val("cli_ratio"), "** više riječi sukoba od konfesionalnih."),
  ed(`2024` = paste0("Podatke smo bilježili **", val("collected_days"),
                     " dana**; ostatak kalendara nema prikupljanja, pa ni Uskrsa nema u podacima."),
     `2025` = paste0("Web je u drugoj polovici godine objavio **", val("web_stream_change"),
                     "** više nego godinu prije."))
)
summary_en <- c(
  paste0("We recorded **", val("total_posts", "en"), " posts** on Catholic themes during ", YEAR, "."),
  paste0("The web remains the main venue and carries **", val("web_share", "en"), "** of annual volume."),
  paste0("The posts come from **", val("distinct_sources", "en"), " distinct sources**, a highly dispersed space."),
  paste0("Even so, just **", val("sources_to_half", "en"), " sources** account for half of the year's volume."),
  paste0("Spirituality and liturgy lead the year, dominant in **", val("lead_theme_docs", "en"), " of posts** in the theme sample."),
  paste0("Abuse and the crisis of trust account for **", val("abuse_share", "en"), "** of all dictionary mentions."),
  ed(`2024` = paste0("The strongest day of the year was Christmas, with **", val("peak_posts", "en"), " posts**."),
     `2025` = paste0("On the day Pope Francis died we recorded **", val("peak_posts", "en"),
                     " posts**, the most in the whole year.")),
  paste0("Predominantly positive vocabulary appears in **", val("tone_positive_share", "en"), " of posts** in the tone sample."),
  paste0("Secular sources carry **", val("cli_ratio", "en"), "** as many conflict words as confessional ones."),
  ed(`2024` = paste0("Collection covered **", val("collected_days", "en"),
                     " days** of the year; the rest is an interruption, and Easter falls inside it."),
     `2025` = paste0("In the second half of the year the web carried **",
                     val("web_stream_change", "en"), "** more than a year earlier."))
)
# Each finding is its own bullet: run together as a paragraph, ten findings read as one blur.
ar_write_utf8(paste0("- ", summary_hr), file.path(AR_TABLES, "summary_hr.md"))
ar_write_utf8(paste0("- ", summary_en), file.path(AR_TABLES, "summary_en.md"))

## === Table fragments =============================================================================
plat_tab <- platform |> filter(total_posts > 0) |> arrange(desc(total_posts))
metric_or_dash <- function(value, coverage) {
  ifelse(coverage < 0.05, "nije zabilježeno", ar_fmt_int_hr(value))
}
ar_fragment(
  file.path(AR_TABLES, "table_platform.md"),
  "Gdje su objave nastale?",
  ar_md_table(data.frame(
    Platforma = plat_tab$platform_hr,
    Objava = ar_fmt_int_hr(plat_tab$total_posts),
    Udio = ar_fmt_pct_hr(100 * plat_tab$post_share),
    Interakcija = metric_or_dash(plat_tab$total_interactions, plat_tab$interaction_coverage),
    Doseg = metric_or_dash(plat_tab$total_reach, plat_tab$reach_coverage),
    check.names = FALSE
  ), align = c(":---", "---:", "---:", "---:", "---:")),
  paste("Izvor: DigiKat, službeni korpus.",
        "„Nije zabilježeno” znači da mjerenje na toj platformi ne postoji u prikupljenim podacima,",
        "a ne da interakcija ili dosega nije bilo. Objava, interakcija i doseg tri su različita pitanja i ne zbrajaju se.")
)

league_top <- head(league, 12L)
ar_fragment(
  file.path(AR_TABLES, "table_league.md"),
  "Koji izvori najviše objavljuju?",
  ar_md_table(data.frame(
    `#` = league_top$rank,
    Izvor = league_top$name_hr,
    Objava = ar_fmt_int_hr(league_top$posts),
    `Udio godine` = ar_fmt_pct_hr(league_top$share_of_year, 2),
    Oznaka = ifelse(league_top$label == "confessional", "konfesionalni", "sekularni"),
    check.names = FALSE
  ), align = c("---:", ":---", "---:", "---:", ":---")),
  paste("Izvor: DigiKat, službeni korpus.",
        "Imenuju se institucijski mediji s najmanje pet objava u godini, a pojedinačni računi nikada.",
        "Redoslijed mjeri količinu, a ne kvalitetu ni utjecaj.")
)

themes_tab <- themes |> arrange(rank)
ar_fragment(
  file.path(AR_TABLES, "table_themes.md"),
  "O čemu se govorilo?",
  ar_md_table(data.frame(
    Tema = themes_tab$topic_hr,
    Spominjanja = ar_fmt_int_hr(themes_tab$mentions),
    `Udio spominjanja` = ar_fmt_pct_hr(100 * themes_tab$share_of_mentions),
    `Vodeća tema objave` = ar_fmt_pct_hr(100 * themes_tab$share_of_docs),
    check.names = FALSE
  ), align = c(":---", "---:", "---:", "---:")),
  paste("Izvor: DigiKat, tematski uzorak korpusa za", paste0(YEAR, "."),
        "Dva stupca odgovaraju na dva pitanja. „Udio spominjanja” dijeli sva rječnička pogotka među kategorijama,",
        "pa jedna objava može pridonijeti većem broju tema. „Vodeća tema objave” svakoj objavi pripisuje jednu,",
        "najjaču kategoriju, pa se taj stupac zbraja na sto posto zajedno s objavama bez ijednog pogotka",
        paste0("(", ar_fmt_pct_hr(100 * themes_cov$share_without_theme), ")."))
)

tone_tab <- tone_theme |> filter(reportable) |> arrange(desc(sentiment_mean))
ar_fragment(
  file.path(AR_TABLES, "table_tone.md"),
  "Kojim se tonom govori o vodećim temama?",
  ar_md_table(data.frame(
    Tema = tone_tab$topic_hr,
    Objava = ar_fmt_int_hr(tone_tab$n_docs),
    `Tonski rezultat` = ar_fmt_num_hr(tone_tab$sentiment_mean, 2),
    `Riječi sukoba` = ar_fmt_num_hr(tone_tab$cli_mean, 0),
    check.names = FALSE
  ), align = c(":---", "---:", "---:", "---:")),
  paste("Izvor: DigiKat, tonski uzorak korpusa za", paste0(YEAR, "."),
        "Tonski rezultat ide od −1 do +1 i mjeri rječnik, a ne stav autora ni istinitost tvrdnje.",
        "„Riječi sukoba” broje pojmove sukoba, ljutnje i straha na tisuću riječi.",
        "Prikazane su samo teme s najmanje trideset objava u uzorku.")
)

arc_tab <- arcs |> arrange(desc(peak_posts))
arc_tab$name <- ar_event_name(arc_tab$peak_day)
ar_fragment(
  file.path(AR_TABLES, "table_events.md"),
  "Koji su dani odudarali od godišnjeg ritma?",
  ar_md_table(data.frame(
    Datum = ar_date_short_hr(arc_tab$peak_day),
    Događaj = arc_tab$name,
    Objava = ar_fmt_int_hr(arc_tab$peak_posts),
    `Odstupanje` = paste0(ar_fmt_num_hr(arc_tab$peak_z, 1), " sd"),
    `Dana u luku` = ar_fmt_int_hr(arc_tab$days),
    check.names = FALSE
  ), align = c(":---", ":---", "---:", "---:", "---:")),
  paste("Izvor: DigiKat, službeni korpus, svi dani u godini.",
        "Odstupanje je udaljenost od prosječnog dana u godini, izražena u standardnim devijacijama;",
        "prag od tri postavljen je prije pregleda podataka. Nazivi dolaze iz javnog kalendara i potvrđeni su",
        "tematskim sastavom tih dana, jer vrh sam po sebi pokazuje datum, a ne uzrok.")
)

# The two period columns are named by the data, not by the calendar: the same table serves an edition
# comparing two half-years and one comparing two quarters inside a single year.
stream_tab <- stream |> filter(report_value >= stream_floor | base_value >= stream_floor) |>
  arrange(desc(report_value))
ar_fragment(
  file.path(AR_TABLES, "table_stream.md"),
  ed(`2024` = "Što je kroz godinu raslo, a što padalo?",
     `2025` = "Što je raslo, a što padalo?"),
  ar_md_table(
    setNames(
      data.frame(
        stream_tab$platform_hr,
        stream_fmt(stream_tab$base_value),
        stream_fmt(stream_tab$report_value),
        ar_fmt_change_hr(stream_tab$change_pct),
        ar_fmt_change_hr(stream_tab$sources_change_pct),
        stringsAsFactors = FALSE
      ),
      c("Platforma", stream$base_label[1], stream$report_label[1], "Objave", "Izvori")
    ),
    align = c(":---", "---:", "---:", "---:", "---:")),
  ed(`2024` = paste("Izvor: DigiKat, službeni korpus, tok prikupljanja koji teče od srpnja 2024.",
                    "Vrijednosti su objave po danu s prikupljanjem, pa rujanski prekid ne ulazi u usporedbu.",
                    "Ovo je kretanje unutar godine, a ne usporedba s prethodnom godinom, i u četvrtom",
                    "tromjesečju stoje advent i Božić. Zadnji stupac pokazuje mijenja li se broj praćenih",
                    "izvora. Kad volumen i broj izvora rastu zajedno, vjerojatnije je da se proširilo",
                    "praćenje nego sama rasprava."),
     `2025` = paste("Izvor: DigiKat, službeni korpus, tok prikupljanja koji teče od srpnja 2024.",
                    "Zadnji stupac pokazuje mijenja li se broj praćenih izvora. Kad volumen i broj izvora rastu zajedno,",
                    "vjerojatnije je da se proširilo praćenje nego sama rasprava."))
)

typ_tab <- typology
ar_fragment(
  file.path(AR_TABLES, "table_typology.md"),
  "Kako su akteri raspoređeni po interakcijama i dosegu?",
  ar_md_table(data.frame(
    Skupina = typ_tab$quadrant_hr,
    Aktera = ar_fmt_int_hr(typ_tab$actors),
    Udio = ar_fmt_pct_hr(100 * typ_tab$share),
    check.names = FALSE
  ), align = c(":---", "---:", "---:")),
  paste("Izvor: DigiKat, službeni korpus. Skupine nastaju podjelom po medijanu interakcija i medijanu dosega",
        "unutar svake platforme, i to samo za platforme koje te dvije mjere doista bilježe.",
        "Aktera mora imati barem dvanaest objava u godini. Skupine su opisne, ne ocjene.")
)

# The rotating chapter's row labels belong to the study, not to the annual measures, so they are
# keyed by that study's own scalar names. The values arrive already formatted for humans, so they go
# through ar_parse_value() before anything is rounded.
special_label <- c(
  linked_posts = "Objave u kojima se religijski i gospodarski govor susreću (sirovi nalaz detektora)",
  core_posts = "Objave s izrazom socijalnoga nauka uz gospodarski pojam",
  corrected_headline = "Ispravljena procjena udjela doktrinarnih parova (%)",
  conf_share_doctrinal_labelled = "Udio konfesionalnih izvora među razvrstanim doktrinarnim objavama (%)",
  n_linked = "Objave u kojima se religijski govor i troškovi života susreću (sirovi nalaz detektora)",
  n_core = "Objave koje je ručna provjera potvrdila kao domaću raspravu o troškovima života",
  peak_n_repricing = "Objava o promjeni cijena crkvenih usluga u 2024., najviše u cijelom razdoblju",
  v2_hicp_repricing_lag_months = "Mjeseci između vrhunca inflacije i vrhunca izvještavanja o cijenama"
)
special_keys <- special[[special_spec$name_column]]
special_numeric <- ar_parse_value(special$value)
special_display <- ifelse(grepl("headline|share", special_keys),
                          ar_fmt_num_hr(special_numeric, 2), ar_fmt_int_hr(special_numeric))
missing_label <- special_keys[!special_keys %in% names(special_label)]
if (length(missing_label)) stop("No Croatian label for special-chapter scalar: ",
                                paste(missing_label, collapse = ", "), call. = FALSE)
ar_fragment(
  file.path(AR_TABLES, "table_special.md"),
  ed(`2024` = "Što je pokazala studija o inflaciji i crkvenom govoru?",
     `2025` = "Što je pokazala studija o socijalnom nauku i gospodarstvu?"),
  ar_md_table(data.frame(Mjera = unname(special_label[special_keys]), Vrijednost = special_display,
                         check.names = FALSE),
              align = c(":---", "---:")),
  ed(`2024` = paste("Izvor: generirani rezultati studije `inflation-salience`.",
                    "Vrijednosti pokrivaju cijelo razdoblje te studije (2021.–2026.), a ne izvještajnu",
                    "godinu, i ne ulaze u godišnje pokazatelje. Studija je računana na akumulatoru, a ne",
                    "na službenom korpusu, pa se njezini nazivnici ne poklapaju s ostatkom izvještaja.",
                    "Prvi red je ono što je detektor pronašao; drugi je ono što je ručna provjera potvrdila."),
     `2025` = paste("Izvor: generirani rezultati studije `moral-economy`. Vrijednosti pokrivaju cijelo razdoblje te studije,",
                    "a ne izvještajnu godinu, i ne ulaze u godišnje pokazatelje.",
                    "Prva dva reda su ono što je detektor pronašao; ispravljena procjena dijeli taj nalaz preciznošću",
                    "koju je pokazala ručna provjera uzorka."))
)

indicator_status <- data.frame(
  id = c("AR01", "AR02", "AR03", "AR04", "AR05", "AR06", "AR07", "AR08", "AR09", "AR10"),
  name_hr = c("Volumen zabilježene rasprave", "Indikativni sastav izvora", "Vodeći institucionalni akteri",
              "Raspored aktera po interakcijama i dosegu", "Referentne vrijednosti angažmana",
              "Tematski profil", "Ton i sukob", "Dani koji odudaraju",
              "Prijenos crkvenoga glasa", "Anketa publike"),
  status = c("objavljeno", "indikativno", "objavljeno", "objavljeno bez kretanja", "objavljeno",
             "objavljeno", "objavljeno", "objavljeno", "u pripremi", "u pripremi"),
  note = c(ed(`2024` = "godišnji presjek i kretanje unutar istoga toka prikupljanja, unutar godine",
              `2025` = "godišnji presjek i usporedba unutar istoga toka prikupljanja"),
           "oznake izvora imaju status prijedloga; pokriveno je nešto više od trećine volumena",
           "imenuju se samo odobreni institucijski mediji",
           "raspored za izvještajnu godinu; kretanje čeka zamrznuto referentno pravilo",
           "medijan interakcija po objavi, samo za platforme koje mjeru bilježe",
           "svih šesnaest kategorija pod jednim nazivnikom, iz tematskog uzorka",
           "godišnja mjera tona i sukoba s intervalima pouzdanosti",
           sprintf("svih %d dana, prag postavljen unaprijed", AR_CALENDAR_DAYS),
           "traži zaseban dizajn mjerenja i kontrolne skupine",
           "traži instrument, uzorak i etičko odobrenje"),
  stringsAsFactors = FALSE
)
ar_write_csv(indicator_status, file.path(AR_OUT, "indicator_status.csv"))
ar_fragment(
  file.path(AR_TABLES, "table_indicators.md"),
  "Što ovaj pregled već mjeri, a što dolazi?",
  ar_md_table(data.frame(
    Oznaka = indicator_status$id,
    Pokazatelj = indicator_status$name_hr,
    Status = indicator_status$status,
    check.names = FALSE
  ), align = c(":---", ":---", ":---")),
  "Puna definicija svakog pokazatelja, pravilo usporedivosti i povijest promjena nalaze se u dokumentu `INDICATORS.md`."
)

## === Press release — three numbers ===============================================================
# A derivative built from the same registry, so it cannot drift from the report.
ar_write_utf8(c(
  sprintf("# DigiKat: godišnji pregled %d.", YEAR), "",
  ed(`2024` = paste("**Zagreb — za objavu.** Hrvatsko katoličko sveučilište objavljuje godišnji pregled",
                    "katoličkih tema u hrvatskom digitalnom prostoru za 2024. godinu."),
     `2025` = paste("**Zagreb — za objavu.** Hrvatsko katoličko sveučilište objavljuje prvi godišnji pregled",
                    "katoličkih tema u hrvatskom digitalnom prostoru.")), "",
  paste0("**", ar_count_hr(total_posts, "objava"), "** o katoličkim temama zabilježeno je u ", YEAR,
         ". godini, iz ", val("distinct_sources"), " različitih izvora."),
  "",
  paste0("**", val("web_share"), " tog volumena nastalo je na webu**, a ne na društvenim mrežama; ",
         "Facebook nosi ", val("facebook_share"), ", YouTube ", val("youtube_share"), "."),
  "",
  ed(`2024` = paste0("**Najjači dan godine bio je Božić, ", val("peak_day"), "**, s ", val("peak_posts"),
                     " objava. Drugi vrhunac godine je Velika Gospa, pa su oba blagdani i nijedan ",
                     "vrhunac nije nastao iz spora. Uskrs 2024. pada unutar prekida u prikupljanju, pa ga ",
                     "u podacima nema."),
     `2025` = paste0("**Najjači dan godine bio je ", val("peak_day"), "**, dan smrti pape Franje, s ",
                     val("peak_posts"), " objava. Preostala tri vrhunca godine su sprovod, Velika Gospa i Božić, ",
                     "i nijedan nije nastao iz spora.")),
  "",
  "Izvještaj je dostupan u HTML i PDF obliku. Sve brojke izračunane su iz baze i mogu se ponoviti.",
  "",
  paste0("Kontakt: doc. dr. sc. Luka Šikić · luka.sikic@unicath.hr"), "",
  paste0("*Metodološka napomena. Brojke opisuju zabilježeni digitalni prostor, a ne cjelinu interneta. ",
         "U ", YEAR, ". godini prikupljanje je stajalo ", val("gap_days"), " dana (", val("gap_span"),
         "), što je u pregledu označeno i isključeno iz svih prosjeka.*")
), file.path(AR_OUT, "press_release.md"))

## === Private annex: institutional mirror profiles =================================================
private_dir <- file.path(AR_PRIVATE, "profiles")
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)
panel <- ar_read_csv(file.path(AR_PRIVATE, "actor_panel_private.csv"))
panel <- panel |> filter(kind %in% "institution", publish %in% "yes") |> arrange(desc(posts))
# A sample of profiles, not a ranking: the six largest outlets all sit in the same quadrant, which
# would show the reader one shape of actor and imply the others do not exist. Take the leader of each
# quadrant first, then fill up with the leader of each platform still unrepresented.
pick <- panel |> group_by(quadrant) |> slice_max(posts, n = 1, with_ties = FALSE) |> ungroup()
for (plat in c("web", "facebook", "youtube")) {
  if (!plat %in% pick$SOURCE_TYPE) {
    add <- panel |> filter(SOURCE_TYPE == plat, !source_key %in% pick$source_key) |>
      slice_max(posts, n = 1, with_ties = FALSE)
    pick <- bind_rows(pick, add)
  }
}
profiles <- pick |> arrange(desc(posts)) |> as.data.frame()
league_name <- league$name_hr[match(profiles$source_key, league$source_key)]
profiles$name_hr <- ifelse(is.na(league_name), profiles$source_key, league_name)
bench_key <- paste(benchmarks$SOURCE_TYPE, benchmarks$quadrant, sep = "\r")
profiles$benchmark <- benchmarks$median_interactions_per_post[
  match(paste(profiles$SOURCE_TYPE, profiles$quadrant, sep = "\r"), bench_key)]
profiles$ratio <- profiles$interactions_per_post / profiles$benchmark
lines <- character()
for (i in seq_len(nrow(profiles))) {
  lines <- c(lines,
    paste0("### ", profiles$name_hr[i]), "",
    paste0("**", unname(ar_platform_hr[profiles$SOURCE_TYPE[i]]), " · ",
           unname(ar_typology_hr[profiles$quadrant[i]]), "**"), "",
    paste0("- Objava u ", YEAR, ".: **", ar_fmt_int_hr(profiles$posts[i]), "**"),
    paste0("- Interakcija: **", ar_fmt_int_hr(profiles$interactions[i]), "**"),
    paste0("- Interakcija po objavi: **", ar_fmt_num_hr(profiles$interactions_per_post[i], 1),
           "**, odnosno ", ar_fmt_num_hr(profiles$ratio[i], 2),
           " medijana svoje skupine na istoj platformi"), "")
}
ar_write_utf8(lines, file.path(private_dir, "profiles.md"))
ar_write_csv(profiles, file.path(AR_PRIVATE, "profiles.csv"))

## === Manifest ======================================================================================
generated <- c(list.files(AR_OUT, pattern = "[.]csv$", full.names = TRUE),
               list.files(AR_OUT, pattern = "[.]md$", full.names = TRUE),
               list.files(AR_TABLES, pattern = "[.]md$", full.names = TRUE),
               list.files(AR_FIGURES, pattern = "[.]png$", full.names = TRUE))
generated <- generated[!grepl("/private/|\\\\private\\\\", generated)]
inventory <- as.data.frame(lapply(ar_file_inventory(generated), unname), stringsAsFactors = FALSE)
root_norm <- paste0(normalizePath(AR_DIR, winslash = "/", mustWork = TRUE), "/")
file_norm <- gsub("\\\\", "/", inventory$file)
if (!all(startsWith(file_norm, root_norm))) stop("Inventory contains a file outside the study.")
inventory$file <- substring(file_norm, nchar(root_norm) + 1L)

generator_files <- c("00_data_readiness.R", "01_report_aggregates.R", "02_nlp_layers.R",
                     "03_report_assets.R", "04_sync_fragments.R", "05_report_checks.R",
                     "06_render_report.R", "report_lib.R", basename(ar_template_path()))
generator_files <- generator_files[file.exists(file.path(AR_DIR, generator_files))]
manifest <- list(
  schema_version = 2L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/annual-report/03_report_assets.R",
  reporting_year = YEAR,
  indicator_version = "edition-1.0",
  dataset = readiness$dataset,
  accumulator_opened = FALSE,
  generator_sha256 = as.list(setNames(
    vapply(generator_files, function(x) ar_sha256(file.path(AR_DIR, x)), character(1)),
    generator_files)),
  upstream_sha256 = list(
    corpus_manifest = ar_sha256(here::here("data", "digikat_corpus_manifest.json")),
    processed_manifest = ar_sha256(here::here("data", "processed", "manifest.json")),
    nlp_manifest = ar_sha256(here::here("data", "nlp", "manifest.json")),
    source_labels = ar_sha256(here::here("resources", "dictionaries", "source_labels.csv")),
    thematic_dictionaries = ar_sha256(here::here("R", "lib", "thematic_dictionaries.R")),
    moral_economy_derived = ar_sha256(here::here("studies", "moral-economy", "output", "tables", "rsp_derived.csv"))
  ),
  outputs = inventory
)
write_json(manifest, file.path(AR_OUT, "manifest.json"), pretty = TRUE, auto_unbox = TRUE, na = "null")

cat("Assets generated:", nrow(inventory), "tracked-safe files;", nrow(derived), "scalars;",
    length(list.files(AR_FIGURES, pattern = "[.]png$")), "figures.\n")
