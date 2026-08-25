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
# showtext converts glyphs to paths on SVG devices. That makes small analytical
# charts several megabytes wide on disk and removes their selectable text. SVG
# output therefore keeps native text and lets the page's web-font CSS render it.
.dk_chunk_device <- tryCatch(knitr::opts_chunk$get("dev"), error = function(e) NULL)
.dk_svg_output <- any(grepl("svg", as.character(.dk_chunk_device), ignore.case = TRUE))
.dk_fonts_ok <- FALSE
if (!.dk_svg_output && requireNamespace("showtext", quietly = TRUE) &&
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
dk_serif <- if (.dk_fonts_ok) "dk_serif" else if (.dk_svg_output) "Source Serif 4" else "serif"
dk_sans  <- if (.dk_fonts_ok) "dk_sans"  else if (.dk_svg_output) "Source Sans 3" else "sans"
dk_mono  <- if (.dk_fonts_ok) "dk_mono"  else if (.dk_svg_output) "IBM Plex Mono" else "mono"

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
  # Okabe–Ito blue and vermilion remain distinguishable under common colour-
  # vision deficiencies. Signed charts also print their values or use shape.
  pos = "#0072B2", neg = "#D55E00", neutral = "#F0ECE3",
  # Anomaly / spike highlight (event detection)
  alert = "#D55E00"
)

# Colour-blind-safe categorical sequence based on Paul Tol's qualitative sets.
# Dense charts must still use direct labels, facets, shape or line type so that
# no distinction depends on colour alone.
dk_palette <- c(
  "#332288", "#117733", "#44AA99", "#88CCEE", "#DDCC77", "#CC6677",
  "#AA4499", "#882255", "#4477AA", "#66CCEE", "#228833", "#CCBB44",
  "#EE6677", "#AA3377", "#BBBBBB", "#EE7733"
)

# Platform identity colors, harmonized to the brand palette: each platform keeps
# its hue family (web=petrol, YouTube=brick red, Facebook=blue …) but is tuned to
# the editorial petrol/warm system instead of the bright Tableau defaults.
dk_platform_colors <- c(
  "web"       = "#4477AA",
  "youtube"   = "#EE6677",
  "facebook"  = "#228833",
  "twitter"   = "#66CCEE",
  "reddit"    = "#EE7733",
  "forum"     = "#777777",
  "comment"   = "#CCBB44",
  "instagram" = "#AA3377",
  "tiktok"    = "#332288"
)

dk_platform_shapes <- c(
  web = 16, youtube = 17, facebook = 15, twitter = 18, reddit = 8,
  forum = 3, comment = 7, instagram = 4, tiktok = 0
)

dk_platform_linetypes <- c(
  web = "solid", youtube = "22", facebook = "42", twitter = "13",
  reddit = "44", forum = "longdash", comment = "twodash",
  instagram = "dotted", tiktok = "dotdash"
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

# --- Editorial map variant -------------------------------------------------
# The analytical maps are read in a wide, card-like figure column. Their type
# should feel like the surrounding article instead of a technical console:
# proportional sans-serif labels, a restrained serif title, a white canvas and
# softer grid lines. Raster output embeds these faces in the image, avoiding
# the Arial fallback that occurs when an SVG is loaded as an isolated image.
theme_digikat_map <- function(base_size = 14) {
  theme_digikat(base_size = base_size) +
    ggplot2::theme(
      plot.background  = ggplot2::element_rect(fill = dk_col$panel, color = NA),
      panel.background = ggplot2::element_rect(fill = dk_col$panel, color = NA),
      panel.grid.major = ggplot2::element_line(color = "#ECE9E2", linewidth = 0.35),
      axis.text = ggplot2::element_text(
        family = dk_sans, size = base_size * 0.84, color = dk_col$muted,
        lineheight = 1.05
      ),
      axis.title = ggplot2::element_text(
        family = dk_sans, size = base_size * 0.92, color = dk_col$body,
        margin = ggplot2::margin(t = 8, r = 8, b = 8, l = 8)
      ),
      plot.title = ggplot2::element_text(
        family = dk_serif, face = "bold", size = base_size * 1.5,
        color = dk_col$ink, lineheight = 1.06, margin = ggplot2::margin(b = 7)
      ),
      plot.subtitle = ggplot2::element_text(
        family = dk_sans, size = base_size, color = dk_col$muted,
        lineheight = 1.15, margin = ggplot2::margin(b = 14)
      ),
      plot.caption = ggplot2::element_text(
        family = dk_sans, size = base_size * 0.72, color = dk_col$faint,
        lineheight = 1.12, hjust = 0, margin = ggplot2::margin(t = 12)
      ),
      legend.title = ggplot2::element_text(
        family = dk_sans, size = base_size * 0.86, color = dk_col$body,
        face = "bold"
      ),
      legend.text = ggplot2::element_text(
        family = dk_sans, size = base_size * 0.82, color = dk_col$body
      ),
      strip.text = ggplot2::element_text(
        family = dk_sans, face = "bold", size = base_size * 0.94,
        color = dk_col$ink, margin = ggplot2::margin(t = 5, b = 8)
      ),
      plot.margin = ggplot2::margin(18, 22, 18, 18)
    )
}

theme_digikat_map_void <- function(base_size = 14) {
  theme_digikat_map(base_size = base_size) +
    ggplot2::theme(
      panel.background = ggplot2::element_blank(),
      panel.border = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank()
    )
}

# --- Brand scales (use for categorical / thematic series) ---
scale_fill_digikat   <- function(...) ggplot2::scale_fill_manual(values = dk_palette, ...)
scale_colour_digikat <- function(...) ggplot2::scale_colour_manual(values = dk_palette, ...)
scale_color_digikat  <- scale_colour_digikat

# Human-readable labels for the canonical SCREAMING_SNAKE topic keys used in
# analytical data. Keep machine keys in data; translate only at display time.
digikat_topic_label <- function(value) {
  label <- tolower(gsub("_", " ", as.character(value), fixed = TRUE))
  paste0(toupper(substr(label, 1L, 1L)), substring(label, 2L))
}

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
