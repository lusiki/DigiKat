#!/usr/bin/env Rscript

# Reproducible analysis behind the companion report
# "Kada se govori o katoličanstvu — i tko tada govori?"
#
# This report deliberately reuses the flagship report's canonical source
# classifier and event detector. It does not create a second actor taxonomy.

options(stringsAsFactors = FALSE, encoding = "UTF-8", width = 160)
Sys.setenv(TZ = "Europe/Zagreb")

suppressPackageStartupMessages({
  library(data.table)
})

source(file.path("R", "lib", "digikat_utils.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_paths.R"), encoding = "UTF-8")
source(file.path("explorations", "_okvir_engine", "okvir_lib.R"), encoding = "UTF-8")

analysis_dir <- file.path("explorations", "glas-crkve-prototype")
output_dir <- file.path(analysis_dir, "output")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

month_hr <- c(
  "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
  "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"
)

format_hr_date <- function(x) {
  x <- as.Date(x)
  paste0(
    as.integer(format(x, "%d")), ". ",
    month_hr[as.integer(format(x, "%m"))], " ",
    format(x, "%Y"), "."
  )
}

actor_value <- function(dt, key, column) {
  value <- dt[actor_group == key, get(column)]
  if (length(value)) value[[1L]] else 0
}

actor_share_object <- function(dt) {
  total <- dt[, sum(posts)]
  values <- vapply(actor_levels, function(key) {
    if (total > 0) 100 * actor_value(dt, key, "posts") / total else 0
  }, numeric(1))
  as.list(stats::setNames(values, actor_levels))
}

say("Reading the DigiKat corpus and applying the canonical flagship classifier")
corpus_path <- digikat_corpus_path()
corpus_raw <- readRDS(corpus_path)
required <- c("DATE", "FROM", "SOURCE_TYPE", "INTERACTIONS")
missing_required <- setdiff(required, names(corpus_raw))
if (length(missing_required)) {
  stop("Corpus lacks: ", paste(missing_required, collapse = ", "), call. = FALSE)
}

corpus <- as.data.table(corpus_raw[, required])
rm(corpus_raw)
invisible(gc())

corpus[, DATE := as.Date(DATE)]
classification <- classify_actor_details(corpus$FROM)
corpus[, `:=`(
  actor_group = classification$actor_group,
  actor_rule = classification$actor_rule,
  platform_group = platform_group(SOURCE_TYPE),
  interactions = safe_numeric(INTERACTIONS)
)]
rm(classification)
corpus[is.na(interactions) | interactions < 0, interactions := 0]

if (any(!corpus$actor_group %in% actor_levels)) {
  stop("Canonical classifier produced an unsupported actor group.", call. = FALSE)
}

actor_totals <- corpus[, .(
  posts = .N,
  interactions = sum(interactions)
), by = actor_group]
actor_totals <- actor_totals[match(actor_levels, actor_group)]
actor_totals[, post_share := 100 * posts / sum(posts)]

# A companion report may not silently redefine the flagship groups. If the
# flagship aggregate is present, require an exact match before publishing.
flagship_totals_path <- file.path(
  "explorations", "okvir-katolicanstva-prototype", "output", "actor_totals.csv"
)
canonical_match <- FALSE
if (file.exists(flagship_totals_path)) {
  flagship_totals <- fread(flagship_totals_path, encoding = "UTF-8")
  flagship_totals <- flagship_totals[match(actor_levels, actor_group)]
  canonical_match <- identical(as.character(flagship_totals$actor_group), actor_levels) &&
    identical(as.integer(flagship_totals$posts), as.integer(actor_totals$posts)) &&
    isTRUE(all.equal(as.numeric(flagship_totals$interactions), as.numeric(actor_totals$interactions)))
  if (!canonical_match) {
    stop(
      "Actor totals differ from the flagship report. Rebuild the flagship before this companion report.",
      call. = FALSE
    )
  }
} else {
  stop("Flagship actor totals are missing; rebuild the flagship report first.", call. = FALSE)
}

fwrite(actor_totals, file.path(output_dir, "actor_totals.csv"), bom = TRUE)

say("Reusing the flagship event detector")
years <- 2021:2026
event_layer <- build_daily_arcs(corpus, years = years)
date_min <- event_layer$date_min
date_max <- event_layer$date_max
arcs <- event_layer$arcs
events <- event_layer$events

named_arcs <- arcs[label != "Događaj nije prepoznat"][order(-peak_z)]
top_named_arcs <- named_arcs[seq_len(min(8L, .N))]
if (!nrow(top_named_arcs)) stop("No named event peaks were detected.", call. = FALSE)

event_actor_daily <- corpus[, .(posts = .N), by = .(DATE, actor_group)]

baseline_mix <- copy(actor_totals[, .(actor_group, posts)])
event_composition <- list(list(
  key = "baseline",
  label = "Sve objave",
  period = "2021. – 11. lipnja 2026.",
  type = "baseline",
  startDate = as.character(date_min),
  endDate = as.character(date_max),
  peakDate = NULL,
  peakZ = NULL,
  posts = baseline_mix[, sum(posts)],
  shares = actor_share_object(baseline_mix)
))

event_mix_rows <- list()
for (i in seq_len(nrow(top_named_arcs))) {
  arc <- top_named_arcs[i]
  mix <- event_actor_daily[
    DATE >= arc$start_date & DATE <= arc$end_date,
    .(posts = sum(posts)),
    by = actor_group
  ]
  mix <- data.table(actor_group = actor_levels)[mix, on = "actor_group"]
  mix[is.na(posts), posts := 0L]
  mix[, `:=`(
    event_key = paste0("event-", i),
    event_label = arc$label,
    period = format_hr_date(arc$peak_date),
    event_type = arc$type,
    peak_z = arc$peak_z
  )]
  event_mix_rows[[i]] <- copy(mix)
  event_composition[[length(event_composition) + 1L]] <- list(
    key = paste0("event-", i),
    label = arc$label,
    period = format_hr_date(arc$peak_date),
    type = arc$type,
    startDate = as.character(arc$start_date),
    endDate = as.character(arc$end_date),
    peakDate = as.character(arc$peak_date),
    peakZ = arc$peak_z,
    posts = mix[, sum(posts)],
    shares = actor_share_object(mix)
  )
}
event_mix_table <- rbindlist(event_mix_rows)
fwrite(event_mix_table, file.path(output_dir, "event_composition.csv"), bom = TRUE)

say("Estimating the liturgical rhythm for the same four source groups")
liturgical_events <- events[type == "liturgical" & date >= date_min & date <= date_max]
papal_dates <- events[type == "papal" & date >= date_min & date <= date_max, date]
if (length(papal_dates)) {
  # Easter 2025 overlaps the death of Pope Francis. Excluding that window keeps
  # the repeated liturgical estimate from absorbing an exceptional papal event.
  liturgical_events <- liturgical_events[
    !vapply(date, function(x) any(abs(as.integer(x - papal_dates)) <= 4L), logical(1))
  ]
}
liturgical_window_dates <- unique(as.Date(
  unlist(lapply(liturgical_events$date, function(x) x + (-2L:2L))),
  origin = "1970-01-01"
))

valid_dates <- event_layer$daily[collected == TRUE & date >= date_min & date <= date_max, unique(date)]
platform_levels <- c("web", "facebook", "video", "other")
daily_counts <- corpus[, .(posts = .N), by = .(
  date = DATE, actor_group, platform_group
)]
panel <- CJ(
  date = valid_dates,
  actor_group = actor_levels,
  platform_group = platform_levels,
  unique = TRUE
)
panel <- daily_counts[panel, on = c("date", "actor_group", "platform_group")]
panel[is.na(posts), posts := 0L]
panel[, `:=`(
  liturgical_window = date %in% liturgical_window_dates,
  weekday = as.integer(format(date, "%u")),
  halfyear = period_id(date),
  week_block = as.integer(as.integer(date - min(date)) %/% 7L)
)]

available_platforms <- corpus[, .N, by = .(actor_group, platform_group)]
panel <- available_platforms[panel, on = c("actor_group", "platform_group"), nomatch = 0L]

fit_rhythm <- function(dt, seed, bootstrap_reps = 120L) {
  model_formula <- log1p(posts) ~ liturgical_window + factor(weekday) +
    factor(halfyear) + factor(platform_group)
  fit <- lm(model_formula, data = dt)
  coefficient <- unname(coef(fit)["liturgical_windowTRUE"])
  if (!is.finite(coefficient)) {
    return(list(estimate = NA_real_, lower = NA_real_, upper = NA_real_))
  }

  set.seed(seed)
  blocks <- unique(dt$week_block)
  bootstrap_values <- replicate(bootstrap_reps, {
    sampled_blocks <- sample(blocks, length(blocks), replace = TRUE)
    bootstrap_data <- rbindlist(lapply(sampled_blocks, function(block) dt[week_block == block]))
    bootstrap_fit <- try(lm(model_formula, data = bootstrap_data), silent = TRUE)
    if (inherits(bootstrap_fit, "try-error")) return(NA_real_)
    unname(coef(bootstrap_fit)["liturgical_windowTRUE"])
  })
  bootstrap_values <- bootstrap_values[is.finite(bootstrap_values)]
  if (length(bootstrap_values) < bootstrap_reps * 0.8) {
    stop("Too few valid rhythm bootstrap estimates.", call. = FALSE)
  }
  interval <- quantile(bootstrap_values, c(0.025, 0.975), na.rm = TRUE)
  list(
    estimate = 100 * (exp(coefficient) - 1),
    lower = 100 * (exp(interval[[1L]]) - 1),
    upper = 100 * (exp(interval[[2L]]) - 1)
  )
}

rhythm_effects <- rbindlist(lapply(seq_along(actor_levels), function(i) {
  key <- actor_levels[[i]]
  estimate <- fit_rhythm(panel[actor_group == key], seed = 20260819L + i)
  data.table(
    actor_group = key,
    estimate = estimate$estimate,
    lower = estimate$lower,
    upper = estimate$upper,
    status = if (estimate$lower > 0) "higher" else if (estimate$upper < 0) "lower" else "unclear"
  )
}))
fwrite(rhythm_effects, file.path(output_dir, "rhythm_effects.csv"), bom = TRUE)

baseline_shares <- vapply(actor_levels, function(key) {
  100 * actor_value(actor_totals, key, "posts") / actor_totals[, sum(posts)]
}, numeric(1))
deviations <- copy(event_mix_table)
deviations[, event_total := sum(posts), by = event_key]
deviations[, share := 100 * posts / event_total]
deviations[, baseline_share := baseline_shares[actor_group]]
deviations[, difference := share - baseline_share]
largest_shift <- deviations[which.max(abs(difference))]

largest_peak <- top_named_arcs[which.max(peak_z)]
most_responsive <- rhythm_effects[which.max(estimate)]

actor_totals_list <- lapply(actor_levels, function(key) {
  row <- actor_totals[actor_group == key]
  definition <- actors[[match(key, actor_levels)]]
  list(
    key = key,
    label = definition$label,
    short = definition$short,
    color = definition$color,
    posts = row$posts,
    interactions = row$interactions,
    postShare = row$post_share
  )
})

rhythm_list <- lapply(seq_len(nrow(rhythm_effects)), function(i) {
  row <- rhythm_effects[i]
  list(
    actor = row$actor_group,
    estimate = row$estimate,
    lower = row$lower,
    upper = row$upper,
    status = row$status
  )
})

result <- list(
  meta = list(
    status = "real_companion_analysis",
    generatedUtc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    corpusPath = gsub("\\\\", "/", corpus_path),
    corpusRows = nrow(corpus),
    dateMin = as.character(date_min),
    dateMax = as.character(date_max),
    sourceClassifier = "canonical flagship classifier from explorations/_okvir_engine/okvir_lib.R",
    canonicalActorMatch = canonical_match,
    eventDetector = "shared flagship daily-arc detector; z > 3 within year",
    rhythmModel = "log1p daily posts with weekday, half-year and platform controls; week-block bootstrap",
    rhythmWindowDays = 2L,
    rhythmBootstrapReps = 120L
  ),
  scope = paste0("Objave od 2021. do ", format_hr_date(date_max), " · istraživački korpus projekta DigiKat"),
  actors = actors,
  actorTotals = actor_totals_list,
  eventTypes = list(
    baseline = list(label = "Sve objave", color = "#7d878c"),
    liturgical = list(label = "Liturgijski događaj", color = "#2f8f6b"),
    papal = list(label = "Papinski događaj", color = "#0f4c5c")
  ),
  eventComposition = event_composition,
  rhythmEffects = rhythm_list,
  findings = list(
    namedPeakCount = nrow(named_arcs),
    displayedPeakCount = nrow(top_named_arcs),
    largestPeak = list(
      label = largest_peak$label,
      date = as.character(largest_peak$peak_date),
      period = format_hr_date(largest_peak$peak_date),
      posts = largest_peak$peak_posts,
      amplitude = largest_peak$peak_z
    ),
    largestCompositionShift = list(
      event = largest_shift$event_label,
      period = largest_shift$period,
      actor = largest_shift$actor_group,
      percentagePoints = largest_shift$difference
    ),
    mostResponsiveActor = most_responsive$actor_group,
    mostResponsiveEstimate = most_responsive$estimate,
    mostResponsiveLow = most_responsive$lower,
    mostResponsiveHigh = most_responsive$upper,
    liturgicalEventsUsed = nrow(liturgical_events),
    liturgicalWindowDays = uniqueN(panel[liturgical_window == TRUE, date])
  ),
  caveats = c(
    "Skupine izvora, njihov redoslijed i boje preuzeti su bez promjene iz glavnog izvještaja.",
    "Vrh označava neuobičajeno velik broj objava unutar pojedine godine; ne dokazuje da je imenovani događaj uzrokovao svaku objavu.",
    "Procjena liturgijskoga ritma uspoređuje prozor od dva dana prije do dva dana poslije ponavljajućih blagdana s drugim prikupljenim danima.",
    "Uskrs 2025. izostavljen je iz procjene liturgijskoga ritma jer se njegov prozor preklapa sa smrću pape Franje.",
    "Reakcije publike ostaju u glavnom izvještaju jer se ne mogu jednostavno usporediti među platformama i događajima."
  )
)

json <- jsonlite::toJSON(
  result,
  auto_unbox = TRUE,
  dataframe = "rows",
  na = "null",
  null = "null",
  digits = 15,
  pretty = FALSE
)
writeLines(
  c('"use strict";', paste0("window.ANALYSIS_RESULTS = ", json, ";")),
  file.path(output_dir, "analysis-data.js"),
  useBytes = TRUE
)

summary_lines <- c(
  "KADA SE GOVORI O KATOLIČANSTVU — ANALYSIS RUN",
  paste("Generated UTC:", result$meta$generatedUtc),
  paste("Corpus rows:", formatC(result$meta$corpusRows, format = "d", big.mark = ".", decimal.mark = ",")),
  paste("Canonical actor totals match flagship:", canonical_match),
  paste("Named event peaks:", nrow(named_arcs)),
  paste("Displayed event peaks:", nrow(top_named_arcs)),
  paste("Largest named peak:", largest_peak$label, "—", format_hr_date(largest_peak$peak_date)),
  paste("Repeated liturgical events in rhythm model:", nrow(liturgical_events)),
  paste("Most responsive group:", actor_labels[[most_responsive$actor_group]]),
  paste0(
    "Estimated liturgical-window change: ",
    format(round(most_responsive$estimate, 1), decimal.mark = ","), "% [",
    format(round(most_responsive$lower, 1), decimal.mark = ","), "; ",
    format(round(most_responsive$upper, 1), decimal.mark = ","), "]"
  )
)
writeLines(summary_lines, file.path(output_dir, "analysis-summary.txt"), useBytes = TRUE)

stopifnot(
  canonical_match,
  actor_totals[, sum(posts)] == nrow(corpus),
  length(result$actors) == 4L,
  length(result$eventComposition) == nrow(top_named_arcs) + 1L,
  nrow(rhythm_effects) == 4L,
  file.info(file.path(output_dir, "analysis-data.js"))$size > 5000
)

say("Companion analysis complete")
