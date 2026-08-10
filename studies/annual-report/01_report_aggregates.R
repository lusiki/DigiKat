#!/usr/bin/env Rscript
# Stage 1 — the report's own annual aggregates, cut from the official corpus.
#
# This is step 4 of the public runbook in PIPELINE.md: a report-specific, STREAM-AWARE annual
# aggregate. The corpus is opened read-only, once, and nothing outside
# studies/annual-report/output/ is written.

suppressPackageStartupMessages({ library(here); library(dplyr); library(jsonlite) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")
ar_readiness_ok()

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }

cm <- digikat_read_corpus_manifest(here::here("data", "digikat_corpus_manifest.json"))
YEAR <- AR_REPORT_YEAR

sum_num <- function(x) sum(as.numeric(x), na.rm = TRUE)

## --- Read the corpus once, keep only the columns this report measures --------------------------
say("reading the corpus (read-only):", cm$corpus$path)
corpus <- readRDS(here::here(cm$corpus$path))
keep_cols <- c("DATE", "SOURCE_TYPE", "FROM", "URL", "INTERACTIONS", "REACH",
               "dk_era", "data_source")
missing <- setdiff(keep_cols, names(corpus))
if (length(missing)) stop("Corpus is missing expected columns: ", paste(missing, collapse = ", "))
cp <- corpus[, keep_cols]
rm(corpus); invisible(gc())

cp$DATE <- as.Date(cp$DATE)
cp$year <- as.integer(format(cp$DATE, "%Y"))
cp$SOURCE_TYPE <- as.character(cp$SOURCE_TYPE)
cp$FROM <- as.character(cp$FROM)
if (nrow(cp) != cm$corpus$rows) stop("Corpus row count does not match its manifest.")
say("corpus rows:", ar_fmt_int_hr(nrow(cp)))

# Source identity is normalised before anything is ranked: 'www.' and case are not editorial facts.
cp$source_key <- sub("^www[.]", "", tolower(trimws(cp$FROM)))

y <- cp[cp$year == YEAR, , drop = FALSE]
if (!nrow(y)) stop("The reporting year is empty in the corpus.")
say("reporting-year rows:", ar_fmt_int_hr(nrow(y)))

## --- 1. Volume by platform ----------------------------------------------------------------------
platform <- y |>
  group_by(SOURCE_TYPE) |>
  summarise(total_posts = n(),
            total_interactions = sum_num(INTERACTIONS),
            total_reach = sum_num(REACH),
            posts_with_interactions = sum(!is.na(INTERACTIONS) & as.numeric(INTERACTIONS) > 0),
            posts_with_reach = sum(!is.na(REACH) & as.numeric(REACH) > 0),
            .groups = "drop") |>
  mutate(post_share = total_posts / sum(total_posts),
         interaction_share = total_interactions / sum(total_interactions),
         reach_share = total_reach / sum(total_reach),
         interaction_coverage = posts_with_interactions / total_posts,
         reach_coverage = posts_with_reach / total_posts,
         platform_hr = unname(ar_platform_hr[SOURCE_TYPE])) |>
  arrange(desc(total_posts)) |>
  as.data.frame()
ar_write_csv(platform, file.path(AR_OUT, "volume_platform.csv"))

## --- 2. Monthly rhythm ---------------------------------------------------------------------------
monthly <- y |>
  mutate(month = as.Date(format(DATE, "%Y-%m-01"))) |>
  group_by(month, SOURCE_TYPE) |>
  summarise(total_posts = n(), .groups = "drop") |>
  mutate(platform_hr = unname(ar_platform_hr[SOURCE_TYPE]),
         month = format(month, "%Y-%m-%d")) |>
  as.data.frame()
ar_write_csv(monthly, file.path(AR_OUT, "volume_monthly.csv"))

## --- 3. Daily rhythm over the COMPLETE calendar --------------------------------------------------
# Every day of the year exists, including days with no recorded post. Standardising over a partial
# calendar would inflate every z-score.
calendar <- data.frame(date = seq(as.Date(sprintf("%d-01-01", YEAR)),
                                  as.Date(sprintf("%d-12-31", YEAR)), by = "day"))
daily <- y |> count(DATE, name = "posts") |> rename(date = DATE)
daily <- calendar |>
  left_join(daily, by = "date") |>
  mutate(posts = ifelse(is.na(posts), 0L, posts))
# A run of days with no post at all on ANY platform is a collection interruption, not silence. It
# has to be found before anything is standardised: left in, fourteen zeros drag the yearly mean down
# and inflate every z-score above it.
runs <- rle(daily$posts == 0)
gap_end <- cumsum(runs$lengths)
gap_start <- gap_end - runs$lengths + 1L
gaps <- data.frame(
  start = daily$date[gap_start][runs$values & runs$lengths >= 2L],
  end = daily$date[gap_end][runs$values & runs$lengths >= 2L],
  days = runs$lengths[runs$values & runs$lengths >= 2L],
  stringsAsFactors = FALSE
)
daily$collected <- TRUE
if (nrow(gaps)) {
  for (i in seq_len(nrow(gaps))) {
    daily$collected[daily$date >= gaps$start[i] & daily$date <= gaps$end[i]] <- FALSE
  }
}
observed <- daily[daily$collected, ]
daily$z <- (daily$posts - mean(observed$posts)) / stats::sd(observed$posts)
daily$z[!daily$collected] <- NA_real_
daily$dow <- format(daily$date, "%u")
ar_write_csv(transform(daily, date = format(date, "%Y-%m-%d")), file.path(AR_OUT, "volume_daily.csv"))

# What the interruption plausibly cost: the median day of the four weeks on either side of it.
gap_days <- sum(!daily$collected)
neighbour_window <- 14L
neighbours <- unlist(lapply(seq_len(nrow(gaps)), function(i) {
  before <- daily$date >= gaps$start[i] - neighbour_window & daily$date < gaps$start[i]
  after <- daily$date > gaps$end[i] & daily$date <= gaps$end[i] + neighbour_window
  daily$posts[(before | after) & daily$collected]
}))
coverage <- data.frame(
  calendar_days = nrow(daily),
  collected_days = sum(daily$collected),
  gap_days = gap_days,
  gap_spans = if (nrow(gaps)) paste(sprintf("%s..%s", gaps$start, gaps$end), collapse = "; ") else "",
  median_collected_day = if (length(neighbours)) stats::median(neighbours) else NA_real_,
  estimated_missing_posts = if (length(neighbours)) round(gap_days * stats::median(neighbours)) else NA_real_,
  stringsAsFactors = FALSE
)
ar_write_csv(coverage, file.path(AR_OUT, "coverage.csv"))
ar_write_csv(gaps, file.path(AR_OUT, "coverage_gaps.csv"))

# Peak rule, fixed before inspection: a day is a candidate peak at z >= 3. Days no more than two
# apart belong to the same attention arc, because one event produces several days.
PEAK_Z <- 3
peaks <- daily[daily$collected & daily$z >= PEAK_Z, , drop = FALSE]
peaks <- peaks[order(peaks$date), ]
if (nrow(peaks)) {
  gap <- c(0, as.numeric(diff(peaks$date)))
  peaks$arc <- cumsum(gap > 2) + 1L
} else {
  peaks$arc <- integer(0)
}
ar_write_csv(transform(peaks, date = format(date, "%Y-%m-%d")), file.path(AR_OUT, "peaks.csv"))

# NB: never name an aggregate the same as the column it consumes — inside one summarise() a later
# expression sees the column created earlier in the same call.
arcs <- peaks |>
  group_by(arc) |>
  summarise(start = min(date), end = max(date), days = n(),
            peak_posts = max(posts), peak_day = date[which.max(posts)], peak_z = max(z),
            arc_posts = sum(posts), .groups = "drop") |>
  arrange(desc(peak_posts)) |>
  as.data.frame()
ar_write_csv(transform(arcs, start = format(start, "%Y-%m-%d"), end = format(end, "%Y-%m-%d"),
                       peak_day = format(peak_day, "%Y-%m-%d")),
             file.path(AR_OUT, "event_arcs.csv"))

## --- 4. The movement this edition can honestly publish, inside one collection stream --------------
# The collection method changed at the 2024 seam, so a comparison across it is confounded. What is
# comparable depends on where the reporting year sits relative to the seam, and AR_STREAM_MODE says
# which of the two shapes applies. Both produce the same columns, so the figure and the table do not
# have to know which edition they are drawing.
#
#  yoy_h2               the baseline year's second half is already inside the stream, so the second
#                       halves of the two years are compared directly, in posts. The interruption
#                       falls inside one of them, so the same calendar days are removed from BOTH.
#                       Comparing 170 collected days against 184 would have read as a decline that
#                       the collection, not the discourse, produced.
#  within_year_quarters the stream begins during the reporting year itself, so no year-over-year
#                       answer exists at all. The third and fourth quarters of the reporting year are
#                       compared instead, in posts PER COLLECTED DAY, because an interruption inside
#                       one quarter would otherwise masquerade as a fall in attention.
excluded_md <- if (nrow(gaps)) {
  unlist(lapply(seq_len(nrow(gaps)), function(i)
    format(seq(as.Date(gaps$start[i]), as.Date(gaps$end[i]), by = "day"), "%m-%d")))
} else character(0)

collected_days_between <- function(from, to) {
  sum(daily$collected & daily$date >= from & daily$date <= to)
}

if (AR_STREAM_MODE == "yoy_h2") {
  window <- cp[cp$dk_era == AR_STREAM_ERA &
                 format(cp$DATE, "%m") %in% sprintf("%02d", 7:12) &
                 cp$year %in% c(AR_BASELINE_YEAR, YEAR) &
                 !format(cp$DATE, "%m-%d") %in% excluded_md, , drop = FALSE]
  window$period <- ifelse(window$year == YEAR, "report", "base")
  base_label <- sprintf("2. polovica %d.", AR_BASELINE_YEAR)
  report_label <- sprintf("2. polovica %d.", YEAR)
  # Both halves were cut to the same calendar days, so the denominators are equal by construction and
  # the published unit stays the plain post count.
  base_days <- report_days <- length(unique(window$DATE[window$period == "report"]))
  stream_unit <- "objave"
} else {
  window <- cp[cp$dk_era == AR_STREAM_ERA & cp$year == YEAR &
                 format(cp$DATE, "%m") %in% sprintf("%02d", 7:12), , drop = FALSE]
  window$period <- ifelse(format(window$DATE, "%m") %in% sprintf("%02d", 10:12), "report", "base")
  base_label <- sprintf("3. tromjesečje %d.", YEAR)
  report_label <- sprintf("4. tromjesečje %d.", YEAR)
  base_days <- collected_days_between(as.Date(sprintf("%d-07-01", YEAR)), as.Date(sprintf("%d-09-30", YEAR)))
  report_days <- collected_days_between(as.Date(sprintf("%d-10-01", YEAR)), as.Date(sprintf("%d-12-31", YEAR)))
  stream_unit <- "objave po danu s prikupljanjem"
}
if (!nrow(window)) stop("The stream comparison window is empty.", call. = FALSE)
if (base_days <= 0 || report_days <= 0) stop("A stream comparison period has no collected day.", call. = FALSE)

counts <- window |>
  group_by(period, SOURCE_TYPE) |>
  summarise(posts = n(), sources = n_distinct(source_key), .groups = "drop") |>
  as.data.frame()
platforms_seen <- sort(unique(counts$SOURCE_TYPE))
pick <- function(period, column) {
  idx <- match(platforms_seen, counts$SOURCE_TYPE[counts$period == period])
  out <- counts[[column]][counts$period == period][idx]
  ifelse(is.na(out), 0, out)
}
stream <- data.frame(
  SOURCE_TYPE = platforms_seen,
  base_posts = pick("base", "posts"),
  report_posts = pick("report", "posts"),
  base_sources = pick("base", "sources"),
  report_sources = pick("report", "sources"),
  stringsAsFactors = FALSE
)
stream$base_days <- base_days
stream$report_days <- report_days
# The published quantity: identical to the post count when the two periods span the same number of
# collected days, and the only honest form when they do not.
stream$base_value <- stream$base_posts / (if (stream_unit == "objave") 1 else base_days)
stream$report_value <- stream$report_posts / (if (stream_unit == "objave") 1 else report_days)
stream$change_pct <- ifelse(stream$base_value > 0,
                            100 * (stream$report_value - stream$base_value) / stream$base_value, NA_real_)
# A jump in recorded volume can mean more discourse or more sources watched. The count of distinct
# sources per period separates the two readings, so the report never has to guess.
stream$sources_change_pct <- ifelse(stream$base_sources > 0,
                                    100 * (stream$report_sources - stream$base_sources) /
                                      stream$base_sources, NA_real_)
stream$platform_hr <- unname(ar_platform_hr[stream$SOURCE_TYPE])
stream$mode <- AR_STREAM_MODE
stream$unit <- stream_unit
stream$base_label <- base_label
stream$report_label <- report_label
stream <- stream[order(-stream$report_value), ]
ar_write_csv(stream, file.path(AR_OUT, "stream_halfyear.csv"))

## --- 5. Year series with the seam marked ----------------------------------------------------------
year_series <- cp |>
  filter(year >= 2021, year <= YEAR) |>
  group_by(year, dk_era) |>
  summarise(posts = n(), .groups = "drop") |>
  as.data.frame()
ar_write_csv(year_series, file.path(AR_OUT, "year_series.csv"))

## --- 6. Sources: concentration, editorial labels, and the named league ---------------------------
labels <- read.csv(here::here("resources", "dictionaries", "source_labels.csv"),
                   fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, colClasses = "character")
for (nm in names(labels)) labels[[nm]] <- enc2utf8(ifelse(is.na(labels[[nm]]), "", trimws(labels[[nm]])))
labels <- labels[nzchar(labels$from), , drop = FALSE]
labels$key <- sub("^www[.]", "", tolower(labels$from))
dups <- labels$key[duplicated(labels$key)]
if (length(dups)) {
  for (k in unique(dups)) {
    z <- unique(labels[labels$key == k, c("kind", "label", "publish")])
    if (nrow(z) > 1L) stop("Conflicting sidecar rows for source: ", k)
  }
  labels <- labels[!duplicated(labels$key), , drop = FALSE]
}

src <- y |>
  group_by(source_key, SOURCE_TYPE) |>
  summarise(posts = n(),
            interactions = sum_num(INTERACTIONS),
            reach = sum_num(REACH),
            display_name = FROM[1],
            .groups = "drop") |>
  as.data.frame()
idx <- match(src$source_key, labels$key)
for (nm in c("entity", "kind", "label", "publish", "status")) src[[nm]] <- labels[[nm]][idx]
src$label[is.na(src$label) | !src$label %in% c("confessional", "secular", "other")] <- "unclassified"
src$classified <- src$label %in% c("confessional", "secular")
ar_write_csv(src, file.path(AR_PRIVATE, "sources_private.csv"))

# Concentration answers "who leads" without naming anyone.
by_source <- src |> group_by(source_key) |> summarise(posts = sum(posts), .groups = "drop") |>
  arrange(desc(posts))
concentration <- data.frame(
  distinct_sources = nrow(by_source),
  top1_share = 100 * by_source$posts[1] / sum(by_source$posts),
  top10_share = 100 * sum(head(by_source$posts, 10)) / sum(by_source$posts),
  top50_share = 100 * sum(head(by_source$posts, 50)) / sum(by_source$posts),
  sources_to_half = which(cumsum(by_source$posts) >= 0.5 * sum(by_source$posts))[1],
  stringsAsFactors = FALSE
)
ar_write_csv(concentration, file.path(AR_OUT, "concentration.csv"))

label_rows <- do.call(rbind, lapply(c("confessional", "secular", "other", "unclassified"), function(lab) {
  z <- src[src$label %in% lab, , drop = FALSE]
  data.frame(label = lab,
             label_hr = c(confessional = "Konfesionalni izvori", secular = "Sekularni izvori",
                          other = "Ostalo (označeno, ali ni jedno ni drugo)",
                          unclassified = "Neoznačeni izvori")[[lab]],
             sources = length(unique(z$source_key)),
             posts = sum(z$posts),
             interactions = sum(z$interactions),
             stringsAsFactors = FALSE)
}))
classified_posts <- sum(label_rows$posts[label_rows$label %in% c("confessional", "secular")])
label_rows$share_of_all <- label_rows$posts / sum(label_rows$posts)
label_rows$share_of_classified <- ifelse(label_rows$label %in% c("confessional", "secular"),
                                         label_rows$posts / classified_posts, NA_real_)
ar_write_csv(label_rows, file.path(AR_OUT, "source_labels.csv"))

# The named league: institutional outlets the PI sidecar clears for publication, above the
# small-cell floor. Individuals are never named, and an unratified source is never named.
league <- src |>
  filter(kind %in% "institution", publish %in% "yes", posts >= AR_SMALL_CELL) |>
  group_by(source_key) |>
  summarise(display_name = display_name[which.max(posts)],
            entity = entity[1], label = label[1],
            posts = sum(posts), interactions = sum(interactions), reach = sum(reach),
            platforms = paste(sort(unique(SOURCE_TYPE)), collapse = "+"),
            .groups = "drop") |>
  arrange(desc(posts)) |>
  mutate(rank = row_number(),
         share_of_year = 100 * posts / nrow(y),
         name_hr = ifelse(nzchar(entity), entity, display_name)) |>
  as.data.frame()
ar_write_csv(league, file.path(AR_OUT, "league_sources.csv"))

## --- 7. Actor panel, quadrants and engagement benchmarks -----------------------------------------
# Eligibility is fixed before inspection: an actor must publish at least one post a month on that
# platform during the reporting year.
ACTOR_MIN_POSTS <- 12L
actors <- src |>
  filter(posts >= ACTOR_MIN_POSTS) |>
  mutate(interactions_per_post = ifelse(posts > 0, interactions / posts, NA_real_)) |>
  as.data.frame()

# Only platforms that actually capture a metric may be scored on it.
COVERAGE_FLOOR <- 0.5
metric_cover <- platform[, c("SOURCE_TYPE", "interaction_coverage", "reach_coverage")]
actors <- actors |> left_join(metric_cover, by = "SOURCE_TYPE")
scored <- actors |> filter(interaction_coverage >= COVERAGE_FLOOR, reach_coverage >= COVERAGE_FLOOR)

quadrant <- scored |>
  group_by(SOURCE_TYPE) |>
  mutate(med_i = stats::median(interactions, na.rm = TRUE),
         med_r = stats::median(reach, na.rm = TRUE),
         quadrant = case_when(
           interactions >= med_i & reach >= med_r ~ "visok_visok",
           interactions >= med_i & reach < med_r ~ "visok_nizak",
           interactions < med_i & reach >= med_r ~ "nizak_visok",
           TRUE ~ "nizak_nizak")) |>
  ungroup() |>
  as.data.frame()
ar_write_csv(quadrant[, c("source_key", "SOURCE_TYPE", "posts", "interactions", "reach",
                          "interactions_per_post", "quadrant", "label", "kind", "publish")],
             file.path(AR_PRIVATE, "actor_panel_private.csv"))

typology <- quadrant |>
  count(quadrant, name = "actors") |>
  mutate(quadrant_hr = unname(ar_typology_hr[quadrant]),
         share = actors / sum(actors)) |>
  as.data.frame()
typology <- typology[match(names(ar_typology_hr), typology$quadrant), ]
typology$quadrant_hr <- unname(ar_typology_hr)
typology$actors[is.na(typology$actors)] <- 0L
ar_write_csv(typology, file.path(AR_OUT, "actor_typology.csv"))

benchmarks <- quadrant |>
  group_by(SOURCE_TYPE, quadrant) |>
  summarise(actors = n(),
            median_interactions_per_post = stats::median(interactions_per_post, na.rm = TRUE),
            .groups = "drop") |>
  mutate(platform_hr = unname(ar_platform_hr[SOURCE_TYPE]),
         quadrant_hr = unname(ar_typology_hr[quadrant])) |>
  as.data.frame()
ar_write_csv(benchmarks, file.path(AR_OUT, "engagement_benchmarks.csv"))

platform_engagement <- quadrant |>
  group_by(SOURCE_TYPE) |>
  summarise(actors = n(),
            median_interactions_per_post = stats::median(interactions_per_post, na.rm = TRUE),
            .groups = "drop") |>
  mutate(platform_hr = unname(ar_platform_hr[SOURCE_TYPE])) |>
  arrange(desc(median_interactions_per_post)) |>
  as.data.frame()
ar_write_csv(platform_engagement, file.path(AR_OUT, "engagement_platform.csv"))

## --- 8. Rotating special chapter -----------------------------------------------------------------
# The chapter rotates, so which study and which of its scalars this edition quotes come from the
# registry in report_lib.R rather than from a path typed here. The study's own generated registry is
# read as-is: a completed analysis is never recomputed to fit a report.
special_spec <- ar_special_chapter()
rsp_path <- here::here(special_spec$registry)
if (!file.exists(rsp_path)) {
  stop("Missing the special chapter's derived-scalar registry: ", special_spec$registry, call. = FALSE)
}
rsp <- read.csv(rsp_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
key_col <- special_spec$name_column
if (!key_col %in% names(rsp)) stop("Special-chapter registry has no '", key_col, "' column.", call. = FALSE)
special <- rsp[match(special_spec$keys, rsp[[key_col]]), , drop = FALSE]
if (anyNA(special[[key_col]])) {
  stop("A required special-chapter scalar is missing: ",
       paste(setdiff(special_spec$keys, rsp[[key_col]]), collapse = ", "), call. = FALSE)
}
special$study <- special_spec$study
ar_write_csv(special, file.path(AR_OUT, "special_chapter.csv"))
say("special chapter:", special_spec$study, "-", nrow(special), "scalars")

## --- 9. Reconciliation gates ---------------------------------------------------------------------
processed_platform <- as.data.frame(readRDS(here::here("data", "processed", "platform_summary.rds")))
pp <- processed_platform[processed_platform$year == YEAR, ]
stopifnot(sum(platform$total_posts) == nrow(y))
stopifnot(sum(as.numeric(monthly$total_posts)) == nrow(y))
stopifnot(sum(daily$posts) == nrow(y))
stopifnot(sum(src$posts) == nrow(y))
stopifnot(sum(label_rows$posts) == nrow(y))
stopifnot(nrow(daily) == AR_CALENDAR_DAYS)
# The report's own cut must reproduce the tracked aggregate exactly.
stopifnot(sum(pp$total_posts) == nrow(y))
recon <- platform |>
  select(SOURCE_TYPE, total_posts) |>
  left_join(pp[, c("SOURCE_TYPE", "total_posts")], by = "SOURCE_TYPE", suffix = c("_report", "_processed"))
stopifnot(all(recon$total_posts_report == recon$total_posts_processed))

reconciliation <- data.frame(
  check = c("platform", "monthly", "daily", "sources", "labels", "processed_platform_summary"),
  report_posts = c(sum(platform$total_posts), sum(as.numeric(monthly$total_posts)), sum(daily$posts),
                   sum(src$posts), sum(label_rows$posts), sum(recon$total_posts_report)),
  reference_posts = rep(nrow(y), 6L),
  stringsAsFactors = FALSE
)
ar_write_csv(reconciliation, file.path(AR_OUT, "reconciliation.csv"))

say("aggregates complete")
cat("  reporting-year posts      :", ar_fmt_int_hr(nrow(y)), "\n")
cat("  platforms                 :", nrow(platform), "\n")
cat("  distinct sources          :", ar_fmt_int_hr(concentration$distinct_sources), "\n")
cat("  classified coverage       :", ar_fmt_pct_hr(100 * classified_posts / nrow(y)), "\n")
cat("  named institutional league:", nrow(league), "outlets\n")
cat("  eligible actors           :", nrow(actors), "; scored on both metrics:", nrow(quadrant), "\n")
cat("  candidate peak days       :", nrow(peaks), "in", nrow(arcs), "arcs\n")
