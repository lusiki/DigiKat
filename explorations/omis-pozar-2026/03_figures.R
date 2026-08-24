# 03_figures.R — the visual layer. Reads output/items.rds + output/agg/*, writes output/figures/*.png
#
#   Rscript 03_figures.R
#
# Design rules (kept deliberately few):
#   * one warm-paper theme, one palette per encoding (outlet type / platform / frame), never mixed
#   * every title states a number that comes from derived.json — nothing typed
#   * story hour on the x axis everywhere, with clock labels; hour 0 = the fire report
#   * synthetic runs are stamped on every figure

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")
suppressPackageStartupMessages({ library(ggplot2); library(patchwork); library(scales); library(ggrepel) })

items <- readRDS(file.path(OUT_DIR, "items.rds"))
D <- read_json(file.path(AGG_DIR, "derived.json"), simplifyVector = TRUE)
SYNTH <- isTRUE(D$synthetic)
om <- items[about_omis == TRUE]
fcols <- paste0("f_", names(FRAMES))
rd <- function(name) fread(file.path(AGG_DIR, paste0(name, ".csv")), encoding = "UTF-8")

# ---------------------------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------------------------
DPI <- 200
F_SANS <- "sans"; F_SERIF <- "serif"; F_MONO <- "mono"
if (requireNamespace("showtext", quietly = TRUE) && requireNamespace("sysfonts", quietly = TRUE)) {
  ok <- tryCatch({
    sysfonts::font_add_google("Source Serif 4", "of_serif")
    sysfonts::font_add_google("Source Sans 3", "of_sans")
    sysfonts::font_add_google("IBM Plex Mono", "of_mono")
    TRUE }, error = function(e) FALSE)
  if (ok) { F_SANS <- "of_sans"; F_SERIF <- "of_serif"; F_MONO <- "of_mono" }
  showtext::showtext_auto(); showtext::showtext_opts(dpi = DPI)
}
C <- list(paper = "#FBF6EE", panel = "#FFFFFF", ink = "#1F1A17", body = "#3A332E", muted = "#6B625B", faint = "#9A9086",
          grid = "#EADFD0", night = "#F1EAE0", ember = "#E4572E", amber = "#F5A623", deep = "#8B1A1A", water = "#2E6FB7")
PAL_TYPE <- c(sluzbeni = "#2E6FB7", lokalni = "#E4572E", nacionalni = "#8B1A1A", ostali_web = "#B39C86", strani = "#6C5B7B", drustveni = "#F5A623")
LAB_TYPE <- c(sluzbeni = "Službeni izvori", lokalni = "Lokalni (Dalmacija)", nacionalni = "Nacionalni mediji", ostali_web = "Ostali web", strani = "Strani mediji", drustveni = "Društvene mreže")
PAL_PLAT <- c(web = "#8B1A1A", facebook = "#3C63A8", twitter = "#4FA3D9", youtube = "#C4302B", instagram = "#C13584", tiktok = "#222222", forum = "#7A9E7E", reddit = "#FF5700", comment = "#B0A090")
LAB_FRAME <- sapply(FRAMES, `[[`, "hr")
type_levels <- c("lokalni", "drustveni", "nacionalni", "sluzbeni", "ostali_web", "strani")

theme_fire <- function(base = 13) {
  theme_minimal(base_size = base, base_family = F_SANS) +
    theme(plot.background = element_rect(fill = C$paper, colour = NA), panel.background = element_rect(fill = C$panel, colour = NA),
          panel.grid.major = element_line(colour = C$grid, linewidth = 0.4), panel.grid.minor = element_blank(),
          axis.text = element_text(family = F_MONO, size = base * 0.75, colour = C$muted), axis.title = element_text(size = base * 0.9, colour = C$body),
          plot.title = element_text(family = F_SERIF, face = "bold", size = base * 1.55, colour = C$ink, margin = margin(b = 4)),
          plot.subtitle = element_text(size = base * 1.0, colour = C$muted, margin = margin(b = 10), lineheight = 1.05),
          plot.caption = element_text(family = F_MONO, size = base * 0.68, colour = C$faint, hjust = 0, margin = margin(t = 10), lineheight = 1.1),
          legend.position = "top", legend.justification = "left", legend.title = element_blank(), legend.text = element_text(size = base * 0.85, colour = C$body),
          legend.key.size = unit(0.9, "lines"), strip.text = element_text(family = F_SERIF, face = "bold", size = base * 0.95, colour = C$ink, hjust = 0),
          plot.title.position = "plot", plot.caption.position = "plot", plot.margin = margin(16, 20, 12, 16))
}
theme_set(theme_fire())
cat_y <- function(size = 10) theme(axis.text.y = element_text(family = F_SANS, size = size, colour = C$body))
wrap_lines <- function(s, width = 150) paste(vapply(strsplit(s, "\n", fixed = TRUE)[[1]], function(l) paste(stri_wrap(l, width, simplify = TRUE), collapse = "\n"), character(1)), collapse = "\n")
CAP <- paste0("Izvor: izvoz servisa za praćenje medija (Determ) · sat 0 = dojava o požaru, ", format(T0, "%d.%m.%Y. %H:%M", tz = TZ),
              " · vrijeme Europe/Zagreb · analiza: L. Šikić", if (SYNTH) paste0("\n", SYNTH_TAG_HR) else "")
stamp <- function(p, polar = FALSE, bottom = FALSE) if (SYNTH && !polar) p + annotate("label", x = Inf, y = if (bottom) -Inf else Inf, label = SYNTH_TAG_HR, hjust = 1.02, vjust = if (bottom) -0.4 else 1.3,
                                                          size = 3.4, family = F_MONO, fill = "#FFE9A8", colour = C$deep, label.size = NA) else p
save_fig <- function(p, name, w = 11, h = 6.8) {
  f <- file.path(FIG_DIR, paste0(name, ".png"))
  ggsave(f, p, width = w, height = h, dpi = DPI, device = ragg::agg_png, bg = C$paper)
  cat("  wrote", basename(f), "\n")
}
# story-hour axis with clock labels every 12 h, day bands and night bands
H_MAX <- ceiling(max(om$h)); H_MIN <- floor(min(0, min(om$h)))
clock_lab <- function(h) format(T0 + h * 3600, "%H:%M", tz = TZ)
brk12 <- seq(ceiling(H_MIN / 12) * 12, H_MAX, by = 12)
scale_x_story <- function(...) scale_x_continuous(breaks = brk12, labels = function(h) paste0(h, " h\n", clock_lab(h)), expand = expansion(mult = c(0.01, 0.02)), ...)
midnights <- local({
  d0 <- as.Date(format(T0, tz = TZ)); out <- data.table(day = d0 + 0:8)
  out[, h := hours_since(as.POSIXct(paste(day, "00:00:00"), tz = TZ))]
  out <- out[h > H_MIN & h < H_MAX]
  out[, lab := format(as.POSIXct(paste(day, "12:00:00"), tz = TZ), "%a %d.%m.", tz = TZ)]
  out
})
nights <- local({
  d0 <- as.Date(format(T0, tz = TZ)) - 1; out <- list()
  for (k in 0:8) { s <- as.POSIXct(paste(d0 + k, "22:00:00"), tz = TZ); e <- s + 8 * 3600; out[[k + 1]] <- data.table(xmin = hours_since(s), xmax = hours_since(e)) }
  rbindlist(out)[xmax > H_MIN & xmin < H_MAX]
})
night_layer <- function() geom_rect(data = nights, aes(xmin = pmax(xmin, H_MIN), xmax = pmin(xmax, H_MAX), ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = C$night, alpha = 0.7)
day_layer <- function(y = Inf, vjust = 1.5, size = 2.8) list(
  geom_vline(data = midnights, aes(xintercept = h), colour = C$faint, linewidth = 0.3),
  geom_text(data = midnights, aes(x = h, y = y, label = lab), inherit.aes = FALSE, hjust = -0.08, vjust = vjust, size = size, family = F_MONO, colour = C$muted))
ev <- copy(FIRE_EVENTS)[, h := hours_since(t)][h >= H_MIN & h <= H_MAX][order(h)]
ev[, k := seq_len(.N)]

# ---------------------------------------------------------------------------------------------
# F1 — Dva požara: what the media produced (up) and what the public rewarded (down), hour by hour
# ---------------------------------------------------------------------------------------------
hourly <- rd("hourly")[, .(n = sum(n)), by = .(hb, outlet_type)]
tot <- rd("hourly_total")
ymax <- max(tot$n); imax <- max(1, max(tot$interactions))
sc <- ymax / imax                                              # interactions drawn on the volume scale
tot[, inter_scaled := -interactions * sc]
hourly[, outlet_type := factor(outlet_type, levels = type_levels)]
b_up <- pretty(c(0, ymax)); b_up <- b_up[b_up > 0]; b_dn <- pretty(c(0, imax), n = 4); b_dn <- b_dn[b_dn > 0]
ev[, yk := ymax * (1.10 + 0.13 * ((k - 1) %% 2))]              # alternate two rows so neighbours do not collide
p1 <- ggplot() + night_layer() +
  geom_col(data = hourly, aes(hb + 0.5, n, fill = outlet_type), width = 1, colour = NA) +
  geom_col(data = tot, aes(hb + 0.5, inter_scaled), width = 1, fill = C$amber, alpha = 0.85) +
  geom_hline(yintercept = 0, colour = C$ink, linewidth = 0.4) +
  geom_segment(data = ev, aes(x = h, xend = h, y = 0, yend = yk), colour = C$ink, linewidth = 0.3, linetype = "22", alpha = 0.7) +
  geom_point(data = ev, aes(h, yk), shape = 21, size = 5.2, fill = C$paper, colour = C$ink, stroke = 0.6) +
  geom_text(data = ev, aes(h, yk, label = k), size = 2.7, family = F_MONO, colour = C$ink) +
  geom_text(data = midnights, aes(x = h, y = -imax * sc, label = lab), hjust = -0.08, vjust = -0.3, size = 2.8, family = F_MONO, colour = C$muted) +
  geom_vline(data = midnights, aes(xintercept = h), colour = C$faint, linewidth = 0.3) +
  scale_fill_manual(values = PAL_TYPE, labels = LAB_TYPE, breaks = type_levels) +
  scale_x_story() +
  scale_y_continuous(breaks = c(-rev(b_dn) * sc, 0, b_up), labels = c(fmt_hr(rev(b_dn)), "0", fmt_hr(b_up)), expand = expansion(mult = c(0.03, 0.06))) +
  labs(x = NULL, y = "objave po satu ↑   ·   interakcije po satu ↓") +
  theme(legend.position = "top")
key <- ggplot(ev, aes(x = 0, y = rev(k))) +
  geom_point(shape = 21, size = 5.2, fill = C$paper, colour = C$ink, stroke = 0.6) + geom_text(aes(label = k), size = 2.7, family = F_MONO) +
  geom_text(aes(x = 0.06, label = paste0(format(t, "%a %H:%M", tz = TZ), "  ", vapply(stri_wrap(label_hr, 30, simplify = FALSE), paste, character(1), collapse = "\n"))),
            hjust = 0, size = 2.75, family = F_SANS, colour = C$body, lineheight = 0.9) +
  scale_x_continuous(limits = c(-0.03, 1), expand = c(0, 0)) + scale_y_continuous(expand = expansion(add = 0.8)) +
  labs(subtitle = "Događaji požara") + theme_void(base_family = F_SANS) +
  theme(plot.background = element_rect(fill = C$paper, colour = NA), plot.subtitle = element_text(size = 11, colour = C$muted, family = F_SERIF, face = "bold", margin = margin(b = 6)),
        plot.margin = margin(52, 6, 40, 0))
p1c <- (stamp(p1) + key + plot_layout(widths = c(4.2, 1.15))) +
  plot_annotation(title = sprintf("Dva požara: %s objava u %s sati", fmt_hr(D$n_items), fmt_hr(D$span_hours)),
                  subtitle = wrap_lines(sprintf("Iznad crte: koliko su mediji objavljivali svaki sat, po vrsti izvora. Ispod crte (žuto): koliko je interakcija skupio sadržaj objavljen u tom satu.\nVrhunac objavljivanja: %s objava u satu %s (%s). Sive trake su noći, brojevi su događaji požara (popis desno).", fmt_hr(D$peak_n), D$peak_hour, D$peak_clock), 175),
                  caption = CAP, theme = theme_fire())
save_fig(p1c, "01_dva_pozara", 13.5, 7.8)

# ---------------------------------------------------------------------------------------------
# F2 — Štafeta: who entered when, who stayed how long, who published how much
# ---------------------------------------------------------------------------------------------
cas <- rd("cascade")
show <- rbind(cas[order(first_h)][1:min(16, .N)], cas[order(-n)][1:min(34, .N)])[!duplicated(FROM)][order(first_h)]
show[, FROM_f := factor(FROM, levels = rev(FROM))]
show[, outlet_type := factor(outlet_type, levels = type_levels)]
p2 <- ggplot(show) + night_layer() +
  geom_segment(aes(x = first_h, xend = last_h, y = FROM_f, yend = FROM_f, colour = outlet_type), linewidth = 0.9, alpha = 0.55) +
  geom_point(aes(median_h, FROM_f, colour = outlet_type), shape = 124, size = 3) +
  geom_point(aes(first_h, FROM_f, size = n, fill = outlet_type), shape = 21, colour = C$paper, stroke = 0.6) +
  geom_vline(xintercept = D$peak_hour, colour = C$ember, linetype = "22", linewidth = 0.4) +
  annotate("text", x = D$peak_hour, y = Inf, label = "vrhunac objavljivanja", vjust = 1.6, hjust = -0.05, size = 3, colour = C$ember, family = F_MONO) +
  day_layer(y = -Inf, vjust = -0.5) +
  scale_y_discrete(expand = expansion(add = c(1.4, 0.8))) +
  scale_colour_manual(values = PAL_TYPE, guide = "none") + scale_fill_manual(values = PAL_TYPE, labels = LAB_TYPE, breaks = type_levels) +
  scale_size_area(max_size = 11, name = "objava", breaks = function(l) pretty(l, 3)) +
  scale_x_story(limits = c(H_MIN, H_MAX)) +
  guides(fill = guide_legend(order = 1, override.aes = list(size = 4)), size = guide_legend(order = 2, override.aes = list(shape = 21, fill = C$muted, colour = C$paper))) +
  labs(title = sprintf("Štafeta: %s izvora ušlo je u priču, %s njih unutar prvih 6 sati", fmt_hr(nrow(cas)), fmt_hr(D$sources_entered_by_6h)),
       subtitle = wrap_lines(sprintf("Svaki redak je jedan izvor, poredan po trenutku prve objave (prikazano %d od %d: prvih 16 i najveći po broju objava). Krug = prva objava, veličina = ukupan broj objava; crta = koliko dugo je izvor ostao na priči; crtica = medijan.\nPrvi lokalni izvor u satu %s, prvi nacionalni u satu %s, prvi službeni u satu %s, prvi strani u satu %s.",
                         nrow(show), nrow(cas), fmt_hr(D$first_h_lokalni, 1), fmt_hr(D$first_h_nacionalni, 1), fmt_hr(D$first_h_sluzbeni, 1), fmt_hr(D$first_h_strani, 1)), 165),
       x = NULL, y = NULL, caption = CAP) +
  theme(axis.text.y = element_text(family = F_MONO, size = 7.2, colour = C$body), panel.grid.major.y = element_blank(), legend.box = "horizontal")
save_fig(stamp(p2), "02_stafeta", 13, 10)

# ---------------------------------------------------------------------------------------------
# F3 — Spektrogram priče: which frames carried the story, 3-hour bins
# ---------------------------------------------------------------------------------------------
fh <- rd("frames_hourly")
ons <- rd("frames_onset")[order(onset_h, -peak_share)]
fh[, frame := factor(frame, levels = rev(ons$frame))]
fh[n_items < 4, share := NA]
p3 <- ggplot(fh, aes(hb3 + 1.5, frame, fill = share)) +
  geom_tile(width = 3, height = 0.92, colour = C$paper, linewidth = 0.4) +
  geom_vline(data = ev, aes(xintercept = h), colour = C$ink, linewidth = 0.25, linetype = "22", alpha = 0.6) +
  geom_text(data = ev, aes(x = h, y = length(FRAMES) + 0.75, label = k), inherit.aes = FALSE, size = 2.6, family = F_MONO, colour = C$body) +
  day_layer(y = 0.35, vjust = 0.5, size = 2.6) +
  scale_fill_gradientn(colours = c("#FFF7E6", "#F5A623", "#E4572E", "#8B1A1A"), na.value = "#F3EEE6", limits = c(0, 100), name = "% objava u kojima se okvir pojavljuje",
                       guide = guide_colourbar(barwidth = 12, barheight = 0.5, title.position = "top")) +
  scale_y_discrete(labels = LAB_FRAME, expand = expansion(add = c(0.7, 1.0))) + scale_x_story() +
  labs(title = "Spektrogram priče: o čemu se pisalo, sat za satom",
       subtitle = wrap_lines(sprintf("Udio objava (u pojasevima od 3 sata) koje nose pojedini tematski okvir. Okviri su poredani odozgo prema trenutku kada su prvi put nosili barem četvrtinu objava.\nPolitika ulazi u satu %s, uzrok i istraga u satu %s, solidarnost u satu %s. Isprekidane crte s brojevima su događaji požara kao na prvoj slici.",
                         fmt_hr(D$frame_politika_onset_h), fmt_hr(D$frame_uzrok_onset_h), fmt_hr(D$frame_solidarnost_onset_h)), 165),
       x = NULL, y = NULL, caption = wrap_lines(paste0(CAP, "\nOkvir = pogodak rječnika u naslovu i prvih 3 000 znakova; jedna objava može nositi više okvira, pa se stupci ne zbrajaju na 100 %."), 170)) +
  theme(legend.position = "top", legend.title = element_text(size = 9, colour = C$muted), panel.grid = element_blank()) + cat_y(10)
save_fig(stamp(p3), "03_spektrogram", 12.5, 6.8)

# ---------------------------------------------------------------------------------------------
# F4 — Objavljeno i nagrađeno: outlet types by share of items vs share of interactions
# ---------------------------------------------------------------------------------------------
pr <- rd("produced_rewarded_type")[order(share_items)]
pr[, outlet_type := factor(outlet_type, levels = outlet_type)]
prl <- melt(pr, id.vars = c("outlet_type", "gap_pp", "ipi", "zero_share"), measure.vars = c("share_items", "share_interactions"), variable.name = "what", value.name = "share")
xr <- max(prl$share)
p4 <- ggplot(pr) +
  geom_segment(aes(x = share_items, xend = share_interactions, y = outlet_type, yend = outlet_type), colour = C$grid, linewidth = 3) +
  geom_point(data = prl, aes(share, outlet_type, colour = what), size = 4.2) +
  geom_text(aes(x = xr * 1.06, y = outlet_type, label = sprintf("%s pp  ·  %s int./objavi  ·  %s bez interakcije", fmt_hr(gap_pp, 1), fmt_hr(ipi, 1), fmt_pct_hr(zero_share, 0))),
            hjust = 0, size = 2.9, family = F_MONO, colour = C$muted) +
  scale_colour_manual(values = c(share_items = C$muted, share_interactions = C$ember), labels = c(share_items = "udio u objavama", share_interactions = "udio u interakcijama")) +
  scale_y_discrete(labels = LAB_TYPE) + scale_x_continuous(labels = function(x) paste0(x, " %"), limits = c(0, xr * 1.85), breaks = pretty(c(0, xr)), expand = expansion(mult = c(0.02, 0))) +
  labs(title = "Objavljeno i nagrađeno: tko je pisao, a tko je dobio pažnju",
       subtitle = wrap_lines(sprintf("Deset objava s najviše interakcija nosi %s svih zabilježenih interakcija; jedna jedina %s. Na webu %s objava nema nijednu zabilježenu interakciju.",
                         fmt_pct_hr(D$top10_share_all), fmt_pct_hr(D$top1_share_all), fmt_pct_hr(D$zero_share_web, 0)), 165),
       x = NULL, y = NULL, caption = wrap_lines(paste0(CAP, "\nInterakcije su vrijednosti servisa za praćenje i razlikuju se po platformi (web: dijeljenja i reakcije uz URL; Facebook: reakcije + komentari + dijeljenja; X: RT + favoriti). Zabilježena pažnja, ne kvaliteta."), 170)) + cat_y(10.5)
save_fig(stamp(p4), "04_objavljeno_nagradeno", 12.5, 6.4)

# ---------------------------------------------------------------------------------------------
# F5 — Krugovi: the story radiating outward from the fire (radial time × ring heat map)
# ---------------------------------------------------------------------------------------------
om[, hb3 := hour_bin(h, 3)]
rg <- om[, .(n = .N), by = .(ring, hb3)]
rg_grid <- CJ(ring = 0:4, hb3 = seq(0, hour_bin(H_MAX, 3), by = 3))
rg <- merge(rg_grid, rg, by = c("ring", "hb3"), all.x = TRUE)[is.na(n), n := 0L]
rings <- rd("rings")
first_pts <- rings[n > 0, .(ring, first_h, first_clock, ring_hr, sources, n)]
XR <- max(rg$hb3) + 3
day_ticks <- data.table(h = seq(0, H_MAX, by = 24))[, lab := format(T0 + h * 3600, "%a %d.%m. %H:%M", tz = TZ)]
ring_lab <- copy(RINGS)[, `:=`(x = XR / 2, y = ring + 1)]        # names at the bottom of the dial (angle 180°), where the story has faded
p5 <- ggplot(rg, aes(hb3 + 1.5, ring + 1)) +
  geom_tile(aes(fill = n), width = 3, height = 0.9, colour = C$paper, linewidth = 0.3) +
  geom_vline(data = day_ticks, aes(xintercept = h), colour = C$ink, linewidth = 0.25, linetype = "22", alpha = 0.5) +
  geom_text(data = day_ticks, aes(h, 6.55, label = lab), size = 2.7, family = F_MONO, colour = C$muted) +
  geom_label(data = ring_lab, aes(x, y, label = ring_hr), size = 2.7, family = F_SANS, colour = C$body, fill = alpha(C$paper, 0.85), label.size = NA, label.padding = unit(0.12, "lines")) +
  geom_point(data = first_pts, aes(first_h, ring + 1), colour = C$ink, fill = "white", shape = 21, size = 3, stroke = 1) +
  geom_text(data = first_pts[ring >= 3], aes(first_h, ring + 1.5, label = paste0("prva: sat ", fmt_hr(first_h, 1))), size = 2.6, family = F_MONO, colour = C$body, hjust = 0) +
  annotate("text", x = 0, y = 0.15, label = "OMIŠ", size = 3.4, family = F_SERIF, fontface = "bold", colour = C$deep) +
  scale_fill_gradientn(colours = c("#FFF7E6", "#F5A623", "#E4572E", "#8B1A1A"), trans = "sqrt", name = "objava u pojasu od 3 sata",
                       guide = guide_colourbar(barwidth = 12, barheight = 0.5, title.position = "top", direction = "horizontal")) +
  scale_y_continuous(limits = c(0, 6.9), expand = c(0, 0)) + scale_x_continuous(limits = c(0, XR), expand = c(0, 0)) +
  coord_polar(start = 0, direction = 1, clip = "off") +
  labs(title = sprintf("Krugovi: %s priče ostalo je u Hrvatskoj, %s prešlo je granicu", fmt_pct_hr(100 - D$foreign_share, 0), fmt_pct_hr(D$foreign_share, 0)),
       subtitle = wrap_lines(sprintf("Vrijeme teče u smjeru kazaljke od sata 0 (%s) na vrhu; svaki prsten je jedna zona udaljenosti od požara, od službenih izvora u sredini do ostatka svijeta na rubu. Boja je broj objava u pojasu od 3 sata, bijela točka je prva objava u zoni.\nRegija (%s izvora) ušla je u satu %s, ostatak svijeta u satu %s.",
                         format(T0, "%d.%m. %H:%M", tz = TZ), rings[ring == 3, sources], fmt_hr(rings[ring == 3, first_h], 1), fmt_hr(rings[ring == 4, first_h], 1)), 108),
       x = NULL, y = NULL, caption = wrap_lines(CAP, 118)) +
  theme(panel.grid = element_blank(), axis.text = element_blank(), panel.background = element_rect(fill = C$paper, colour = NA),
        legend.position = "bottom", legend.justification = "center", legend.title = element_text(size = 9, colour = C$muted), plot.margin = margin(16, 20, 8, 20))
save_fig(stamp(p5, polar = TRUE), "05_krugovi", 10.5, 10.5)

# ---------------------------------------------------------------------------------------------
# F6 — Prozor: how much of everything ever published came in the first N hours, per outlet type
# ---------------------------------------------------------------------------------------------
cu <- rd("cumulative_type"); wt <- rd("window_type")
cu[, outlet_type := factor(outlet_type, levels = type_levels)]
lab_pts <- cu[hb == max(hb)][, y0 := cum_share]
p6 <- ggplot(cu, aes(hb, cum_share, colour = outlet_type)) +
  annotate("rect", xmin = 0, xmax = 24, ymin = 0, ymax = 100, fill = C$night, alpha = 0.6) +
  annotate("text", x = 1, y = 97, label = "prva 24 sata", size = 3, family = F_MONO, colour = C$muted, hjust = 0) +
  geom_hline(yintercept = c(50, 80), colour = C$grid, linewidth = 0.6) +
  geom_step(linewidth = 1.05) +
  geom_point(data = wt, aes(t50, 50, colour = outlet_type), size = 2.6) +
  geom_text_repel(data = lab_pts, aes(x = H_MAX + 1, y = y0, label = LAB_TYPE[as.character(outlet_type)]), hjust = 0, direction = "y", size = 3, family = F_SANS,
                  segment.colour = C$grid, xlim = c(H_MAX + 1, H_MAX + 30), box.padding = 0.15, min.segment.length = 0) +
  scale_colour_manual(values = PAL_TYPE, guide = "none") + scale_x_story(limits = c(0, H_MAX + 30)) +
  scale_y_continuous(labels = function(x) paste0(x, " %"), breaks = c(0, 25, 50, 80, 100)) +
  labs(title = sprintf("Prozor: polovica svega objavljeno je unutar %s sati, četiri petine unutar %s", fmt_hr(D$t50_hours, 0), fmt_hr(D$t80_hours, 0)),
       subtitle = wrap_lines(sprintf("Kumulativni udio objava svake vrste izvora po satu priče. Točka je sat u kojem je vrsta prešla polovicu svojih objava. U prva 24 sata objavljeno je %s svih objava, koje su skupile %s svih interakcija.",
                         fmt_pct_hr(D$share_items_first_24h, 0), fmt_pct_hr(D$share_interactions_first_24h, 0)), 165),
       x = NULL, y = "kumulativni udio objava", caption = CAP)
save_fig(stamp(p6, bottom = TRUE), "06_prozor", 12.5, 6.6)

# ---------------------------------------------------------------------------------------------
# F7 — Temperatura jezika: sensational headlines by outlet type and over time
# ---------------------------------------------------------------------------------------------
st <- rd("sensational_type")[order(sensational_share)]; st[, outlet_type := factor(outlet_type, levels = outlet_type)]
stt <- rd("sensational_time")[items >= 5]
WORD_LAB <- c("apokalips" = "apokalipsa", "pak[ao]o|paklen" = "pakao / pakleni", "katastrof" = "katastrofa", "horor" = "horor", "dram" = "drama / dramatično",
              "u[žz]as" = "užas", "strav" = "strava / stravično", "nevi[đd]en" = "neviđeno", "kaos" = "kaos", "inferno" = "inferno", "jeziv" = "jezivo", "[šs]ok" = "šok / šokantno", "stihij" = "stihija")
wd <- rd("sensational_words")[n > 0][1:min(.N, 8)][, lab := WORD_LAB[word]][is.na(lab), lab := word]
p7a <- ggplot(st, aes(sensational_share, outlet_type, fill = outlet_type)) + geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%s  (×%s int.)", fmt_pct_hr(sensational_share), fmt_hr(lift, 2))), hjust = -0.1, size = 3, family = F_MONO, colour = C$body) +
  scale_fill_manual(values = PAL_TYPE, guide = "none") + scale_y_discrete(labels = LAB_TYPE) +
  scale_x_continuous(labels = function(x) paste0(x, " %"), expand = expansion(mult = c(0, 0.6))) +
  labs(subtitle = "Udio naslova sa senzacionalnim rječnikom, po vrsti izvora\n(u zagradi: interakcije po objavi u odnosu na obične naslove iste vrste)", x = NULL, y = NULL) + cat_y(10)
p7b <- ggplot(stt, aes(hb3 + 1.5, sensational_share)) + night_layer() + geom_col(width = 3, fill = C$ember, alpha = 0.85) +
  day_layer(vjust = 1.4) + scale_x_story() + scale_y_continuous(labels = function(x) paste0(x, " %"), expand = expansion(mult = c(0, 0.15))) +
  labs(subtitle = "…i po satu priče (pojasevi od 3 sata)", x = NULL, y = NULL)
p7c <- ggplot(wd, aes(n, reorder(lab, n))) + geom_col(width = 0.6, fill = C$deep) + geom_text(aes(label = n), hjust = -0.2, size = 3, family = F_MONO) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) + labs(subtitle = "Najčešće senzacionalne riječi u naslovima", x = NULL, y = NULL) + cat_y(10)
p7 <- (p7a | p7c) / p7b + plot_layout(heights = c(1.1, 1)) +
  plot_annotation(title = sprintf("Temperatura jezika: %s naslova zvuči kao katastrofa", fmt_pct_hr(D$sensational_share_all)), caption = CAP, theme = theme_fire())
save_fig(p7, "07_temperatura", 12.5, 8.4)

# ---------------------------------------------------------------------------------------------
# F8 — Jeka: identical headlines across outlets
# ---------------------------------------------------------------------------------------------
ec <- rd("echo_clusters_public")
if (nrow(ec)) {
  ec[, first_type := factor(first_type, levels = type_levels)]
  p8 <- ggplot(ec[1:min(20, .N)], aes(cluster_sources, reorder(paste0("#", rank), -rank), fill = first_type)) + geom_col(width = 0.7) +
    geom_text(aes(label = sprintf("%d izvora · %s h od prve do zadnje · %s int.", cluster_sources, fmt_hr(spread_h, 0), fmt_hr(interactions))), hjust = -0.05, size = 2.8, family = F_MONO, colour = C$body) +
    scale_fill_manual(values = PAL_TYPE, labels = LAB_TYPE, breaks = type_levels, name = "tko je prvi objavio") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.6))) +
    labs(title = sprintf("Jeka: %s web-objava o požaru bilo je isti naslov na tri ili više portala", fmt_pct_hr(D$echo_share_web, 0)),
         subtitle = wrap_lines(sprintf("Dvadeset najraširenijih istovjetnih naslova (%s naslova pojavilo se na 3 ili više portala). Boja kaže koja je vrsta izvora prva objavila; %s web-objava izrijekom navodi Hinu.",
                           fmt_hr(D$echo_clusters_n), fmt_pct_hr(D$hina_share_web, 0)), 165),
         x = "broj portala s istim naslovom", y = NULL, caption = wrap_lines(paste0(CAP, "\nNaslovi su uspoređeni nakon uklanjanja velikih slova, dijakritika i interpunkcije; sami naslovi nisu prikazani."), 170)) + cat_y(9)
  save_fig(stamp(p8), "08_jeka", 12.5, 7)
}

# ---------------------------------------------------------------------------------------------
# F9 — Rano i kasno: attention per item by entry window
# ---------------------------------------------------------------------------------------------
el <- rd("early_late")[items >= 5]
p9 <- ggplot(el, aes(entry_window, ipi, fill = platform)) + geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_text(aes(label = paste0(fmt_hr(ipi, 0), "\n(n = ", items, ")")), position = position_dodge(width = 0.75), vjust = -0.25, size = 2.6, family = F_MONO, colour = C$body, lineheight = 0.85) +
  scale_fill_manual(values = PAL_PLAT, labels = c(web = "web", facebook = "Facebook")) + scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(title = "Rano i kasno: koliko interakcija dobije objava prema satu ulaska u priču",
       subtitle = wrap_lines("Prosječne interakcije po objavi prema tome kada je objava izašla, web i Facebook odvojeno. Opisuje različite objave u različitim trenucima, ne učinak premještanja iste objave.", 165),
       x = "sat priče u kojem je objava izašla", y = "interakcije po objavi", caption = CAP) + theme(axis.text.x = element_text(family = F_SANS, size = 10))
save_fig(stamp(p9), "09_rano_kasno", 12.5, 6.2)

cat("Figures written to", FIG_DIR, "\n")
if (SYNTH) cat(">>> ", SYNTH_TAG_EN, " <<<\n")
