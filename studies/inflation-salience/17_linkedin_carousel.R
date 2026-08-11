# 17_linkedin_carousel.R — LinkedIn document-post carousel (8 slides, 1080 x 1350 px, 4:5)
#
# Two audiences, one argument: slides 1-4 speak to the media-monitoring crowd
# (mention counts overstate; the funnel is the payoff), slide 5 is the bridge
# (the cleaned series carries economic signal), slides 6-7 the economics payoff
# (the 20-month speech-to-repricing lag), slide 8 routes both crowds.
#
# Palette semantics, identical on every slide:
#   amber  = raw / misleading counting        teal, green = validated / real
#   purple = institutions' own speech
#
# Every number is derived from the tracked study outputs (derived_v2.csv,
# event_process.csv, event_summary.csv, instrument_correlations.csv,
# instrument_threshold.csv); nothing is hand-typed, so a referee-driven change
# upstream re-flows into the carousel by re-running:
#   Rscript studies/inflation-salience/17_linkedin_carousel.R   (from the repo root)
# Outputs: output/carousel/DigiKat_inflacija_od_brojanja_do_mjerenja.pdf
#          output/carousel/slide_[1-8].png   — previews for the 25%-zoom thumbnail test
#
# Fonts: Source Sans 3 (the DigiKat design-system sans) via sysfonts/showtext, with a
# Segoe UI fallback when Google Fonts is unreachable. Rendering goes through R's cairo
# devices (cairo_pdf, png(type = "cairo")): ragg has its own text stack and ignores
# showtext-registered fonts, so it is deliberately not used here.

suppressWarnings(suppressMessages({
  library(data.table)
  library(ggplot2)
  library(sysfonts)
  library(showtext)
}))

STUDY <- "studies/inflation-salience"
OUT   <- file.path(STUDY, "output")
CARO  <- file.path(OUT, "carousel")
if (!dir.exists(CARO)) dir.create(CARO, recursive = TRUE)

## ------------------------------------------------------------- numbers -----

der_tab <- fread(file.path(OUT, "derived_v2.csv"), header = TRUE, encoding = "UTF-8")
der    <- function(nm) { v <- der_tab[name == nm, value]; stopifnot(length(v) == 1L); v }
dernum <- function(nm) as.numeric(gsub(" ", "", gsub(",", ".", der(nm), fixed = TRUE), fixed = TRUE))

proc  <- fread(file.path(OUT, "event_process.csv"),          header = TRUE, encoding = "UTF-8")
summ  <- fread(file.path(OUT, "event_summary.csv"),          header = TRUE, encoding = "UTF-8")
corr  <- fread(file.path(OUT, "instrument_correlations.csv"), header = TRUE, encoding = "UTF-8")
thres <- fread(file.path(OUT, "instrument_threshold.csv"),    header = TRUE, encoding = "UTF-8")

hr_months <- c("Siječanj", "Veljača", "Ožujak", "Travanj", "Svibanj", "Lipanj",
               "Srpanj", "Kolovoz", "Rujan", "Listopad", "Studeni", "Prosinac")
hr_month_year <- function(ym) {
  p <- as.integer(strsplit(ym, "-", fixed = TRUE)[[1]])
  paste0(hr_months[p[2]], " ", p[1], ".")
}
hr_num <- function(x, dec = 1) formatC(x, format = "f", digits = dec,
                                       big.mark = " ", decimal.mark = ",")
hr_units_word <- c("Jedan", "Dva", "Tri", "Četiri", "Pet", "Šest")
inst_word <- function(n) {         # 1 institucija / 2-4 institucije / 5+ institucija
  r <- n %% 10; rr <- n %% 100
  if (r %in% 2:4 && !(rr %in% 12:14)) "institucije" else "institucija"
}

# Funnel (monitoring payoff)
n_corpus     <- der("n_corpus")       # "710 307", already formatted
n_tagged     <- der("n_tagged")       # posts mentioning inflation
n_candidates <- der("n_candidates")   # religion + inflation co-occurrence pool
n_linked     <- der("n_linked")       # genuine linkage after reading
n_core       <- der("n_core")         # measured core (domestic, about inflation)
surv_pct     <- dernum("pct_candidates_surviving")
overstate    <- dernum("n_tagged") / dernum("n_core")
oom          <- 10 ^ round(log10(overstate))     # "order of magnitude" as in the paper

# Bridge (instrument validation; monitoring stream = the 2021-2024 high-inflation window)
r_headline  <- corr[stream == "monitoring" & component == "headline", pearson]
thres_ratio <- unique(thres[stream == "monitoring", ratio])

# Event register (economics payoff)
own_month  <- der("v2_own_peak_month")         # peak of institutions' own-cost speech
rep_month  <- der("v2_repricing_peak_month")   # peak of repricing coverage
lag_months <- dernum("v2_own_repricing_lag_months")
n_rep_peak <- summ$repricing_peak_n            # repricing posts in the peak month
price_gap  <- dernum("v2_price_gap")           # chained price-level gap vs 2021, %
n_units    <- dernum("v2_matched_units")
n_over_yr  <- dernum("v2_matched_units_over_year")
hicp_own   <- proc[month == own_month, hicp_headline]
hicp_rep   <- proc[month == rep_month, hicp_headline]

# The claims the slides make must hold in the data they are drawn from.
mdiff <- function(a, b) {
  pa <- as.integer(strsplit(a, "-", fixed = TRUE)[[1]])
  pb <- as.integer(strsplit(b, "-", fixed = TRUE)[[1]])
  (pb[1] - pa[1]) * 12L + (pb[2] - pa[2])
}
stopifnot(
  dernum("n_linked") / dernum("n_candidates") < 0.5,     # "manje od polovice je stvarno"
  abs(surv_pct - 100 * dernum("n_linked") / dernum("n_candidates")) < 1,
  overstate >= oom * 0.8,                                # "najmanje <oom> puta"
  length(r_headline) == 1L,
  length(thres_ratio) == 1L, thres_ratio > 2,            # "više nego udvostruči"
  mdiff(own_month, rep_month) == lag_months,
  length(hicp_own) == 1L, length(hicp_rep) == 1L,
  n_rep_peak == max(proc$repricing),                     # peak-month claim
  proc[month == rep_month, repricing] == n_rep_peak,
  abs(proc[month == rep_month, price_gap_from_2021] - price_gap) < 0.05,
  n_over_yr <= length(hr_units_word)
)

## --------------------------------------------------------------- fonts -----

FF <- "Source Sans 3"
got_font <- tryCatch({ font_add_google("Source Sans 3", family = FF); TRUE },
                     error = function(e) FALSE)
if (!got_font) {
  win <- file.path(Sys.getenv("WINDIR"), "Fonts")
  if (file.exists(file.path(win, "segoeui.ttf"))) {
    font_add("Segoe UI", regular = file.path(win, "segoeui.ttf"),
             bold = file.path(win, "segoeuib.ttf"))
    FF <- "Segoe UI"
  } else FF <- "sans"
  message("Google Fonts unavailable; falling back to ", FF)
}
showtext_auto()

## -------------------------------------------------------------- canvas -----

W <- 1080; H <- 1350; M <- 90        # LinkedIn 4:5 page, 90 px grid margin
PXPT <- 72 / 135                     # 1 canvas px in points (1080 px == 8 in)
sz <- function(px) px * PXPT / .pt

COL <- list(ink = "#14181D", muted = "#6B6F76", faint = "#9A9EA6",
            hair = "#E4E2DA", paper = "#FFFFFF",
            amber = "#CF8324", purple = "#6E54A6",
            green = "#2F8F6B", teal = "#1F97A4")

canvas <- function() {
  ggplot() +
    coord_cartesian(xlim = c(0, W), ylim = c(0, H), expand = FALSE, clip = "off") +
    theme_void() +
    theme(plot.background = element_rect(fill = COL$paper, colour = NA),
          plot.margin = margin(0, 0, 0, 0))
}
txt <- function(p, x, y, label, px, colour = COL$ink, face = "plain",
                hjust = 0, vjust = 1, lineheight = 1.08) {
  p + annotate("text", x = x, y = y, label = label, family = FF, fontface = face,
               size = sz(px), colour = colour, hjust = hjust, vjust = vjust,
               lineheight = lineheight)
}
seg <- function(p, x, xend, y, yend, colour, lw = 0.5, lt = "solid") {
  p + annotate("segment", x = x, xend = xend, y = y, yend = yend,
               colour = colour, linewidth = lw, linetype = lt)
}
# Same title position and the same pager corner on every slide.
chrome <- function(p, kicker, page, accent) {
  p <- txt(p, M, H - 66, kicker, 27, colour = accent, face = "bold")
  txt(p, M, 60, paste0(page, " / 8"), 27, colour = COL$faint, vjust = 0)
}

slides <- vector("list", 8)

## ------------------------------------------------------- slide 1 · hook -----

p <- chrome(canvas(), "DIGIKAT · 2021.–2026.", 1, COL$amber)
p <- txt(p, M, 1030, "Alati za praćenje\nmedija broje\nspominjanja.",
         96, face = "bold", lineheight = 1.05)
p <- txt(p, M, 620, "Manje od polovice\nje stvarno.",
         60, colour = COL$amber, face = "bold", lineheight = 1.12)
p <- txt(p, W - M, 66, "→", 70, colour = COL$amber, hjust = 1, vjust = 0)
slides[[1]] <- p

## ------------------------------------------------ slide 2 · credibility -----

p <- chrome(canvas(), "KORPUS", 2, COL$amber)
p <- txt(p, M, 940, n_corpus, 210, face = "bold")
p <- txt(p, M, 650, "medijskih objava, 2021.–2026.", 46, colour = COL$muted)
p <- seg(p, M, M + 90, 470, 470, COL$amber, lw = 1.6)
p <- txt(p, M, 420, "Sektor bez službene\ncjenovne statistike.",
         46, face = "bold", lineheight = 1.15)
slides[[2]] <- p

## ----------------------------------------------- slide 3 · the funnel -----

funnel <- data.frame(
  label = c("Spominju inflaciju",
            "Religija i inflacija zajedno",
            "Stvarna poveznica nakon čitanja",
            "Mjerena jezgra"),
  count = c(n_tagged, n_candidates, n_linked, n_core),
  value = c(dernum("n_tagged"), dernum("n_candidates"),
            dernum("n_linked"), dernum("n_core")),
  col   = c(COL$amber, COL$amber, COL$teal, COL$green)
)
funnel$w   <- funnel$value / max(funnel$value) * (W - 2 * M)
funnel$top <- c(1130, 940, 750, 560)
BAR <- 52

p <- chrome(canvas(), "OD SPOMINJANJA DO MJERENJA", 3, COL$amber)
for (i in seq_len(nrow(funnel))) {
  f <- funnel[i, ]
  p <- txt(p, M, f$top + 44, f$label, 30, colour = COL$muted)
  p <- p + annotate("rect", xmin = M, xmax = M + f$w,
                    ymin = f$top - BAR, ymax = f$top,
                    fill = f$col, colour = NA)
  if (f$w > 0.65 * (W - 2 * M)) {          # wide bar: count inside, right-aligned
    p <- txt(p, M + f$w - 22, f$top - BAR / 2, f$count, 46,
             colour = COL$paper, face = "bold", hjust = 1, vjust = 0.5)
  } else {
    p <- txt(p, M + f$w + 22, f$top - BAR / 2, f$count, 46,
             colour = f$col, face = "bold", vjust = 0.5)
  }
}
p <- txt(p, M, 330, "Brojanje nije mjerenje.\nSvaku objavu treba pročitati.",
         44, face = "bold", lineheight = 1.15)
p <- txt(p, M, 160,
         paste0("DigiKat, ", n_corpus, " objava · pročitano i kodirano ",
                n_candidates, " kandidata"),
         26, colour = COL$faint)
slides[[3]] <- p

## --------------------------------------- slide 4 · the overstatement -----

p <- chrome(canvas(), "PRECJENJIVANJE", 4, COL$amber)
p <- txt(p, M, 960, paste0(oom, " puta"), 150, colour = COL$amber, face = "bold")
p <- txt(p, M, 730, "Najmanje toliko bi brojanje\nsupojavljivanja\nprecijenilo pojavu.",
         54, face = "bold", lineheight = 1.18)
p <- txt(p, M, 430, paste0(n_tagged, " spominjanja naspram ", n_core, " mjerenih objava."),
         32, colour = COL$muted)
slides[[4]] <- p

## -------------------------------------------------- slide 5 · bridge -----

p <- chrome(canvas(), "VALIDACIJA", 5, COL$teal)
p <- txt(p, M, 970, hr_num(r_headline, 2), 170, colour = COL$teal, face = "bold")
p <- txt(p, M, 720, "Korelacija očišćene pokrivenosti\nsa službenom inflacijom.",
         54, face = "bold", lineheight = 1.18)
p <- txt(p, M, 480, "Iznad 4 % pozornost se\nviše nego udvostruči.",
         44, colour = COL$muted, lineheight = 1.2)
p <- txt(p, M, 300, "Razdoblje visoke inflacije, 2021.–2024.", 28, colour = COL$faint)
slides[[5]] <- p

## ------------------------------------------------- slide 6 · payoff -----

mo <- proc$month
n  <- nrow(proc)
x_of <- function(i) M + (i - 1) / (n - 1) * (W - 2 * M)
y0 <- 430; ytop <- 1050; vmax <- 14
y_of <- function(v) y0 + v / vmax * (ytop - y0)
i_own <- match(own_month, mo); i_rep <- match(rep_month, mo)
x1 <- x_of(i_own); yd1 <- y_of(hicp_own)
x2 <- x_of(i_rep); yd2 <- y_of(hicp_rep)
ybr <- 1150                                            # bracket height
curve <- data.frame(x = x_of(seq_len(n)), y = y_of(proc$hicp_headline))

p <- chrome(canvas(), "SREDIŠNJI NALAZ", 6, COL$amber)
p <- p +
  geom_ribbon(data = curve, aes(x = x, ymin = y0, ymax = y),
              fill = COL$amber, alpha = 0.08) +
  geom_line(data = curve, aes(x = x, y = y), colour = COL$amber, linewidth = 1.1)
p <- seg(p, M, W - M, y0, y0, COL$hair, lw = 0.35)                 # baseline
for (k in 0:5) {                                                   # year ticks
  xk <- x_of(1 + 12 * k)
  p <- seg(p, xk, xk, y0 - 10, y0, COL$faint, lw = 0.35)
  p <- txt(p, xk, y0 - 18, as.character(2021 + k), 27, colour = COL$muted,
           hjust = 0.5, vjust = 1)
}
p <- seg(p, x1, x1, yd1 + 16, ybr, COL$purple, lw = 0.45, lt = "22")   # leaders
p <- seg(p, x2, x2, yd2 + 16, ybr, COL$green,  lw = 0.45, lt = "22")
p <- seg(p, x1, x2, ybr, ybr, COL$ink, lw = 0.7)                       # bracket
p <- txt(p, (x1 + x2) / 2, ybr + 20, paste0(lag_months, " mjeseci"),
         62, face = "bold", hjust = 0.5, vjust = 0)
p <- txt(p, x1 - 30, ybr - 30, "govore\no vlastitim\ntroškovima",
         34, colour = COL$purple, face = "bold", hjust = 1, lineheight = 1.1)
p <- txt(p, x2 + 30, ybr - 30, "poskupljenja\nu medijima",
         34, colour = COL$green, face = "bold", hjust = 0, lineheight = 1.1)
p <- p +
  annotate("point", x = x1, y = yd1, shape = 21, size = 6,
           fill = COL$purple, colour = "white", stroke = 1.4) +
  annotate("point", x = x2, y = yd2, shape = 21, size = 6,
           fill = COL$green, colour = "white", stroke = 1.4)
p <- txt(p, x1 + 20, yd1 + 44, paste0(hr_num(hicp_own), " %"),
         32, colour = COL$purple, face = "bold", vjust = 0)
p <- txt(p, x2 + 16, yd2 + 40, paste0(hr_num(hicp_rep), " %"),
         32, colour = COL$green, face = "bold", vjust = 0)
p <- txt(p, M, 330, "Govor na vrhuncu inflacije.\nPoskupljenja kad je splasnula.",
         44, face = "bold", lineheight = 1.15)
p <- txt(p, M, 160,
         paste0("Godišnja inflacija (HICP), Hrvatska · DigiKat, ",
                n_corpus, " objava"),
         26, colour = COL$faint)
slides[[6]] <- p

## ------------------------------------------------ slide 7 · receipts -----

p <- chrome(canvas(), "ISTE INSTITUCIJE", 7, COL$green)
p <- txt(p, M, 980, paste0(n_units, " ", inst_word(n_units)), 116, face = "bold")
p <- txt(p, M, 780,
         "Najprije govore o vlastitim\ntroškovima, kasnije se pojavljuju\nu objavama o poskupljenju.",
         48, lineheight = 1.22)
p <- txt(p, M, 480,
         paste0(hr_units_word[n_over_yr], " razmaka dulja od godine dana."),
         48, face = "bold")
slides[[7]] <- p

## --------------------------------------------------- slide 8 · close -----

p <- chrome(canvas(), "DVIJE PORUKE", 8, COL$amber)
p <- txt(p, M, 1070, "Čitanje i validacija\nsu proizvod.",
         54, colour = COL$teal, face = "bold", lineheight = 1.15)
p <- txt(p, M, 880, "Mediji kao registar\ndogađaja.",
         54, colour = COL$green, face = "bold", lineheight = 1.15)
p <- seg(p, M, W - M, 740, 740, COL$hair, lw = 0.35)
p <- txt(p, M, 680, "doc. dr. sc. Luka Šikić", 42, face = "bold")
p <- txt(p, M, 615, "Hrvatsko katoličko sveučilište · projekt DigiKat",
         34, colour = COL$muted)
p <- txt(p, M, 560, "Rad u recenziji.", 34, colour = COL$muted)
p <- txt(p, M, 400, "U kojem ste sektoru\nvidjeli isti obrazac?",
         58, colour = COL$amber, face = "bold", lineheight = 1.12)
slides[[8]] <- p

## -------------------------------------------------------------- render -----

pdf_file <- file.path(CARO, "DigiKat_inflacija_od_brojanja_do_mjerenja.pdf")
showtext_opts(dpi = 72)                       # cairo_pdf is a 72-dpi device
grDevices::cairo_pdf(pdf_file, width = 8, height = 10, onefile = TRUE)
for (s in slides) print(s)
dev.off()

showtext_opts(dpi = 135)                      # 1080 px / 8 in
for (i in seq_along(slides)) {
  f <- file.path(CARO, sprintf("slide_%d.png", i))
  grDevices::png(f, width = 1080, height = 1350, res = 135, type = "cairo")
  print(slides[[i]])
  dev.off()
}
showtext_opts(dpi = 96)

cat("Carousel written:\n  ", pdf_file, "\n  ",
    file.path(CARO, "slide_[1-8].png"), "\n", sep = "")
