#!/usr/bin/env Rscript
# Publication figures for PAPER_v2.md.
# Reads study outputs only and writes aggregate figures/tables under output/.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggrepel)
  library(here)
  library(scales)
  library(tidyr)
})

source(here::here("R/theme_digikat.R"))

study_dir <- here::here("studies/catholic-education")
out_dir <- file.path(study_dir, "output")
fig_dir <- file.path(out_dir, "figures")
tab_dir <- file.path(out_dir, "tables")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

anchor_labels <- c(
  odgoj_vrijednosti = "Upbringing and values",
  redovi_orders = "Teaching orders",
  katolicka_skola = "Catholic schools",
  vjeronauk = "Religious instruction",
  stepinac = "Alojzije Stepinac",
  strossmayer = "Josip Juraj Strossmayer",
  stadler = "Josip Stadler",
  petkovic_marija = "Marija Petković",
  rituali = "Catholic rituals"
)

anchor_labels_hr <- c(
  odgoj_vrijednosti = "Odgoj i vrijednosti",
  redovi_orders = "Redovničke zajednice",
  katolicka_skola = "Katoličke škole",
  vjeronauk = "Vjeronauk",
  stepinac = "Alojzije Stepinac",
  strossmayer = "Josip Juraj Strossmayer",
  stadler = "Josip Stadler",
  petkovic_marija = "Marija Petković",
  rituali = "Katolički obredi"
)

# Print-first grayscale system. Shape, fill, and direct labels carry meaning so
# every figure remains legible in black-and-white print and for colour-blind readers.
bw <- c(
  ink = "#111111",
  dark = "#404040",
  mid = "#8A8A8A",
  light = "#D8D8D8",
  faint = "#EFEFEF",
  paper = "#FFFFFF",
  grid = "#E5E5E5"
)

theme_paper_bw <- function(base_size = 13) {
  theme_digikat(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = bw[["paper"]], colour = NA),
      panel.background = element_rect(fill = bw[["paper"]], colour = NA),
      panel.grid.major = element_line(colour = bw[["grid"]], linewidth = 0.35),
      axis.text = element_text(colour = bw[["dark"]]),
      axis.title = element_text(colour = bw[["ink"]]),
      plot.title = element_text(colour = bw[["ink"]]),
      plot.subtitle = element_text(colour = bw[["dark"]]),
      plot.caption = element_text(colour = bw[["mid"]]),
      legend.text = element_text(colour = bw[["ink"]]),
      legend.title = element_text(colour = bw[["ink"]]),
      strip.text = element_text(colour = bw[["ink"]])
    )
}

# Figure 1: recurrence versus genuine local anchoring.
candidates <- read.csv(
  file.path(out_dir, "candidate_sites_of_memory.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
) |>
  filter(entity != "rituali") |>
  mutate(
    label = unname(anchor_labels[entity]),
    family = factor(
      case_when(
        entity == "stepinac" ~ "Stepinac",
        entity %in% c("vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "redovi_orders") ~ "Educational institutions",
        TRUE ~ "Other figures"
      ),
      levels = c("Stepinac", "Educational institutions", "Other figures")
    )
  )

family_fills <- c(
  "Stepinac" = bw[["ink"]],
  "Educational institutions" = bw[["mid"]],
  "Other figures" = bw[["paper"]]
)

family_shapes <- c(
  "Stepinac" = 21,
  "Educational institutions" = 22,
  "Other figures" = 24
)

p_anchor <- ggplot(
  candidates,
  aes(x = recurrence_n, y = past_anchor_genuine, label = label)
) +
  geom_hline(
    yintercept = candidates$past_anchor_genuine[candidates$entity == "odgoj_vrijednosti"],
    linewidth = 0.45,
    linetype = "dashed",
    colour = bw[["mid"]]
  ) +
  geom_point(
    aes(fill = family, shape = family),
    size = 4.8,
    colour = bw[["ink"]],
    stroke = 0.9
  ) +
  ggrepel::geom_text_repel(
    family = dk_sans,
    size = 3.8,
    colour = bw[["ink"]],
    min.segment.length = 0,
    box.padding = 0.45,
    point.padding = 0.25,
    seed = 20260806,
    max.overlaps = Inf
  ) +
  scale_x_log10(
    labels = label_number(big.mark = ","),
    breaks = c(300, 1000, 3000, 10000, 30000, 100000)
  ) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    limits = c(0.035, 0.265),
    breaks = seq(0.05, 0.25, 0.05)
  ) +
  scale_fill_manual(values = family_fills, guide = "none") +
  scale_shape_manual(values = family_shapes) +
  labs(
    title = "Frequency is not memory",
    subtitle = "Stepinac appears less often than the institutions, but connects to the past much more strongly",
    x = "Posts mentioning the anchor (log scale)",
    y = "Posts with genuine anchoring",
    fill = NULL,
    caption = "Genuine anchoring: a past-reference expression within ±160 characters of the anchor. DigiKat, 2021–2025."
  ) +
  theme_paper_bw(base_size = 13) +
  guides(
    shape = guide_legend(
      override.aes = list(fill = unname(family_fills), size = 4.8)
    )
  ) +
  theme(
    legend.position = "top",
    panel.grid.major.x = element_line(colour = bw[["grid"]]),
    plot.margin = margin(14, 22, 12, 12)
  )

ggsave(file.path(fig_dir, "paper_anchor_split.png"), p_anchor, width = 11, height = 6.8, dpi = 300)
ggsave(file.path(fig_dir, "paper_anchor_split.svg"), p_anchor, width = 11, height = 6.8)

# Figure 2: pooled month-of-year profiles across the complete 2021–2025 strand.
slice <- readRDS(file.path(out_dir, "slice.rds"))
slice$date <- as.Date(slice$DATE)
slice$month <- as.integer(format(slice$date, "%m"))
slice$year <- as.integer(format(slice$date, "%Y"))

season_keys <- c("stepinac", "vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "rituali")
seasonality <- bind_rows(lapply(season_keys, function(entity_name) {
  slice |>
    filter(.data[[paste0("probe_", entity_name)]] %in% TRUE, !is.na(month)) |>
    count(month, name = "posts") |>
    complete(month = 1:12, fill = list(posts = 0L)) |>
    mutate(
      share = posts / sum(posts),
      entity = entity_name,
      label = unname(anchor_labels[entity_name])
    )
})) |>
  group_by(entity) |>
  mutate(is_peak = share == max(share), peak_label = if_else(is_peak, percent(share, accuracy = 0.1), "")) |>
  ungroup()

temporal_summary <- bind_rows(lapply(c(season_keys, "redovi_orders", "strossmayer"), function(entity_name) {
  sub <- slice |>
    filter(.data[[paste0("probe_", entity_name)]] %in% TRUE, !is.na(date))
  monthly <- sub |>
    count(ym = format(date, "%Y-%m"), name = "posts") |>
    complete(
      ym = format(seq(as.Date("2021-01-01"), as.Date("2025-12-01"), by = "month"), "%Y-%m"),
      fill = list(posts = 0L)
    )
  annual_peaks <- sub |>
    count(year, month, name = "posts") |>
    group_by(year) |>
    slice_max(posts, n = 1, with_ties = FALSE) |>
    ungroup()
  modal_month <- as.integer(names(sort(table(annual_peaks$month), decreasing = TRUE))[1])
  tibble(
    entity = entity_name,
    label = unname(anchor_labels[entity_name]),
    recurrence_n = nrow(sub),
    pooled_monthly_cv = round(sd(monthly$posts) / mean(monthly$posts), 2),
    modal_peak_month = modal_month,
    years_peaking_that_month = sum(annual_peaks$month == modal_month),
    n_years = nrow(annual_peaks)
  )
}))

write.csv(
  seasonality,
  file.path(tab_dir, "paper_seasonality_pooled.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
write.csv(
  temporal_summary,
  file.path(tab_dir, "paper_temporal_pooled.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

month_labels <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
seasonality$label <- factor(
  seasonality$label,
  levels = unname(anchor_labels[season_keys])
)
p_season <- ggplot(seasonality, aes(x = month, y = share)) +
  geom_col(
    aes(fill = is_peak),
    width = 0.78,
    colour = bw[["dark"]],
    linewidth = 0.22,
    show.legend = FALSE
  ) +
  geom_text(
    aes(label = peak_label),
    family = dk_mono,
    size = 3.2,
    vjust = -0.45,
    colour = bw[["ink"]]
  ) +
  facet_wrap(~label, ncol = 3, scales = "free_y") +
  scale_x_continuous(breaks = 1:12, labels = month_labels) +
  scale_y_continuous(labels = label_percent(accuracy = 1), expand = expansion(mult = c(0, 0.14))) +
  scale_fill_manual(values = c(`FALSE` = bw[["light"]], `TRUE` = bw[["ink"]])) +
  labs(
    title = "Different calendars of attention",
    subtitle = "Black bars mark each anchor's peak: February for Stepinac and August for Catholic rituals",
    x = NULL,
    y = "Share of each anchor's posts",
    caption = "Pooled month-of-year distribution across 2021–2025. Catholic rituals are included as a secondary calendar comparison."
  ) +
  theme_paper_bw(base_size = 12.5) +
  theme(
    panel.grid.major.x = element_blank(),
    strip.text = element_text(hjust = 0),
    axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
    plot.margin = margin(14, 14, 12, 12)
  )

ggsave(file.path(fig_dir, "paper_pooled_seasonality.png"), p_season, width = 11, height = 8, dpi = 300)
ggsave(file.path(fig_dir, "paper_pooled_seasonality.svg"), p_season, width = 11, height = 8)

# Figure 3: source origin among posts with a classified outlet.
source_profiles <- read.csv(
  file.path(tab_dir, "confessional_secular_by_entity.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
) |>
  filter(entity %in% c(
    "stepinac", "vjeronauk", "katolicka_skola",
    "odgoj_vrijednosti", "redovi_orders"
  )) |>
  transmute(
    entity,
    label = unname(anchor_labels[entity]),
    classified_coverage = pct_classified,
    confessional = confessional_share_of_classified,
    non_confessional = 1 - confessional_share_of_classified
  ) |>
  arrange(confessional) |>
  mutate(label = factor(label, levels = label))

source_long <- source_profiles |>
  select(entity, label, classified_coverage, confessional, non_confessional) |>
  pivot_longer(
    cols = c(confessional, non_confessional),
    names_to = "origin",
    values_to = "share"
  ) |>
  mutate(
    origin = factor(
      origin,
      levels = c("confessional", "non_confessional"),
      labels = c("Confessional", "Non-confessional")
    ),
    share_label = percent(share, accuracy = 0.1)
  )

write.csv(
  source_profiles,
  file.path(tab_dir, "paper_source_composition.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

p_sources <- ggplot(source_long, aes(x = share, y = label, fill = origin)) +
  geom_col(width = 0.66, colour = bw[["ink"]], linewidth = 0.35) +
  geom_text(
    aes(label = share_label, colour = origin),
    position = position_stack(vjust = 0.5),
    family = dk_mono,
    size = 3.5,
    show.legend = FALSE
  ) +
  scale_x_continuous(
    labels = label_percent(accuracy = 1),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0))
  ) +
  scale_fill_manual(values = c(
    "Confessional" = bw[["ink"]],
    "Non-confessional" = bw[["paper"]]
  )) +
  scale_colour_manual(values = c(
    "Confessional" = bw[["paper"]],
    "Non-confessional" = bw[["ink"]]
  )) +
  labs(
    title = "Stepinac crosses the institutional boundary",
    subtitle = "His source mix is more diverse than that of Catholic schools or religious instruction",
    x = "Share among posts with a classified outlet",
    y = NULL,
    fill = NULL,
    caption = "Source-origin shares among classified posts only. DigiKat, 2021–2025."
  ) +
  theme_paper_bw(base_size = 13) +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.y = element_text(family = dk_sans, colour = bw[["ink"]]),
    plot.margin = margin(14, 18, 12, 12)
  )

ggsave(file.path(fig_dir, "paper_source_boundary.png"), p_sources, width = 10.5, height = 6.2, dpi = 300)
ggsave(file.path(fig_dir, "paper_source_boundary.svg"), p_sources, width = 10.5, height = 6.2)

# Figure 4: document-level overlap versus local proximity.
overlap_summary <- tibble(
  stage = factor(
    c("Anywhere in the document", "Within ±160 characters"),
    levels = c("Anywhere in the document", "Within ±160 characters")
  ),
  share = c(
    mean(slice$past_anchor_doc, na.rm = TRUE),
    mean(slice$past_anchor_genuine, na.rm = TRUE)
  )
) |>
  mutate(share_label = percent(share, accuracy = 0.1))

removed_share <- 1 - overlap_summary$share[2] / overlap_summary$share[1]

write.csv(
  overlap_summary,
  file.path(tab_dir, "paper_overlap_filter.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

profile_metrics <- tibble(
  metric = c(
    "education_strand_n",
    "stepinac_n",
    "stepinac_genuine_share",
    "document_overlap_share",
    "local_overlap_share",
    "overlap_removed_share",
    "stepinac_confessional_share",
    "stepinac_non_confessional_share",
    "stepinac_february_peak_years"
  ),
  value = c(
    nrow(slice),
    candidates$recurrence_n[candidates$entity == "stepinac"],
    candidates$past_anchor_genuine[candidates$entity == "stepinac"],
    overlap_summary$share[1],
    overlap_summary$share[2],
    removed_share,
    source_profiles$confessional[source_profiles$entity == "stepinac"],
    source_profiles$non_confessional[source_profiles$entity == "stepinac"],
    temporal_summary$years_peaking_that_month[temporal_summary$entity == "stepinac"]
  )
)

write.csv(
  profile_metrics,
  file.path(tab_dir, "paper_profile_metrics.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

p_overlap <- ggplot(overlap_summary, aes(x = stage, y = share, fill = stage)) +
  geom_col(width = 0.56, colour = bw[["ink"]], linewidth = 0.45, show.legend = FALSE) +
  geom_text(
    aes(label = share_label),
    family = dk_mono,
    fontface = "bold",
    size = 5,
    vjust = -0.55,
    colour = bw[["ink"]]
  ) +
  annotate(
    "curve",
    x = 1.12,
    xend = 1.86,
    y = overlap_summary$share[1] - 0.015,
    yend = overlap_summary$share[2] + 0.018,
    curvature = 0.08,
    linewidth = 0.55,
    colour = bw[["dark"]],
    arrow = arrow(length = grid::unit(0.12, "inches"), type = "closed")
  ) +
  annotate(
    "text",
    x = 1.5,
    y = 0.265,
    label = paste0(percent(removed_share, accuracy = 0.1), " of apparent links\nremoved"),
    family = dk_serif,
    fontface = "bold",
    size = 4.7,
    colour = bw[["ink"]],
    lineheight = 0.95
  ) +
  scale_fill_manual(values = c(
    "Anywhere in the document" = bw[["light"]],
    "Within ±160 characters" = bw[["ink"]]
  )) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1),
    limits = c(0, 0.44),
    breaks = seq(0, 0.4, 0.1),
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    title = "Local context removes most apparent memory links",
    subtitle = "An anchor and a past reference must meet in the text, not only in the same post",
    x = NULL,
    y = "Share of education-strand posts",
    caption = "Document-level overlap compared with the ±160-character proximity rule. DigiKat, 2021–2025."
  ) +
  theme_paper_bw(base_size = 13) +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(family = dk_sans, colour = bw[["ink"]]),
    plot.margin = margin(14, 18, 12, 12)
  )

ggsave(file.path(fig_dir, "paper_overlap_filter.png"), p_overlap, width = 9.5, height = 6.2, dpi = 300)
ggsave(file.path(fig_dir, "paper_overlap_filter.svg"), p_overlap, width = 9.5, height = 6.2)

# Croatian variants for the thematic-study profile. The manuscript stays in
# English; the DigiKat website follows its Croatian-first presentation rule.
candidates_hr <- candidates |>
  mutate(label = unname(anchor_labels_hr[entity]))

p_anchor_hr <- p_anchor + candidates_hr +
  scale_shape_manual(
    values = family_shapes,
    labels = c("Stepinac", "Obrazovne ustanove", "Ostale osobe")
  ) +
  labs(
    title = "Učestalost nije isto što i sjećanje",
    subtitle = "Stepinac se pojavljuje rjeđe od ustanova, ali je znatno snažnije povezan s prošlošću",
    x = "Broj objava u kojima se sidro pojavljuje (logaritamska ljestvica)",
    y = "Objave sa stvarnim sidrenjem u prošlosti",
    fill = NULL,
    caption = "Stvarno sidrenje: izraz povezan s prošlošću unutar ±160 znakova od sidra. DigiKat, 2021.–2025."
  )

ggsave(file.path(fig_dir, "paper_anchor_split_hr.png"), p_anchor_hr, width = 11, height = 6.8, dpi = 300)

facet_labels_hr <- setNames(
  unname(anchor_labels_hr[season_keys]),
  unname(anchor_labels[season_keys])
)
month_labels_hr <- c("sij", "velj", "ožu", "tra", "svi", "lip", "srp", "kol", "ruj", "lis", "stu", "pro")

p_season_hr <- p_season +
  facet_wrap(
    ~label,
    ncol = 3,
    scales = "free_y",
    labeller = as_labeller(facet_labels_hr)
  ) +
  scale_x_continuous(breaks = 1:12, labels = month_labels_hr) +
  scale_y_continuous(
    labels = label_percent(accuracy = 1, decimal.mark = ","),
    expand = expansion(mult = c(0, 0.14))
  ) +
  labs(
    title = "Različiti kalendari pažnje",
    subtitle = "Crni stupci označavaju vrhunac: veljaču za Stepinca i kolovoz za katoličke obrede",
    x = NULL,
    y = "Udio objava za pojedino sidro",
    caption = "Zajednička mjesečna raspodjela za 2021.–2025.; katolički obredi služe kao kalendarska usporedba."
  )

ggsave(file.path(fig_dir, "paper_pooled_seasonality_hr.png"), p_season_hr, width = 11, height = 8, dpi = 300)

source_levels_hr <- unname(anchor_labels_hr[as.character(source_profiles$entity)])
source_long_hr <- source_long |>
  mutate(
    label = factor(unname(anchor_labels_hr[entity]), levels = source_levels_hr),
    share_label = percent(share, accuracy = 0.1, decimal.mark = ",")
  )

p_sources_hr <- p_sources + source_long_hr +
  scale_x_continuous(
    labels = label_percent(accuracy = 1, decimal.mark = ","),
    limits = c(0, 1),
    expand = expansion(mult = c(0, 0))
  ) +
  scale_fill_manual(
    values = c("Confessional" = bw[["ink"]], "Non-confessional" = bw[["paper"]]),
    labels = c("Konfesionalni", "Nekonfesionalni")
  ) +
  labs(
    title = "Stepinac prelazi institucijsku granicu",
    subtitle = "Njegov je profil izvora raznolikiji od profila katoličkih škola i vjeronauka",
    x = "Udio među objavama s klasificiranim izvorom",
    y = NULL,
    fill = NULL,
    caption = "Podrijetlo izvora među klasificiranim objavama. DigiKat, 2021.–2025."
  )

ggsave(file.path(fig_dir, "paper_source_boundary_hr.png"), p_sources_hr, width = 10.5, height = 6.2, dpi = 300)

cat("Wrote publication figures and pooled temporal tables under", out_dir, "\n")
