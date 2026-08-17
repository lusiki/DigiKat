#!/usr/bin/env Rscript
# English-language figures and fragments for the annual review.
#
# This file is sourced by 03_report_assets.R after the checked aggregate and scalar registries have
# been assembled. It changes presentation only: every value comes from the same in-memory objects
# and annual_report_derived.csv as the Croatian edition.

fig_en <- function(name) file.path(AR_FIGURES_EN, paste0(name, ".png"))
save_fig_en <- function(plot, name, width, height) {
  ggsave(fig_en(name), plot, width = width, height = height, dpi = AR_DPI, bg = dk_col$paper)
  invisible(fig_en(name))
}

src_corpus_en <- sprintf("Source: DigiKat official corpus. Calendar year %d.", YEAR)
src_theme_en <- sprintf(
  paste("Source: DigiKat; %s posts from the %d corpus year in the theme sample",
        "(%s of the corpus year; TikTok and texts shorter than 101 characters are excluded)."),
  ar_fmt_int_en(nlp_cov$in_corpus_rows_year[nlp_cov$layer == "teme"]), YEAR,
  ar_fmt_pct_en(100 * nlp_cov$effective_rate[nlp_cov$layer == "teme"], 1)
)
src_tone_en <- sprintf(
  paste("Source: DigiKat; %s posts from the %d corpus year in the tone sample (%s of the corpus year).",
        "Lines show 95%% confidence intervals."),
  ar_fmt_int_en(nlp_cov$in_corpus_rows_year[nlp_cov$layer == "ton"]), YEAR,
  ar_fmt_pct_en(100 * nlp_cov$effective_rate[nlp_cov$layer == "ton"], 1)
)

FIG_WORDS_EN <- list()
register_fig_en <- function(name, title, measure, note, alt) {
  FIG_WORDS_EN[[name]] <<- list(title = title, measure = measure, note = note, alt = alt)
  invisible(name)
}

## Figure 1: ten generated numbers ---------------------------------------------------------------
tile_last_en <- ed(
  `2024` = list(value = ar_fmt_int_en(coverage$collected_days),
                label = "days of the year contain collected data; the rest is an interruption"),
  `2025` = list(value = ar_fmt_change_en(web_stream$change_pct),
                label = "more web posts in the same collection stream, despite fewer tracked sources")
)
tiles_en <- data.frame(
  value = c(ar_fmt_int_en(total_posts), ar_fmt_pct_en(web_share),
            ar_fmt_int_en(concentration$distinct_sources),
            ar_fmt_int_en(concentration$sources_to_half),
            ar_fmt_pct_en(100 * lead_theme$share_of_docs), ar_fmt_pct_en(abuse_share),
            ar_fmt_int_en(peak$peak_posts), ar_fmt_pct_en(100 * tone_overall$share_positive),
            paste0(ar_fmt_num_en(cli_ratio, 2), "×"), tile_last_en$value),
  label = wrap(c(
    sprintf("posts on Catholic themes were recorded in %d", YEAR),
    "of annual volume was published on the web rather than on social media",
    "distinct sources published at least one such post",
    "sources account for half of the year's volume",
    "of posts in the theme sample are led by spirituality and liturgy",
    "of all theme mentions concern abuse and the crisis of trust",
    ed(`2024` = "posts were recorded on Christmas Day, the annual maximum",
       `2025` = "posts were recorded on 21 April, the day Pope Francis died, the annual maximum"),
    "of posts in the tone sample use predominantly positive vocabulary",
    "as many conflict words appear in secular sources as in confessional sources",
    tile_last_en$label
  )),
  stringsAsFactors = FALSE
)
save_fig_en(make_tiles(tiles_en), "fig01_ten_numbers", 7.4, 6.8)
register_fig_en("fig01_ten_numbers", sprintf("Ten numbers from %d", YEAR),
                "Every number is computed from the corpus; none was entered by hand.",
                src_corpus_en,
                "Ten highlighted numbers from the year, each accompanied by one explanatory sentence.")

# The cover spark has no words or locale-dependent marks, so the same generated pixels are valid in
# both editions. Keeping a copy in the English asset tree makes the language bundle self-contained.
file.copy(fig("cover_spark"), fig_en("cover_spark"), overwrite = TRUE)

## Figure 2: platforms ---------------------------------------------------------------------------
plat_en <- platform |> filter(total_posts > 0) |> arrange(total_posts)
plat_en$platform_en <- factor(unname(ar_platform_en[plat_en$SOURCE_TYPE]),
                              levels = unname(ar_platform_en[plat_en$SOURCE_TYPE]))
plat_en$emphasis <- plat_en$SOURCE_TYPE == plat_en$SOURCE_TYPE[which.max(plat_en$total_posts)]
p2_en <- ggplot(plat_en, aes(platform_en, post_share)) +
  geom_col(aes(fill = emphasis), width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = paste0(ar_fmt_pct_en(100 * post_share), "  ·  ", ar_fmt_int_en(total_posts))),
            hjust = -0.08, family = dk_mono, size = 3.05, colour = dk_col$body) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = c(`TRUE` = dk_col$accent, `FALSE` = dk_col$accent_200)) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.30))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12) + theme(panel.grid.major.y = element_blank())
save_fig_en(p2_en, "fig02_platforms", 7.2, 4.2)
register_fig_en("fig02_platforms", "The web carries more than half of all recorded posts",
                sprintf("Platform share of %s posts from %d, with the absolute count.",
                        ar_fmt_int_en(total_posts), YEAR),
                src_corpus_en, "Horizontal bars showing every platform's share of annual posts.")

## Figure 3: monthly rhythm ----------------------------------------------------------------------
mplot_en <- mplot
group_lab_en <- c(unname(ar_platform_en[top3]), "Other")
names(group_lab_en) <- c(top3, "ostalo")
ends_en <- mplot_en |> group_by(group) |> filter(date == max(date)) |> ungroup()
month_label_en <- function(x) month.abb[as.integer(format(as.Date(x), "%m"))]
p3_en <- ggplot(mplot_en, aes(date, posts, colour = group)) +
  geom_line(linewidth = 0.9, show.legend = FALSE) +
  geom_point(size = 1.5, show.legend = FALSE) +
  geom_text(data = ends_en, aes(label = group_lab_en[group]), hjust = -0.12, vjust = 0.4,
            family = dk_sans, size = 3.2, show.legend = FALSE) +
  scale_colour_manual(values = group_cols) +
  scale_x_date(breaks = seq(as.Date(sprintf("%d-01-01", YEAR)),
                            as.Date(sprintf("%d-12-01", YEAR)), by = "month"),
               labels = month_label_en, expand = expansion(mult = c(0.02, 0.24))) +
  scale_y_continuous(labels = label_number(big.mark = ","), limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.08))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12)
save_fig_en(p3_en, "fig03_months", 7.2, 4.2)
register_fig_en(
  "fig03_months",
  ed(`2024` = "The curve begins in June because earlier months are absent from the data",
     `2025` = "April carries the annual peak; the September dip is a collection interruption"),
  "Monthly post count for the three largest platforms and all others combined.",
  ed(`2024` = paste(src_corpus_en,
                    "There was no collection from 9 January through 31 May, so those months are absent;",
                    "September is incomplete because collection stopped from 16 through 30 September.",
                    "Direct labels make the lines readable without colour."),
     `2025` = paste(src_corpus_en,
                    "September is incomplete because collection stopped for its first fourteen days.",
                    "Direct labels make the lines readable without colour.")),
  "Monthly post-count lines for the web, Facebook, YouTube and all other platforms combined."
)

## Figure 4: daily year --------------------------------------------------------------------------
arc_points_en <- arc_points
arc_points_en$label <- paste0(ar_event_name_en(arc_points_en$date), "\n",
                              as.integer(format(arc_points_en$date, "%d")), " ",
                              month.abb[as.integer(format(arc_points_en$date, "%m"))])
p4_en <- ggplot(daily, aes(date, drawn)) +
  { if (nrow(gaps)) annotate("rect", xmin = as.Date(gaps$start), xmax = as.Date(gaps$end),
                             ymin = 0, ymax = ymax, fill = dk_col$hairline, alpha = 0.65) } +
  { if (nrow(gaps)) {
      widest <- which.max(gaps$days)
      annotate("text", x = as.Date(gaps$start[widest]) + as.integer(gaps$days[widest] / 2),
               y = ymax * 0.52, label = "collection\ninterruption", hjust = 0.5, vjust = 1,
               family = dk_sans, size = 2.8, colour = dk_col$muted, lineheight = 1.05)
    } } +
  geom_line(colour = dk_col$accent_300, linewidth = 0.4, na.rm = TRUE) +
  geom_point(data = arc_points_en, colour = dk_col$alert, size = 2.6) +
  geom_text(data = arc_points_en, aes(label = label), vjust = -0.55,
            hjust = as.integer(format(arc_points_en$date, "%j")) / AR_CALENDAR_DAYS,
            family = dk_sans, size = 2.9, colour = dk_col$body, lineheight = 1.05) +
  scale_x_date(breaks = seq(as.Date(sprintf("%d-01-01", YEAR)),
                            as.Date(sprintf("%d-12-01", YEAR)), by = "month"),
               labels = month_label_en,
               limits = c(as.Date(sprintf("%d-01-01", YEAR)), as.Date(sprintf("%d-12-31", YEAR))),
               expand = expansion(mult = 0.01)) +
  scale_y_continuous(labels = label_number(big.mark = ","), limits = c(0, ymax),
                     expand = expansion(mult = c(0, 0))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 12)
save_fig_en(p4_en, "fig04_year", 7.4, 4.2)
register_fig_en(
  "fig04_year",
  ed(`2024` = "Both annual peaks are feast days; Easter fell outside collection",
     `2025` = "The year has one clear peak, and it was not a controversy"),
  sprintf("Daily post count across %s collected days; days above three standard deviations are labelled.",
          ar_fmt_int_en(coverage$collected_days)),
  ed(`2024` = paste(src_corpus_en,
                    "The peak threshold was fixed before inspecting the data; means and dispersion use",
                    "collected days only. Easter 2024 fell during the long interruption and is absent.",
                    "Grey bands mark periods without collection."),
     `2025` = paste(src_corpus_en,
                    "The peak threshold was fixed before inspecting the data; means and dispersion use",
                    "collected days only.")),
  "Daily post count for the full year, with peaks and collection interruptions marked."
)

## Figures 5 and 6: themes and tone --------------------------------------------------------------
th_en <- themes |> arrange(share_of_mentions)
th_en$topic_en <- factor(unname(ar_topic_en[th_en$topic]),
                         levels = unname(ar_topic_en[th_en$topic]))
th_en$emphasis <- th_en$rank == 1
p5_en <- ggplot(th_en, aes(topic_en, share_of_mentions)) +
  geom_col(aes(fill = emphasis), width = 0.5, show.legend = FALSE) +
  geom_text(aes(label = ar_fmt_pct_en(100 * share_of_mentions)), hjust = -0.12,
            family = dk_mono, size = 2.95, colour = dk_col$body) +
  coord_flip(clip = "off") +
  scale_fill_manual(values = c(`TRUE` = dk_col$accent, `FALSE` = dk_col$accent_200)) +
  scale_y_continuous(labels = label_percent(), expand = expansion(mult = c(0, 0.22))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) + theme(panel.grid.major.y = element_blank())
save_fig_en(p5_en, "fig05_themes", 7.2, 5.8)
register_fig_en("fig05_themes", "The year is led by what the Church does every week",
                "Share of all dictionary mentions by category; all sixteen categories are shown.",
                src_theme_en, "Horizontal bars showing the shares of all sixteen theme categories.")

tt_en <- tone_theme |> filter(reportable) |> arrange(sentiment_mean)
tt_en$topic_en <- factor(unname(ar_topic_en[tt_en$topic]),
                         levels = unname(ar_topic_en[tt_en$topic]))
p6_en <- ggplot(tt_en, aes(sentiment_mean, topic_en)) +
  geom_vline(xintercept = 0, colour = dk_col$line, linewidth = 0.4, linetype = "22") +
  geom_segment(aes(x = sentiment_lower, xend = sentiment_upper, yend = topic_en),
               colour = dk_col$accent_200, linewidth = 1.1) +
  geom_point(aes(colour = sentiment_mean >= 0), size = 3.1, show.legend = FALSE) +
  geom_text(aes(label = ar_fmt_num_en(sentiment_mean, 2)), vjust = -1.05,
            family = dk_mono, size = 2.85, colour = dk_col$body) +
  scale_colour_manual(values = c(`TRUE` = dk_col$pos, `FALSE` = dk_col$neg)) +
  scale_x_continuous(labels = label_number(), expand = expansion(mult = c(0.10, 0.10))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) + theme(panel.grid.major.y = element_blank())
save_fig_en(p6_en, "fig06_tone_themes", 7.2, 4.2)
register_fig_en("fig06_tone_themes", "No major theme is negative on average",
                "Mean tone score by a post's leading theme, from −1 to +1; categories with at least 30 posts.",
                src_tone_en, "Mean tone score by leading theme, with confidence intervals.")

## Figure 7: source labels -----------------------------------------------------------------------
tl_en <- tone_label |> filter(label != "unclassified")
label_en <- c(confessional = "Confessional", secular = "Secular")
tl_long_en <- rbind(
  data.frame(label_en = unname(label_en[tl_en$label]), panel = "Tone score (−1 to +1)",
             value = tl_en$sentiment_mean, lower = tl_en$sentiment_lower,
             upper = tl_en$sentiment_upper, stringsAsFactors = FALSE),
  data.frame(label_en = unname(label_en[tl_en$label]), panel = "Conflict words per 1,000 words",
             value = tl_en$cli_mean, lower = tl_en$cli_lower, upper = tl_en$cli_upper,
             stringsAsFactors = FALSE)
)
tl_long_en$panel <- factor(tl_long_en$panel,
                           levels = c("Tone score (−1 to +1)", "Conflict words per 1,000 words"))
tl_long_en$mark <- ifelse(tl_long_en$panel == "Tone score (−1 to +1)",
                          ar_fmt_num_en(tl_long_en$value, 2), ar_fmt_num_en(tl_long_en$value, 0))
p7_en <- ggplot(tl_long_en, aes(value, label_en)) +
  geom_segment(aes(x = lower, xend = upper, yend = label_en),
               colour = dk_col$accent_200, linewidth = 1.2) +
  geom_point(size = 3.2, colour = dk_col$accent) +
  geom_text(aes(label = mark), vjust = -1.1, family = dk_mono, size = 2.9, colour = dk_col$body) +
  facet_wrap(~ panel, scales = "free_x") +
  scale_x_continuous(labels = label_number(), expand = expansion(mult = 0.18)) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.y = element_blank(), panel.spacing.x = unit(16, "pt"))
save_fig_en(p7_en, "fig07_tone_labels", 7.4, 2.6)
register_fig_en("fig07_tone_labels", "Secular sources discuss the same field in sharper language",
                sprintf("Confessional (%s posts) and secular sources (%s posts) in the tone sample.",
                        ar_fmt_int_en(tl_en$n_docs[tl_en$label == "confessional"]),
                        ar_fmt_int_en(tl_en$n_docs[tl_en$label == "secular"])),
                paste(src_tone_en, "Source labels are editorial proposals, so the comparison is indicative."),
                "Tone and conflict-word measures for confessional and secular sources.")

## Figure 8: movement within one collection stream ----------------------------------------------
period_base_en <- ed(`2024` = sprintf("Q3 %d", YEAR), `2025` = sprintf("H2 %d", AR_BASELINE_YEAR))
period_report_en <- ed(`2024` = sprintf("Q4 %d", YEAR), `2025` = sprintf("H2 %d", YEAR))
stream_fmt_en <- function(x) if (stream_is_rate) ar_fmt_num_en(x, 1) else ar_fmt_int_en(x)
sl_long_en <- rbind(
  data.frame(platform = sl$SOURCE_TYPE, x = period_base_en, posts = sl$base_value),
  data.frame(platform = sl$SOURCE_TYPE, x = period_report_en, posts = sl$report_value)
)
sl_long_en$x <- factor(sl_long_en$x, levels = c(period_base_en, period_report_en))
sl_end_en <- sl_long_en[sl_long_en$x == period_report_en, ]
sl_end_en$mark <- paste0("  ", unname(ar_platform_en[sl_end_en$platform]), " · ",
                         stream_fmt_en(sl$base_value[match(sl_end_en$platform, sl$SOURCE_TYPE)]), " → ",
                         stream_fmt_en(sl_end_en$posts))
sl_end_en <- sl_end_en[order(sl_end_en$posts), ]
label_y_en <- log10(sl_end_en$posts)
min_sep_en <- diff(range(log10(sl_long_en$posts))) * 0.045
for (i in seq_along(label_y_en)[-1]) label_y_en[i] <- max(label_y_en[i], label_y_en[i - 1] + min_sep_en)
sl_end_en$label_y <- 10^label_y_en
p8_en <- ggplot(sl_long_en, aes(x, posts, group = platform)) +
  geom_line(colour = dk_col$accent_300, linewidth = 0.9) +
  geom_point(size = 2.6, colour = dk_col$accent) +
  geom_text(data = sl_end_en, aes(y = label_y, label = mark), hjust = 0,
            family = dk_sans, size = 3.1, colour = dk_col$body) +
  scale_y_continuous(trans = "log10", labels = label_number(big.mark = ",")) +
  scale_x_discrete(expand = expansion(mult = c(0.18, 0.86))) +
  labs(title = NULL, subtitle = NULL, caption = NULL, x = NULL, y = NULL) +
  theme_digikat(base_size = 11) +
  theme(panel.grid.major.x = element_blank(), axis.text.y = element_blank())
save_fig_en(p8_en, "fig08_stream", 7.2, 4.2)
register_fig_en(
  "fig08_stream",
  ed(`2024` = "Facebook almost doubles, but the tracked-page list grows with it",
     `2025` = "The web grows even though fewer sources are tracked than a year earlier"),
  ed(`2024` = paste("Posts per collected day, third versus fourth quarter, within the collection",
                    "stream operating since July 2024; logarithmic scale."),
     `2025` = paste("Posts in the second half of each year, within the collection stream operating",
                    "since July 2024; logarithmic scale.")),
  ed(`2024` = paste("Source: DigiKat official corpus, post2024 collection stream. This is movement",
                    "within one year, not a comparison with the previous year. Q4 includes Advent and",
                    "Christmas. Rates per collected day prevent the September interruption from appearing as a fall."),
     `2025` = paste("Source: DigiKat official corpus, post2024 collection stream. The comparison does",
                    "not cross the 2024 collection seam, and the same interruption dates are removed from both periods.")),
  "Slope chart comparing platform volume within the same collection stream."
)

## Figure 9: concentration ----------------------------------------------------------------------
p9_en <- ggplot(curve, aes(rank, cum)) +
  geom_line(colour = dk_col$accent, linewidth = 0.9) +
  geom_segment(x = 1, xend = half_rank, y = 0.5, yend = 0.5,
               colour = dk_col$alert, linewidth = 0.4, linetype = "22") +
  geom_point(x = half_rank, y = 0.5, colour = dk_col$alert, size = 2.8) +
  annotate("text", x = half_rank * 1.25, y = 0.5,
           label = sprintf("%s sources → half of annual volume", ar_fmt_int_en(half_rank)),
           hjust = 0, vjust = -0.7, family = dk_sans, size = 3.2, colour = dk_col$body) +
  scale_x_log10(breaks = c(1, 10, 100, 1000, 5000), labels = label_number(big.mark = ",")) +
  scale_y_continuous(labels = label_percent(), limits = c(0, 1),
                     expand = expansion(mult = c(0.01, 0.03))) +
  labs(title = NULL, subtitle = NULL, caption = NULL,
       x = "Source rank (logarithmic scale)", y = NULL) +
  theme_digikat(base_size = 11)
save_fig_en(p9_en, "fig09_concentration", 7.2, 4.2)
register_fig_en("fig09_concentration", "A small number of sources carries a great deal, but the tail is long",
                sprintf("Cumulative share of annual volume by source rank; %s sources in total.",
                        ar_fmt_int_en(concentration$distinct_sources)),
                src_corpus_en, "Cumulative share of annual post volume by source rank.")

for (nm in names(FIG_WORDS_EN)) {
  w <- FIG_WORDS_EN[[nm]]
  ar_figure(file.path(AR_TABLES_EN, paste0("block_", nm, ".md")), nm, w$title, w$measure,
            w$note, w$alt, figure_dir = "../figures-en")
}

## English summary and table fragments -----------------------------------------------------------
ar_write_utf8(paste0("- ", summary_en), file.path(AR_TABLES_EN, "summary.md"))

metric_or_dash_en <- function(value, coverage) {
  ifelse(coverage < 0.05, "not recorded", ar_fmt_int_en(value))
}
ar_fragment(file.path(AR_TABLES_EN, "table_platform.md"), "Where were the posts published?",
  ar_md_table(data.frame(
    Platform = unname(ar_platform_en[plat_tab$SOURCE_TYPE]),
    Posts = ar_fmt_int_en(plat_tab$total_posts), Share = ar_fmt_pct_en(100 * plat_tab$post_share),
    Interactions = metric_or_dash_en(plat_tab$total_interactions, plat_tab$interaction_coverage),
    Reach = metric_or_dash_en(plat_tab$total_reach, plat_tab$reach_coverage), check.names = FALSE),
    align = c(":---", "---:", "---:", "---:", "---:")),
  paste("Source: DigiKat official corpus. 'Not recorded' means the platform measure is absent from",
        "the collected data, not that no interactions or reach occurred. Posts, interactions and reach",
        "answer three different questions and are not added together."))

ar_fragment(file.path(AR_TABLES_EN, "table_league.md"), "Which sources publish most?",
  ar_md_table(data.frame(`#` = league_top$rank, Source = league_top$name_hr,
    Posts = ar_fmt_int_en(league_top$posts), `Share of year` = ar_fmt_pct_en(league_top$share_of_year, 2),
    Label = ifelse(league_top$label == "confessional", "confessional", "secular"), check.names = FALSE),
    align = c("---:", ":---", "---:", "---:", ":---")),
  paste("Source: DigiKat official corpus. Institutional media with at least five posts in the year",
        "may be named; individual accounts are never named. Rank measures volume, not quality or influence."))

ar_fragment(file.path(AR_TABLES_EN, "table_themes.md"), "What did the space discuss?",
  ar_md_table(data.frame(Theme = unname(ar_topic_en[themes_tab$topic]),
    Mentions = ar_fmt_int_en(themes_tab$mentions),
    `Share of mentions` = ar_fmt_pct_en(100 * themes_tab$share_of_mentions),
    `Leading theme of post` = ar_fmt_pct_en(100 * themes_tab$share_of_docs), check.names = FALSE),
    align = c(":---", "---:", "---:", "---:")),
  paste("Source: DigiKat theme sample for", YEAR,
        "The two columns answer different questions. 'Share of mentions' distributes all dictionary",
        "matches among categories, so one post may contribute to several themes. 'Leading theme of post'",
        "assigns one category to each post and sums to 100% together with posts without a match",
        paste0("(", ar_fmt_pct_en(100 * themes_cov$share_without_theme), ").")))

ar_fragment(file.path(AR_TABLES_EN, "table_tone.md"), "What language is used for leading themes?",
  ar_md_table(data.frame(Theme = unname(ar_topic_en[tone_tab$topic]),
    Posts = ar_fmt_int_en(tone_tab$n_docs), `Tone score` = ar_fmt_num_en(tone_tab$sentiment_mean, 2),
    `Conflict words` = ar_fmt_num_en(tone_tab$cli_mean, 0), check.names = FALSE),
    align = c(":---", "---:", "---:", "---:")),
  paste("Source: DigiKat tone sample for", YEAR,
        "The tone score runs from −1 to +1 and measures vocabulary, not an author's position or the",
        "truth of a claim. Conflict words count terms of conflict, anger and fear per 1,000 words.",
        "Only themes with at least thirty posts in the sample are shown."))

ar_fragment(file.path(AR_TABLES_EN, "table_events.md"), "Which days departed from the annual rhythm?",
  ar_md_table(data.frame(Date = ar_date_short_en(arc_tab$peak_day),
    Event = ar_event_name_en(arc_tab$peak_day), Posts = ar_fmt_int_en(arc_tab$peak_posts),
    Deviation = paste0(ar_fmt_num_en(arc_tab$peak_z, 1), " sd"),
    `Days in arc` = ar_fmt_int_en(arc_tab$days), check.names = FALSE),
    align = c(":---", ":---", "---:", "---:", "---:")),
  paste("Source: DigiKat official corpus, all days in the year. Deviation is distance from the mean",
        "day in standard deviations; the threshold of three was set before data inspection. Names come",
        "from the public calendar and were checked against the thematic composition of those days,",
        "because a peak identifies a date, not a cause."))

stream_value_en <- function(x) if (stream_is_rate) ar_fmt_num_en(x, 1) else ar_fmt_int_en(x)
ar_fragment(file.path(AR_TABLES_EN, "table_stream.md"),
  ed(`2024` = "What grew and what fell during the year?", `2025` = "What grew and what fell?"),
  ar_md_table(setNames(data.frame(
    unname(ar_platform_en[stream_tab$SOURCE_TYPE]), stream_value_en(stream_tab$base_value),
    stream_value_en(stream_tab$report_value), ar_fmt_change_en(stream_tab$change_pct),
    ar_fmt_change_en(stream_tab$sources_change_pct), stringsAsFactors = FALSE),
    c("Platform", period_base_en, period_report_en, "Posts", "Sources")),
    align = c(":---", "---:", "---:", "---:", "---:")),
  ed(`2024` = paste("Source: DigiKat official corpus, collection stream operating since July 2024.",
                    "Values are posts per collected day, so the September interruption is excluded.",
                    "This is within-year movement, not a comparison with the previous year; Q4 includes",
                    "Advent and Christmas. The last column records changes in tracked-source count."),
     `2025` = paste("Source: DigiKat official corpus, collection stream operating since July 2024.",
                    "The last column records changes in tracked-source count. If volume and source count",
                    "rise together, expanded tracking is a more likely explanation than discussion alone.")))

ar_fragment(file.path(AR_TABLES_EN, "table_typology.md"),
  "How are actors distributed by interactions and reach?",
  ar_md_table(data.frame(Group = unname(ar_typology_en[typ_tab$quadrant]),
    Actors = ar_fmt_int_en(typ_tab$actors), Share = ar_fmt_pct_en(100 * typ_tab$share),
    check.names = FALSE), align = c(":---", "---:", "---:")),
  paste("Source: DigiKat official corpus. Groups are defined by platform-specific medians of interactions",
        "and reach, only on platforms that record both measures. Actors need at least twelve posts in the",
        "year. The groups are descriptions, not ratings."))

special_label_en <- c(
  linked_posts = "Posts where religious and economic language meet (raw detector result)",
  core_posts = "Posts with a Catholic social teaching term near an economic term",
  corrected_headline = "Corrected estimate of doctrinal-pair share (%)",
  conf_share_doctrinal_labelled = "Confessional-source share among labelled doctrinal posts (%)",
  n_linked = "Posts where religious language and cost-of-living language meet (raw detector result)",
  n_core = "Posts manually confirmed as domestic cost-of-living discussion",
  peak_n_repricing = "Posts about changed prices of Church services in 2024, the period maximum",
  v2_hicp_repricing_lag_months = "Months between the inflation peak and the reporting peak"
)
special_display_en <- ifelse(grepl("headline|share", special_keys),
                             ar_fmt_num_en(special_numeric, 2), ar_fmt_int_en(special_numeric))
ar_fragment(file.path(AR_TABLES_EN, "table_special.md"),
  ed(`2024` = "What did the study of inflation and Church language find?",
     `2025` = "What did the study of Catholic social teaching and the economy find?"),
  ar_md_table(data.frame(Measure = unname(special_label_en[special_keys]), Value = special_display_en,
                         check.names = FALSE), align = c(":---", "---:")),
  ed(`2024` = paste("Source: generated results of the inflation-salience study. Values cover its full",
                    "2021–2026 period rather than the report year and do not enter annual indicators.",
                    "The first row is the detector result; the second is manually confirmed."),
     `2025` = paste("Source: generated results of the moral-economy study. Values cover the study's full",
                    "period, not the report year, and do not enter annual indicators. The first two rows",
                    "are detector results; the corrected estimate applies sample-validated precision.")))

indicator_name_en <- c(
  "Recorded discussion volume", "Indicative source composition", "Leading institutional actors",
  "Actor distribution by interactions and reach", "Engagement benchmarks", "Theme profile",
  "Tone and conflict", "Exceptional days", "Transmission of the Church voice", "Audience survey"
)
indicator_status_en <- c("published", "indicative", "published", "published without movement",
                         "published", "published", "published", "published", "in preparation",
                         "in preparation")
ar_fragment(file.path(AR_TABLES_EN, "table_indicators.md"),
  "What does this review already measure, and what comes next?",
  ar_md_table(data.frame(Code = indicator_status$id, Indicator = indicator_name_en,
                         Status = indicator_status_en, check.names = FALSE),
              align = c(":---", ":---", ":---")),
  "INDICATORS.md contains each indicator's full definition, comparability rule and change history.")

## English annex profiles -----------------------------------------------------------------------
profile_lines_en <- character()
for (i in seq_len(nrow(profiles))) {
  profile_lines_en <- c(profile_lines_en,
    paste0("### ", profiles$name_hr[i]), "",
    paste0("**", unname(ar_platform_en[profiles$SOURCE_TYPE[i]]), " · ",
           unname(ar_typology_en[profiles$quadrant[i]]), "**"), "",
    paste0("- Posts in ", YEAR, ": **", ar_fmt_int_en(profiles$posts[i]), "**"),
    paste0("- Interactions: **", ar_fmt_int_en(profiles$interactions[i]), "**"),
    paste0("- Interactions per post: **", ar_fmt_num_en(profiles$interactions_per_post[i], 1),
           "**, or ", ar_fmt_num_en(profiles$ratio[i], 2),
           " times the median of its group on the same platform"), "")
}
ar_write_utf8(profile_lines_en, file.path(private_dir, "profiles_en.md"))

cat("English assets generated:", length(list.files(AR_FIGURES_EN, pattern = "[.]png$")),
    "figures and", length(list.files(AR_TABLES_EN, pattern = "[.]md$")), "fragments.\n")
