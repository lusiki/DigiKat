# Shared, date-keyed registry for recurring calendar events and reviewed event names.
#
# The annual-report chain and source-level products both read this file. A date in the corpus shows
# when attention moved; the label remains an editorially reviewed description rather than a causal
# claim. `moj_medij` marks the compact set used in outlet profiles.

DIGIKAT_EVENT_REGISTRY <- data.frame(
  id = c(
    "easter-2024", "assumption-2024", "all-saints-2024", "christmas-eve-2024",
    "christmas-2024", "easter-2025", "pope-death-2025", "pope-funeral-2025",
    "assumption-2025", "all-saints-2025", "christmas-2025"
  ),
  date = as.Date(c(
    "2024-03-31", "2024-08-15", "2024-11-01", "2024-12-24", "2024-12-25",
    "2025-04-20", "2025-04-21", "2025-04-26", "2025-08-15", "2025-11-01",
    "2025-12-25"
  )),
  label_hr = c(
    "Uskrs", "Velika Gospa", "Svi sveti", "Badnjak", "Božić", "Uskrs",
    "Smrt pape Franje", "Sprovod pape Franje", "Velika Gospa", "Svi sveti", "Božić"
  ),
  label_en = c(
    "Easter", "Assumption of Mary", "All Saints' Day", "Christmas Eve", "Christmas Day",
    "Easter", "Death of Pope Francis", "Funeral of Pope Francis", "Assumption of Mary",
    "All Saints' Day", "Christmas Day"
  ),
  moj_medij = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

digikat_calendar_events <- function(years = NULL, moj_medij_only = FALSE) {
  out <- DIGIKAT_EVENT_REGISTRY
  if (isTRUE(moj_medij_only)) out <- out[out$moj_medij, , drop = FALSE]
  if (!is.null(years)) {
    out <- out[as.integer(format(out$date, "%Y")) %in% as.integer(years), , drop = FALSE]
  }
  out[order(out$date), , drop = FALSE]
}

# Reproduce the annual report's collection-gap rule. Two or more consecutive calendar days without
# any corpus post are an interruption in collection, not evidence of silence.
digikat_collection_gaps <- function(dates, years = NULL, min_run_days = 2L) {
  dates <- as.Date(dates)
  dates <- dates[!is.na(dates)]
  if (!length(dates)) {
    return(data.frame(start = as.Date(character()), end = as.Date(character()),
                      days = integer(), stringsAsFactors = FALSE))
  }
  if (is.null(years)) years <- seq.int(min(as.integer(format(dates, "%Y"))),
                                       max(as.integer(format(dates, "%Y"))))

  pieces <- lapply(as.integer(years), function(year) {
    calendar <- seq(as.Date(sprintf("%d-01-01", year)),
                    as.Date(sprintf("%d-12-31", year)), by = "day")
    has_post <- calendar %in% dates
    runs <- rle(!has_post)
    run_end <- cumsum(runs$lengths)
    run_start <- run_end - runs$lengths + 1L
    keep <- runs$values & runs$lengths >= as.integer(min_run_days)
    data.frame(
      start = calendar[run_start[keep]],
      end = calendar[run_end[keep]],
      days = as.integer(runs$lengths[keep]),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, pieces)
}

digikat_collected_dates <- function(years, gaps) {
  calendar <- unlist(lapply(as.integer(years), function(year) {
    seq(as.Date(sprintf("%d-01-01", year)), as.Date(sprintf("%d-12-31", year)), by = "day")
  }))
  calendar <- as.Date(calendar, origin = "1970-01-01")
  collected <- rep(TRUE, length(calendar))
  if (nrow(gaps)) {
    for (i in seq_len(nrow(gaps))) {
      collected[calendar >= gaps$start[[i]] & calendar <= gaps$end[[i]]] <- FALSE
    }
  }
  calendar[collected]
}

# A common window prevents the outlet and comparison field from receiving different denominators.
# Each event uses three days. Its baseline uses the two weeks immediately before and after, excluding
# the event window. An event is not measurable if any event day was not collected or fewer than 21
# of the 28 baseline days remain after collection gaps are removed.
digikat_event_windows <- function(events, collected_dates, event_radius = 1L,
                                  baseline_weeks = 2L, min_baseline_days = 21L) {
  events <- events[order(events$date), , drop = FALSE]
  collected_dates <- unique(as.Date(collected_dates))
  baseline_span <- 7L * as.integer(baseline_weeks)
  registry <- events
  registry$event_days <- integer(nrow(events))
  registry$baseline_days <- integer(nrow(events))
  registry$measurable <- logical(nrow(events))
  registry$reason <- character(nrow(events))
  maps <- vector("list", nrow(events))

  for (i in seq_len(nrow(events))) {
    event_date <- as.Date(events$date[[i]])
    event_dates <- seq(event_date - event_radius, event_date + event_radius, by = "day")
    baseline_dates <- c(
      seq(event_date - event_radius - baseline_span,
          event_date - event_radius - 1L, by = "day"),
      seq(event_date + event_radius + 1L,
          event_date + event_radius + baseline_span, by = "day")
    )
    kept_event <- event_dates[event_dates %in% collected_dates]
    kept_baseline <- baseline_dates[baseline_dates %in% collected_dates]
    registry$event_days[[i]] <- length(kept_event)
    registry$baseline_days[[i]] <- length(kept_baseline)
    registry$measurable[[i]] <- length(kept_event) == length(event_dates) &&
      length(kept_baseline) >= as.integer(min_baseline_days)
    registry$reason[[i]] <- if (length(kept_event) < length(event_dates)) {
      "collection_gap"
    } else if (length(kept_baseline) < as.integer(min_baseline_days)) {
      "insufficient_baseline"
    } else {
      ""
    }
    if (registry$measurable[[i]]) {
      maps[[i]] <- rbind(
        data.frame(id = events$id[[i]], date = kept_event, period = "event",
                   stringsAsFactors = FALSE),
        data.frame(id = events$id[[i]], date = kept_baseline, period = "baseline",
                   stringsAsFactors = FALSE)
      )
    }
  }

  map <- do.call(rbind, maps[lengths(maps) > 0L])
  if (is.null(map)) {
    map <- data.frame(id = character(), date = as.Date(character()), period = character(),
                      stringsAsFactors = FALSE)
  }
  list(registry = registry, map = map)
}
