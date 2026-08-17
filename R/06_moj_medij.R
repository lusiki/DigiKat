#!/usr/bin/env Rscript
# =============================================================================
# R/06_moj_medij.R  --  data artifact for the "Moj medij" lookup
# -----------------------------------------------------------------------------
# Precomputes ONE PII-free JSON so an editor can look their own outlet up on a
# static page. GitHub Pages has no server, so everything the widget can ever
# show has to be in this file, and everything in this file is therefore public.
# That is why the disclosure gate below is part of the generator and not a
# separate optional step.
#
#   INPUTS  : data/digikat_corpus.rds                          (read-only official corpus)
#             data/processed/source_summary.rds                (year x FROM)
#             data/processed/{web,youtube,facebook,instagram,tiktok,twitter}_actors.rds
#             resources/dictionaries/source_labels.csv         (PI-owned)
#             data/digikat_corpus_manifest.json                (provenance)
#             studies/news-gap/output/outlet_topic_profiles.csv (optional; publication-gated)
#   OUTPUT  : data/page-ready/moj_medij.json                   (TRACKED)
#
# Reads the official corpus to build compact behavioural aggregates. The public
# artifact contains no post text, URL, identifier or top-post list.
#
# Run from the REPO ROOT:   Rscript R/06_moj_medij.R [--apply]
#   default                         : builds, validates, reports, writes nothing
#   --apply                         : additionally installs data/page-ready/moj_medij.json
#   --preview-news-gap              : embeds the private provisional news-gap profiles in memory
#   --preview-news-gap --write-preview : writes only the gitignored private preview JSON
# =============================================================================

suppressMessages({
  library(dplyr)
  library(jsonlite)
})

args   <- commandArgs(trailingOnly = TRUE)
apply_ <- "--apply" %in% args
preview_news_gap <- "--preview-news-gap" %in% args
write_preview <- "--write-preview" %in% args
if (apply_ && preview_news_gap) {
  stop("The private preview input can never be installed as the public Moj medij artifact.",
       call. = FALSE)
}
if (write_preview && !preview_news_gap) {
  stop("--write-preview requires --preview-news-gap.", call. = FALSE)
}

source(file.path("R", "lib", "digikat_paths.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_typology.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_events.R"), encoding = "UTF-8")
source(file.path("R", "lib", "moj_medij_metrics.R"), encoding = "UTF-8")
source(file.path("R", "lib", "thematic_dictionaries.R"), encoding = "UTF-8")
source(file.path("R", "lib", "moj_medij_topics.R"), encoding = "UTF-8")

# A page must never print a corpus figure computed from a different dataset than the one the
# manifest names, so refuse to build against stale aggregates for the same reason a page refuses
# to render against them.
digikat_assert_aggregates_current(file.path("data", "processed", "manifest.json"))

## ---- policy ----------------------------------------------------------------
# PI decision, 2026-08-11. The volume floor keeps the lookup off outlets whose rank would rest on
# a handful of posts. The publish gate is the catalogue's own editorial decision, reused here so
# an actor withheld from the catalogue cannot reappear through the lookup.
MIN_POSTS <- 100L
MIN_RHYTHM_CELL_POSTS <- 20L
MIN_TOPIC_CLASSIFIED_POSTS <- 100L
EVENT_YEARS <- c(2024L, 2025L)

# Sidecar `kind` values that are not media actors and never appear.
KIND_NOT_ACTOR <- c("offtopic", "noise", "duplicate")

# A FROM that looks like an internet domain is an institution by construction, so it clears the
# individual/institution question without editorial review. Anything else is a handle or a personal
# name; those appear ONLY when the sidecar has reviewed them and said yes. The consequence is that
# unreviewed handles are withheld even above the floor. That is deliberate and the run reports them
# so the PI can extend the sidecar and unlock them.
looks_like_domain <- function(x) grepl("^[A-Za-z0-9][A-Za-z0-9.-]*\\.[A-Za-z]{2,}$", x)

proc_dir <- file.path("data", "processed")
out_dir  <- file.path("data", "page-ready")
out_path <- file.path(out_dir, "moj_medij.json")
preview_out_path <- file.path("studies", "news-gap", "output", "private",
                              "moj_medij_preview.json")
sidecar  <- file.path("resources", "dictionaries", "source_labels.csv")

## ---- inputs ----------------------------------------------------------------
mf <- digikat_read_corpus_manifest()
agg_mf <- fromJSON(file.path(proc_dir, "manifest.json"), simplifyVector = TRUE)

ss <- readRDS(file.path(proc_dir, "source_summary.rds")) |>
  filter(!is.na(FROM), nzchar(trimws(as.character(FROM))),
         !FROM %in% DIGIKAT_NON_ACTOR_FROM)

side <- read.csv(sidecar, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                 colClasses = "character", na.strings = "NA")
names(side) <- gsub("^﻿", "", names(side))
for (col in names(side)) side[[col]] <- enc2utf8(ifelse(is.na(side[[col]]), "", trimws(side[[col]])))

platforms <- c(web = "web_actors.rds", youtube = "youtube_actors.rds",
               facebook = "facebook_actors.rds", instagram = "instagram_actors.rds",
               tiktok = "tiktok_actors.rds", twitter = "twitter_actors.rds")

# Platform and typology exist only for the actors the catalogue profiles, because source_summary
# groups by FROM alone and carries no platform column. The typology is computed with the SHARED
# rule on the SAME rows the catalogue uses, so the two surfaces cannot disagree.
actors <- bind_rows(lapply(names(platforms), function(p) {
  a <- readRDS(file.path(proc_dir, platforms[[p]]))
  a$platform <- p
  a$typology <- digikat_classify_typology(a)
  a[, c("FROM", "platform", "typology")]
}))
# A handle present on two platforms would otherwise attach two archetypes to one row. Keep the
# platform where the name carries the most posts and record that the split exists.
multi_platform <- actors |> count(FROM) |> filter(n > 1L) |> pull(FROM)
actors <- actors |> distinct(FROM, .keep_all = TRUE)

## ---- per-source totals and yearly series -----------------------------------
totals <- ss |>
  group_by(FROM) |>
  summarise(posts = sum(productivity, na.rm = TRUE),
            interactions = sum(total_interactions, na.rm = TRUE),
            reach = sum(total_reach, na.rm = TRUE),
            .groups = "drop")

n_sources_all <- nrow(totals)

## ---- disclosure gate --------------------------------------------------------
elig <- totals |>
  left_join(side |> select(FROM = from, entity, kind, label, publish), by = "FROM") |>
  mutate(
    kind = ifelse(is.na(kind), "", kind),
    publish = ifelse(is.na(publish), "", publish),
    is_domain = looks_like_domain(FROM),
    reviewed = FROM %in% side$from,
    # Ordered so each row gets exactly one reason.
    reason = case_when(
      posts < MIN_POSTS                      ~ "ispod praga objava",
      kind %in% KIND_NOT_ACTOR               ~ "nije medijski akter",
      reviewed & publish != "yes"            ~ "zadržano uredničkom odlukom",
      !is_domain & !reviewed                 ~ "nerecenzirani račun bez uredničke provjere",
      TRUE                                   ~ NA_character_
    ),
    listed = is.na(reason)
  )

withheld <- elig |> filter(!listed, posts >= MIN_POSTS) |> arrange(desc(posts))
listed   <- elig |> filter(listed)

stopifnot(nrow(listed) > 0L)

## ---- full-corpus behavioural and topic aggregates -------------------------
# This is the only row-level read in the generator. Keep the URL only long enough to verify that
# TIME follows Europe/Zagreb local time against Twitter Snowflake timestamps. Topic classification
# is chunked and immediately reduced to (FROM, platform, topic) before all row-level fields vanish.
corpus_path <- digikat_corpus_path()
if (!file.exists(corpus_path)) {
  stop("The official corpus is required for Moj medij behavioural profiles: ", corpus_path,
       call. = FALSE)
}
corpus <- readRDS(corpus_path)
behaviour_columns <- c("DATE", "TIME", "FROM", "SOURCE_TYPE", "INTERACTIONS", "URL")
topic_columns <- c("FROM", "SOURCE_TYPE", "TITLE", "FULL_TEXT")
missing_profile_columns <- setdiff(union(behaviour_columns, topic_columns), names(corpus))
if (length(missing_profile_columns)) {
  stop("The official corpus is missing profile field(s): ",
       paste(missing_profile_columns, collapse = ", "), call. = FALSE)
}
if (nrow(corpus) != as.integer(mf$corpus$rows)) {
  stop("The official corpus row count does not match its manifest.", call. = FALSE)
}
behaviour_all <- corpus[, behaviour_columns]
topic_rows <- corpus[, topic_columns]
rm(corpus); invisible(gc())
topic_profiles_all <- digikat_topic_profiles(
  topic_rows,
  dictionary = digikat_thematic_dictionaries,
  text_characters = 3000L,
  chunk_size = 25000L,
  progress = TRUE
)
rm(topic_rows); invisible(gc())
topic_comparisons <- digikat_topic_comparisons(
  topic_profiles_all,
  listed_sources = listed$FROM,
  min_classified_posts = MIN_TOPIC_CLASSIFIED_POSTS,
  max_neighbours = 4L,
  min_neighbours = 3L
)
rm(topic_profiles_all); invisible(gc())
behaviour_all$DATE <- as.Date(behaviour_all$DATE)
behaviour_all$FROM <- as.character(behaviour_all$FROM)
behaviour_all$SOURCE_TYPE <- as.character(behaviour_all$SOURCE_TYPE)

time_audit <- digikat_audit_vendor_time(behaviour_all)
if (!isTRUE(time_audit$reliable)) {
  stop("TIME reliability audit failed; hour-band profiles cannot be published.", call. = FALSE)
}

# Detect the same global interruptions as the annual-report chain. The shared event registry and
# gap rule prevent one product from treating an uncollected date as zero while another omits it.
events <- digikat_calendar_events(EVENT_YEARS, moj_medij_only = TRUE)
support_years <- seq.int(min(EVENT_YEARS) - 1L, max(EVENT_YEARS) + 1L)
support_gaps <- digikat_collection_gaps(behaviour_all$DATE, support_years)
collected_dates <- digikat_collected_dates(support_years, support_gaps)
collected_dates <- collected_dates[
  collected_dates >= min(behaviour_all$DATE, na.rm = TRUE) &
    collected_dates <= max(behaviour_all$DATE, na.rm = TRUE)
]
collection_gaps <- support_gaps[
  as.integer(format(support_gaps$start, "%Y")) %in% EVENT_YEARS,
  , drop = FALSE
]
event_windows <- digikat_event_windows(events, collected_dates)

# Fail closed if a generated annual-report gap table disagrees with the shared detector.
for (event_year in EVENT_YEARS) {
  annual_gap_path <- file.path("studies", "annual-report", "output", as.character(event_year),
                               "coverage_gaps.csv")
  if (file.exists(annual_gap_path)) {
    annual_gaps <- read.csv(annual_gap_path, stringsAsFactors = FALSE)
    annual_gaps$start <- as.Date(annual_gaps$start)
    annual_gaps$end <- as.Date(annual_gaps$end)
    detected <- collection_gaps[as.integer(format(collection_gaps$start, "%Y")) == event_year,
                                c("start", "end", "days"), drop = FALSE]
    rownames(annual_gaps) <- NULL
    rownames(detected) <- NULL
    if (!isTRUE(all.equal(annual_gaps[, c("start", "end", "days"), drop = FALSE],
                          detected, check.attributes = TRUE))) {
      stop("Collection gaps disagree with the annual-report chain for ", event_year, ".",
           call. = FALSE)
    }
  }
}

behaviour <- behaviour_all |>
  filter(FROM %in% listed$FROM, !is.na(SOURCE_TYPE), nzchar(SOURCE_TYPE))

platform_counts <- behaviour |>
  count(FROM, SOURCE_TYPE, name = "posts") |>
  arrange(FROM, desc(posts), SOURCE_TYPE)
primary_platform <- platform_counts |>
  group_by(FROM) |>
  summarise(primary_platform = first(SOURCE_TYPE), platform_n = n(), .groups = "drop")

attention <- digikat_attention_metrics(behaviour) |>
  digikat_attention_peer_medians(MIN_POSTS)
rhythm <- digikat_rhythm_cells(behaviour, MIN_RHYTHM_CELL_POSTS)

# Counts are aggregated to date before they meet an event window. The same event and baseline dates
# then feed outlet and platform-field rates, including zeros on collected days.
event_map <- event_windows$map
source_daily <- behaviour |>
  count(FROM, SOURCE_TYPE, DATE, name = "posts")
source_event_counts <- source_daily |>
  inner_join(event_map, by = c("DATE" = "date"), relationship = "many-to-many") |>
  group_by(FROM, SOURCE_TYPE, id, period) |>
  summarise(posts = sum(posts), .groups = "drop")
field_daily <- behaviour_all |>
  filter(!is.na(SOURCE_TYPE), nzchar(SOURCE_TYPE)) |>
  count(SOURCE_TYPE, DATE, name = "posts")
field_event_counts <- field_daily |>
  inner_join(event_map, by = c("DATE" = "date"), relationship = "many-to-many") |>
  group_by(SOURCE_TYPE, id, period) |>
  summarise(posts = sum(posts), .groups = "drop")

# No public object below this point needs a URL or any other row-level identifier.
behaviour_all$URL <- NULL

## ---- ranks, shares, series --------------------------------------------------
corpus_posts <- as.numeric(mf$corpus$rows)

listed <- listed |>
  mutate(
    eng = ifelse(posts > 0, interactions / posts, NA_real_),
    rank_posts = rank(-posts, ties.method = "min"),
    rank_interactions = rank(-interactions, ties.method = "min"),
    rank_reach = rank(-reach, ties.method = "min"),
    share_posts = 100 * posts / corpus_posts
  ) |>
  left_join(actors, by = "FROM") |>
  left_join(primary_platform, by = "FROM") |>
  mutate(multi = platform_n > 1L | FROM %in% multi_platform) |>
  arrange(desc(posts))

n_listed <- nrow(listed)

# Peer group: same editorial label, among listed sources. Where the sidecar has no label there is
# no peer group, which the page states rather than inventing one.
listed <- listed |>
  group_by(label) |>
  mutate(rank_in_label = ifelse(nzchar(label) & !is.na(label),
                                rank(-interactions, ties.method = "min"), NA_integer_),
         n_in_label = ifelse(nzchar(label) & !is.na(label), n(), NA_integer_)) |>
  ungroup()

years <- sort(unique(ss$year))

series <- ss |>
  filter(FROM %in% listed$FROM) |>
  select(FROM, year, p = productivity, i = total_interactions, r = total_reach) |>
  arrange(FROM, year)

## ---- optional publication-gated news-gap profiles -------------------------
# The private preview must never enter the page-ready JSON. Public integration is fail-closed:
# the result must carry an explicit public status and a separately public aggregate must exist.
news_gap_results_path <- file.path("studies", "news-gap", "output", "analysis_results.json")
news_gap_profiles_path <- file.path("studies", "news-gap", "output", "outlet_topic_profiles.csv")
news_gap_private_profiles_path <- file.path("studies", "news-gap", "output", "private",
                                           "outlet_topic_profiles.csv")
news_gap_registry_path <- file.path("studies", "news-gap", "source_registry.csv")
news_gap_status <- "not_available"
news_gap_by_source <- list()

if (file.exists(news_gap_results_path)) {
  news_gap_results <- fromJSON(news_gap_results_path, simplifyVector = TRUE)
  news_gap_status <- as.character(news_gap_results$status)

  publishable_news_gap_status <- news_gap_status %in% c(
    "published_provisional_pending_manual_dictionary_validation",
    "validated_for_publication"
  )
  embed_news_gap <- publishable_news_gap_status || preview_news_gap
  selected_news_gap_profiles_path <- if (preview_news_gap) {
    news_gap_private_profiles_path
  } else {
    news_gap_profiles_path
  }

  if (embed_news_gap) {
    if (!file.exists(selected_news_gap_profiles_path) || !file.exists(news_gap_registry_path)) {
      stop(
        "The selected news-gap profile table or registry is missing.",
        call. = FALSE
      )
    }

    ng <- read.csv(selected_news_gap_profiles_path, fileEncoding = "UTF-8-BOM",
                   stringsAsFactors = FALSE,
                   check.names = FALSE)
    ng_registry <- read.csv(news_gap_registry_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE,
                            check.names = FALSE)
    required_ng <- c("product_id", "display_name", "topic_label", "production_pct", "reward_pct",
                     "gap_pp", "validation_status")
    if (length(setdiff(required_ng, names(ng))) || any(ng$validation_status != news_gap_status)) {
      stop("News-gap profile table fails its publication data contract.", call. = FALSE)
    }
    if (anyDuplicated(ng_registry$product_id)) {
      stop("News-gap registry contains duplicate product IDs.", call. = FALSE)
    }

    ng <- merge(
      ng,
      ng_registry[, c("product_id", "raw_from", "url_host")],
      by = "product_id",
      all.x = TRUE
    )
    if (any(is.na(ng$raw_from)) || any(!is.finite(ng$production_pct)) ||
        any(!is.finite(ng$reward_pct)) || any(!is.finite(ng$gap_pp))) {
      stop("News-gap profiles contain an unmapped or non-finite value.", call. = FALSE)
    }

    ng_products <- split(ng, ng$product_id)
    ng_records <- lapply(ng_products, function(z) list(
      id = unname(z$product_id[[1L]]),
      n = unname(z$display_name[[1L]]),
      h = unname(z$url_host[[1L]]),
      v = list(
        k = unname(as.character(z$topic_label)),
        p = unname(round(as.numeric(z$production_pct), 2)),
        r = unname(round(as.numeric(z$reward_pct), 2)),
        g = unname(round(as.numeric(z$gap_pp), 2))
      )
    ))
    ng_sources <- vapply(ng_products, function(z) as.character(z$raw_from[[1L]]), character(1L))
    news_gap_by_source <- split(unname(ng_records), unname(ng_sources))
  }
}

# Catalogue profile filenames follow R/wiki_sources.R's slug rule; link only where the page exists.
slugify <- function(x) {
  mfrom <- c("č","ć","ž","š","đ","Č","Ć","Ž","Š","Đ")
  mto   <- c("c","c","z","s","dj","c","c","z","s","dj")
  for (i in seq_along(mfrom)) x <- gsub(mfrom[i], mto[i], x, fixed = TRUE)
  x <- tolower(x); x <- gsub("[^a-z0-9]+", "-", x); x <- gsub("(^-+)|(-+$)", "", x)
  x[x == ""] <- "izvor"; x
}
profile_of <- function(from, platform) {
  ifelse(is.na(platform), NA_character_,
         paste0(platform, "-", slugify(from), ".html"))
}
listed$profile <- profile_of(listed$FROM, listed$platform)
exists_profile <- file.exists(file.path("pages", "izvori",
                                        sub("\\.html$", ".qmd", ifelse(is.na(listed$profile), "", listed$profile))))
listed$profile[!exists_profile] <- NA_character_

# Case and punctuation occasionally distinguish two public source records (most often the web and
# Facebook forms of the same outlet). Keep every record downloadable without allowing one PDF to
# overwrite another. Platform names make the common collision readable; a stable ordinal covers
# the few legacy records that do not carry a platform value.
card_stem <- slugify(listed$FROM)
card_collision <- duplicated(card_stem) | duplicated(card_stem, fromLast = TRUE)
card_ordinal <- ave(seq_along(card_stem), card_stem, FUN = seq_along)
card_suffix <- ifelse(!is.na(listed$platform), listed$platform, paste0("record-", card_ordinal))
card_stem[card_collision] <- paste(card_stem[card_collision], card_suffix[card_collision], sep = "-")
listed$card <- paste0(make.unique(card_stem, sep = "-record-"), ".pdf")

## ---- assemble ---------------------------------------------------------------
r1 <- function(x) round(as.numeric(x), 1)
r2 <- function(x) ifelse(is.finite(as.numeric(x)), round(as.numeric(x), 2), NA_real_)

period_posts <- function(table, from = NULL, platform, event_id, period) {
  keep <- table$SOURCE_TYPE == platform & table$id == event_id & table$period == period
  if (!is.null(from)) keep <- keep & table$FROM == from
  value <- table$posts[keep]
  if (length(value)) sum(value) else 0
}

calendar_values <- function(from, platform) {
  lapply(seq_len(nrow(event_windows$registry)), function(i) {
    event <- event_windows$registry[i, ]
    out <- list(v = as.integer(i))
    if (isTRUE(event$measurable)) {
      outlet_event <- period_posts(source_event_counts, from, platform, event$id, "event")
      outlet_base <- period_posts(source_event_counts, from, platform, event$id, "baseline")
      field_event <- period_posts(field_event_counts, NULL, platform, event$id, "event")
      field_base <- period_posts(field_event_counts, NULL, platform, event$id, "baseline")
      out$o <- unname(r2(digikat_rate_ratio(outlet_event, event$event_days,
                                           outlet_base, event$baseline_days)))
      out$f <- unname(r2(digikat_rate_ratio(field_event, event$event_days,
                                           field_base, event$baseline_days)))
    }
    out
  })
}

behaviour_values <- function(from) {
  source_platforms <- platform_counts[platform_counts$FROM == from, , drop = FALSE]
  lapply(seq_len(nrow(source_platforms)), function(i) {
    platform <- source_platforms$SOURCE_TYPE[[i]]
    topic_key <- digikat_topic_profile_key(from, platform)
    att <- attention[attention$FROM == from & attention$SOURCE_TYPE == platform, , drop = FALSE]
    cells <- rhythm[rhythm$FROM == from & rhythm$SOURCE_TYPE == platform, , drop = FALSE]
    coverage <- topic_comparisons$coverage[
      topic_comparisons$coverage$key == topic_key,
      , drop = FALSE
    ]
    if (nrow(coverage) != 1L) {
      stop("Topic coverage is missing or duplicated for ", from, " / ", platform, ".",
           call. = FALSE)
    }
    out <- list(
      pl = unname(platform),
      p = unname(as.integer(source_platforms$posts[[i]])),
      tc = unname(as.integer(coverage$classified_posts[[1L]])),
      a = list(
        t = unname(r2(att$top10_share[[1L]])),
        z = unname(r2(att$zero_rate[[1L]])),
        mt = unname(r2(att$peer_top10[[1L]])),
        mz = unname(r2(att$peer_zero[[1L]])),
        nt = unname(as.integer(att$peer_top10_n[[1L]])),
        nz = unname(as.integer(att$peer_zero_n[[1L]]))
      ),
      r = lapply(seq_len(nrow(cells)), function(j) list(
        d = unname(as.integer(cells$weekday[[j]])),
        b = unname(as.integer(cells$band[[j]])),
        p = unname(as.integer(cells$posts[[j]])),
        e = unname(r2(cells$engagement[[j]]))
      )),
      k = calendar_values(from, platform)
    )
    if (isTRUE(coverage$eligible[[1L]])) {
      topic_rows <- topic_comparisons$profiles[
        topic_comparisons$profiles$FROM == from &
          topic_comparisons$profiles$SOURCE_TYPE == platform,
        , drop = FALSE
      ]
      topic_rows <- topic_rows[match(topic_comparisons$topics, topic_rows$topic), , drop = FALSE]
      if (nrow(topic_rows) != length(topic_comparisons$topics) || anyNA(topic_rows$topic)) {
        stop("Eligible topic profile is incomplete for ", from, " / ", platform, ".",
             call. = FALSE)
      }
      out$tm <- list(
        n = unname(as.integer(coverage$classified_posts[[1L]])),
        pn = unname(as.integer(topic_rows$peer_n[[1L]])),
        s = unname(r2(topic_rows$topic_share)),
        f = unname(r2(topic_rows$peer_share))
      )
      similar <- topic_comparisons$neighbours[[topic_key]]
      if (length(similar)) out$sn <- unname(as.character(similar))
    }
    out
  })
}

records <- lapply(seq_len(n_listed), function(k) {
  row <- listed[k, ]
  ys <- series[series$FROM == row$FROM, ]
  out <- list(
    n = unname(row$FROM),
    c = unname(row$card),
    p = unname(as.integer(row$posts)),
    i = unname(as.numeric(row$interactions)),
    x = unname(as.numeric(row$reach)),
    e = unname(r1(row$eng)),
    rp = unname(as.integer(row$rank_posts)),
    ri = unname(as.integer(row$rank_interactions)),
    rx = unname(as.integer(row$rank_reach)),
    sp = unname(round(as.numeric(row$share_posts), 3)),
    y = list(g = as.integer(ys$year), p = as.integer(ys$p),
             i = as.numeric(ys$i), r = as.numeric(ys$r))
  )
  if (nzchar(row$entity) && !is.na(row$entity)) out$t <- unname(row$entity)
  if (!is.na(row$platform))  out$pl <- unname(row$platform)
  if (!is.na(row$typology))  out$tp <- unname(row$typology)
  if (nzchar(row$label) && !is.na(row$label)) {
    out$lb <- unname(row$label)
    out$rl <- unname(as.integer(row$rank_in_label))
    out$nl <- unname(as.integer(row$n_in_label))
  }
  if (!is.na(row$profile)) out$pr <- unname(row$profile)
  if (isTRUE(row$multi))   out$mp <- TRUE
  out$bh <- behaviour_values(as.character(row$FROM))
  if (length(news_gap_by_source[[as.character(row$FROM)]])) {
    out$ng <- news_gap_by_source[[as.character(row$FROM)]]
  }
  out
})

payload <- list(
  schema_version = 4L,
  generated_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%d %H:%M:%S UTC"),
  generator = "R/06_moj_medij.R",
  input = list(
    corpus_sha256 = mf$corpus$sha256,
    aggregates_sha256 = agg_mf$input$sha256,
    source_summary_sha256 = agg_mf$outputs$source_summary$sha256
  ),
  policy = list(
    min_posts = MIN_POSTS,
    rhythm_min_cell_posts = MIN_RHYTHM_CELL_POSTS,
    topic_min_classified_posts = MIN_TOPIC_CLASSIFIED_POSTS,
    unreviewed_handles_withheld = TRUE,
    note = paste("Prikazani su izvori s najmanje", MIN_POSTS,
                 "objava. Računi koji nisu internetske domene prikazuju se samo ako ih je",
                 "urednička provjera odobrila.")
  ),
  behaviour = list(
    attention = list(
      top_posts = 10L,
      peer_definition = paste("Prikazani izvori na istoj platformi s najmanje", MIN_POSTS, "objava."),
      zero_denominator = "Objave za koje je servis zabilježio broj interakcija."
    ),
    rhythm = list(
      timezone = time_audit$timezone,
      weekdays = c("Pon", "Uto", "Sri", "Čet", "Pet", "Sub", "Ned"),
      bands = unname(DIGIKAT_TIME_BANDS$label),
      min_cell_posts = MIN_RHYTHM_CELL_POSTS
    ),
    topics = list(
      status = "provisional_validation_leads_not_rankings",
      decision_date = "2026-08-13",
      label = "Privremeno · smjernice za validaciju, ne rangiranje",
      method = "Rječnik na naslovu i prvih 3.000 znakova teksta; vezani rezultati dijele težinu.",
      min_classified_posts = MIN_TOPIC_CLASSIFIED_POSTS,
      labels = unname(DIGIKAT_TOPIC_PROFILE_LABELS[topic_comparisons$topics]),
      peer_definition = paste(
        "Jednako ponderiran prosjek prikazanih izvora na istoj platformi s najmanje",
        MIN_TOPIC_CLASSIFIED_POSTS, "rječnički razvrstanih objava."
      ),
      similarity = "Kosinusna sličnost tematskih udjela među prikazanim izvorima na istoj platformi."
    ),
    calendar = list(
      event_radius_days = 1L,
      baseline_weeks_each_side = 2L,
      events = lapply(seq_len(nrow(event_windows$registry)), function(i) {
        event <- event_windows$registry[i, ]
        list(
          id = unname(event$id),
          d = format(event$date, "%Y-%m-%d"),
          n = unname(event$label_hr),
          y = as.integer(format(event$date, "%Y")),
          ok = isTRUE(event$measurable),
          rs = if (nzchar(event$reason)) unname(event$reason) else NULL
        )
      }),
      exclusions = lapply(seq_len(nrow(collection_gaps)), function(i) list(
        s = format(collection_gaps$start[[i]], "%Y-%m-%d"),
        e = format(collection_gaps$end[[i]], "%Y-%m-%d")
      ))
    ),
    time_audit = list(
      rows = as.integer(time_audit$rows),
      valid_pct = r2(time_audit$valid_pct),
      missing_pct = r2(time_audit$missing_pct),
      distinct_times = as.integer(time_audit$distinct_times),
      second_precision_pct = r2(time_audit$second_precision_pct),
      timezone = unname(time_audit$timezone),
      twitter_snowflakes = as.integer(time_audit$twitter_snowflakes),
      zagreb_match_pct = r2(time_audit$zagreb_match_pct)
    )
  ),
  totals = list(
    corpus_posts = as.integer(mf$corpus$rows),
    corpus_years = paste0(mf$corpus$year_min, ".-", mf$corpus$year_max, "."),
    sources_in_corpus = as.integer(n_sources_all),
    sources_listed = as.integer(n_listed),
    sources_withheld = as.integer(nrow(withheld)),
    posts_listed = as.integer(sum(listed$posts))
  ),
  years = as.integer(years),
  sources = records
)
if (preview_news_gap) {
  payload$preview <- list(
    news_gap = TRUE,
    status = news_gap_status
  )
}

json <- toJSON(payload, auto_unbox = TRUE, digits = 6, null = "null", na = "null")

## ---- validate before writing ------------------------------------------------
# The artifact is public the moment it is committed, so assert what it must NOT contain rather
# than trusting the assembly above.
txt <- as.character(json)
forbidden <- c("http://", "https://", "FULL_TEXT", "@gmail", "AUTHOR", "URL\"", "TITLE\"")
hit <- forbidden[vapply(forbidden, function(p) grepl(p, txt, fixed = TRUE), logical(1))]
if (length(hit)) {
  stop("Disclosure gate: generated JSON contains ", paste(hit, collapse = ", "), call. = FALSE)
}
allowed_keys <- c("n","c","t","p","i","x","e","rp","ri","rx","sp","y","pl","tp","lb","rl","nl","pr","mp","ng","bh")
extra <- setdiff(unique(unlist(lapply(records, names))), allowed_keys)
if (length(extra)) {
  stop("Disclosure gate: unexpected key(s) in a source record: ", paste(extra, collapse = ", "),
       call. = FALSE)
}
stopifnot(!any(is.na(listed$posts)), all(listed$posts >= MIN_POSTS))
stopifnot(!anyDuplicated(listed$card), all(grepl("^[a-z0-9-]+[.]pdf$", listed$card)))
stopifnot(sum(platform_counts$posts) == sum(listed$posts))
stopifnot(all(rhythm$posts >= MIN_RHYTHM_CELL_POSTS))
stopifnot(identical(names(DIGIKAT_TOPIC_PROFILE_LABELS), topic_comparisons$topics))
topic_payloads <- unlist(lapply(records, function(record) {
  lapply(record$bh, function(platform) platform$tm)
}), recursive = FALSE)
topic_payloads <- topic_payloads[!vapply(topic_payloads, is.null, logical(1L))]
stopifnot(length(topic_payloads) == sum(topic_comparisons$coverage$eligible))
stopifnot(all(vapply(topic_payloads, function(profile) {
  length(profile$s) == length(topic_comparisons$topics) &&
    length(profile$f) == length(topic_comparisons$topics) &&
    abs(sum(profile$s) - 100) <= 0.1 && abs(sum(profile$f) - 100) <= 0.1
}, logical(1L))))
similar_payloads <- unlist(lapply(records, function(record) {
  lapply(record$bh, function(platform) platform$sn)
}), recursive = FALSE)
similar_payloads <- similar_payloads[!vapply(similar_payloads, is.null, logical(1L))]
stopifnot(all(vapply(similar_payloads, function(similar) length(similar) %in% 3:4, logical(1L))))
easter_2024 <- event_windows$registry[event_windows$registry$id == "easter-2024", ]
stopifnot(nrow(easter_2024) == 1L, !isTRUE(easter_2024$measurable),
          identical(easter_2024$reason, "collection_gap"))

## ---- report ------------------------------------------------------------------
cat("\n=== Moj medij ===\n")
cat("izvora u korpusu           :", n_sources_all, "\n")
cat("prag objava                :", MIN_POSTS, "\n")
cat("izvora iznad praga         :", sum(elig$posts >= MIN_POSTS), "\n")
cat("PRIKAZANO                  :", n_listed, "\n")
cat("zadrzano (iznad praga)     :", nrow(withheld), "\n")
if (nrow(withheld)) {
  cat("\nrazlozi zadrzavanja:\n")
  print(as.data.frame(withheld |> count(reason, name = "izvora") |> arrange(desc(izvora))))
  cat("\n20 najvecih zadrzanih (kandidati za urednicku provjeru):\n")
  print(as.data.frame(withheld |> select(FROM, posts, reason) |> head(20)))
}
cat("\nvelicina JSON-a            :", nchar(txt, type = "bytes"), "bytes\n")
cat("s tipologijom              :", sum(!is.na(listed$typology)), "\n")
cat("s poveznicom na katalog    :", sum(!is.na(listed$profile)), "\n")
cat("news-gap status            :", news_gap_status, "\n")
cat("s news-gap profilom         :", sum(vapply(records, function(x) "ng" %in% names(x), logical(1L))), "\n")
cat("s tematskim profilom        :", length(topic_payloads), "\n")
cat("s 3-4 slična izvora         :", length(similar_payloads), "\n")
cat("rječnički razvrstano        :", sum(topic_comparisons$coverage$classified_posts), "objava\n")
cat("TIME zona                  :", time_audit$timezone, "(", time_audit$zagreb_match_pct,
    "% Twitter provjera)\n")
cat("ćelija ritma (>= prag)      :", nrow(rhythm), "\n")
cat("kalendarskih događaja       :", nrow(event_windows$registry), "\n")

if (write_preview) {
  dir.create(dirname(preview_out_path), showWarnings = FALSE, recursive = TRUE)
  con <- file(preview_out_path, open = "wb")
  writeLines(enc2utf8(txt), con, useBytes = TRUE)
  close(con)
  cat("\nZAPISAN PREGLED:", preview_out_path, "\n\n")
} else if (!apply_) {
  cat("\nPREGLED. Nista nije zapisano. Za instalaciju pokreni:\n  Rscript R/06_moj_medij.R --apply\n\n")
} else {
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  con <- file(out_path, open = "wb"); writeLines(enc2utf8(txt), con, useBytes = TRUE); close(con)
  cat("\nZAPISANO:", out_path, "\n\n")
}
