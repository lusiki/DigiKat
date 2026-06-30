# =====================================================================
# theme_digikat.R — shared ggplot2 theme matching the DigiKat site design
# (petrol accent · cream paper · Source Serif 4 / Source Sans 3 / IBM Plex Mono).
#
# Source AFTER library(ggplot2) in a page's setup chunk:
#   source("../../R/theme_digikat.R")
# Then plots pick it up automatically (theme_set), or use theme_digikat()/
# scale_fill_digikat() explicitly.
# =====================================================================

suppressWarnings(suppressMessages(library(ggplot2)))

# --- Fonts: pull the design's Google fonts via showtext (graceful fallback) ---
.dk_fonts_ok <- FALSE
if (requireNamespace("showtext", quietly = TRUE) &&
    requireNamespace("sysfonts", quietly = TRUE)) {
  try({
    sysfonts::font_add_google("Source Serif 4", "dk_serif")
    sysfonts::font_add_google("Source Sans 3",  "dk_sans")
    sysfonts::font_add_google("IBM Plex Mono",   "dk_mono")
    showtext::showtext_auto()
    # match showtext rendering dpi to the chunk's fig dpi to keep text sized right
    .dk_dpi <- tryCatch(knitr::opts_chunk$get("dpi"), error = function(e) NULL)
    if (is.null(.dk_dpi)) .dk_dpi <- 200
    showtext::showtext_opts(dpi = .dk_dpi)
    .dk_fonts_ok <- TRUE
  }, silent = TRUE)
}
dk_serif <- if (.dk_fonts_ok) "dk_serif" else "serif"
dk_sans  <- if (.dk_fonts_ok) "dk_sans"  else "sans"
dk_mono  <- if (.dk_fonts_ok) "dk_mono"  else "mono"

# --- Design tokens (mirror assets/css/custom.scss) ---
dk_col <- list(
  accent = "#0F4C5C", accent_700 = "#0A3543", accent_300 = "#2C6F7E",
  accent_200 = "#5A949F", accent_050 = "#EAF0F2",
  ink = "#14181D", body = "#1B1D21", muted = "#6B6F76", faint = "#9A9EA6",
  paper = "#F5F4F0", panel = "#FFFFFF", hairline = "#E4E2DA", grid = "#E2DDD0",
  # Reference lines / lollipop stems / neutral marks
  line = "#9A9EA6",
  # Semantic encodings — kept on-brand. The diverging pair preserves the
  # "plave nijanse = pozitivno · crvene nijanse = negativno" convention used in
  # the pages' prose, so swapping firebrick/steelblue for these needs no text edits.
  pos = "#2F73B8", neg = "#B5462F", neutral = "#F0ECE3",
  # Anomaly / spike highlight (event detection)
  alert = "#B5462F"
)

# 16-hue categorical palette (kept visually distinct from the brand accent)
dk_palette <- c("#b5462f","#cf8324","#a98a1f","#6e8c3a","#2f8f6b","#1f97a4",
                "#2f73b8","#3f4fa0","#6e54a6","#9b4d9e","#c0468a","#b23a52",
                "#8a6240","#5e7488","#4c9c5e","#c2702a")

# Platform identity colors, harmonized to the brand palette: each platform keeps
# its hue family (web=petrol, YouTube=brick red, Facebook=blue …) but is tuned to
# the editorial petrol/warm system instead of the bright Tableau defaults.
dk_platform_colors <- c(
  "web"       = "#0F4C5C",  # petrol (brand) — the dominant platform
  "youtube"   = "#B5462F",  # brick red
  "facebook"  = "#2F73B8",  # blue
  "twitter"   = "#1F97A4",  # teal
  "reddit"    = "#CF8324",  # amber
  "forum"     = "#5E7488",  # slate
  "comment"   = "#6E8C3A",  # olive
  "instagram" = "#C0468A",  # magenta
  "tiktok"    = "#3F4FA0"   # indigo
)

# --- The theme ---
theme_digikat <- function(base_size = 13) {
  ggplot2::theme_minimal(base_size = base_size, base_family = dk_sans) +
    ggplot2::theme(
      # Whole figure shares the page's cream paper — plot AND panel — so charts
      # dissolve into the page with no white box. No framing border (seamless).
      plot.background  = ggplot2::element_rect(fill = dk_col$paper, color = NA),
      panel.background = ggplot2::element_rect(fill = dk_col$paper, color = NA),
      panel.border     = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(color = dk_col$grid, linewidth = 0.4),
      panel.grid.minor = ggplot2::element_blank(),
      axis.ticks       = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(family = dk_mono, size = base_size * 0.78, color = dk_col$muted),
      axis.title       = ggplot2::element_text(family = dk_sans, size = base_size * 0.92, color = dk_col$body),
      plot.title       = ggplot2::element_text(family = dk_serif, face = "bold", size = base_size * 1.5, color = dk_col$ink, margin = ggplot2::margin(b = 4)),
      plot.subtitle    = ggplot2::element_text(family = dk_sans, size = base_size * 1.0, color = dk_col$muted, margin = ggplot2::margin(b = 10)),
      plot.caption     = ggplot2::element_text(family = dk_mono, size = base_size * 0.72, color = dk_col$faint, hjust = 0),
      legend.title     = ggplot2::element_text(family = dk_sans, size = base_size * 0.85, color = dk_col$body),
      legend.text      = ggplot2::element_text(family = dk_sans, size = base_size * 0.82, color = dk_col$body),
      strip.text       = ggplot2::element_text(family = dk_serif, face = "bold", size = base_size * 0.95, color = dk_col$ink),
      plot.title.position = "plot",
      plot.caption.position = "plot"
    )
}

# --- A "void" variant: keeps the cream paper + serif titles, drops the panel/axes.
# For ggraph network plots and empty-data fallbacks (replaces theme_void()/theme_graph()
# which strip the design background to plain white). ---
theme_digikat_void <- function(base_size = 13) {
  theme_digikat(base_size = base_size) +
    ggplot2::theme(
      panel.background = ggplot2::element_blank(),
      panel.border     = ggplot2::element_blank(),
      panel.grid       = ggplot2::element_blank(),
      axis.text        = ggplot2::element_blank(),
      axis.title       = ggplot2::element_blank(),
      axis.ticks       = ggplot2::element_blank()
    )
}

# --- Brand scales (use for categorical / thematic series) ---
scale_fill_digikat   <- function(...) ggplot2::scale_fill_manual(values = dk_palette, ...)
scale_colour_digikat <- function(...) ggplot2::scale_colour_manual(values = dk_palette, ...)
scale_color_digikat  <- scale_colour_digikat

# --- Diverging scales for signed values (sentiment / tonalitet around 0).
# On-brand replacement for the firebrick/white/steelblue scales: red = negative,
# blue = positive, cream-neutral midpoint. ---
scale_fill_digikat_diverging <- function(..., midpoint = 0)
  ggplot2::scale_fill_gradient2(low = dk_col$neg, mid = dk_col$neutral,
                                high = dk_col$pos, midpoint = midpoint, ...)
scale_colour_digikat_diverging <- function(..., midpoint = 0)
  ggplot2::scale_colour_gradient2(low = dk_col$neg, mid = dk_col$neutral,
                                  high = dk_col$pos, midpoint = midpoint, ...)
scale_color_digikat_diverging <- scale_colour_digikat_diverging

# Make it the default theme for any plot that doesn't set one explicitly
ggplot2::theme_set(theme_digikat())
