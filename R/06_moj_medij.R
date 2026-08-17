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
#   INPUTS  : data/processed/source_summary.rds                (year x FROM)
#             data/processed/{web,youtube,facebook,instagram,tiktok,twitter}_actors.rds
#             resources/dictionaries/source_labels.csv         (PI-owned)
#             data/digikat_corpus_manifest.json                (provenance)
#             studies/news-gap/output/outlet_topic_profiles.csv (optional; publication-gated)
#   OUTPUT  : data/page-ready/moj_medij.json                   (TRACKED)
#
# Reads only tracked aggregates. Never reads the corpus or the accumulator, so
# it runs on a machine without them and cannot leak a post.
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

# A page must never print a corpus figure computed from a different dataset than the one the
# manifest names, so refuse to build against stale aggregates for the same reason a page refuses
# to render against them.
digikat_assert_aggregates_current(file.path("data", "processed", "manifest.json"))

## ---- policy ----------------------------------------------------------------
# PI decision, 2026-08-11. The volume floor keeps the lookup off outlets whose rank would rest on
# a handful of posts. The publish gate is the catalogue's own editorial decision, reused here so
# an actor withheld from the catalogue cannot reappear through the lookup.
MIN_POSTS <- 100L

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
  mutate(multi = FROM %in% multi_platform) |>
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
  if (length(news_gap_by_source[[as.character(row$FROM)]])) {
    out$ng <- news_gap_by_source[[as.character(row$FROM)]]
  }
  out
})

payload <- list(
  schema_version = 2L,
  generated_utc = format(Sys.time(), tz = "UTC", "%Y-%m-%d %H:%M:%S UTC"),
  generator = "R/06_moj_medij.R",
  input = list(
    corpus_sha256 = mf$corpus$sha256,
    aggregates_sha256 = agg_mf$input$sha256,
    source_summary_sha256 = agg_mf$outputs$source_summary$sha256
  ),
  policy = list(
    min_posts = MIN_POSTS,
    unreviewed_handles_withheld = TRUE,
    note = paste("Prikazani su izvori s najmanje", MIN_POSTS,
                 "objava. Računi koji nisu internetske domene prikazuju se samo ako ih je",
                 "urednička provjera odobrila.")
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
forbidden <- c("http://", "https://", "FULL_TEXT", "@gmail", "AUTHOR", "URL\"")
hit <- forbidden[vapply(forbidden, function(p) grepl(p, txt, fixed = TRUE), logical(1))]
if (length(hit)) {
  stop("Disclosure gate: generated JSON contains ", paste(hit, collapse = ", "), call. = FALSE)
}
allowed_keys <- c("n","c","t","p","i","x","e","rp","ri","rx","sp","y","pl","tp","lb","rl","nl","pr","mp","ng")
extra <- setdiff(unique(unlist(lapply(records, names))), allowed_keys)
if (length(extra)) {
  stop("Disclosure gate: unexpected key(s) in a source record: ", paste(extra, collapse = ", "),
       call. = FALSE)
}
stopifnot(!any(is.na(listed$posts)), all(listed$posts >= MIN_POSTS))
stopifnot(!anyDuplicated(listed$card), all(grepl("^[a-z0-9-]+[.]pdf$", listed$card)))

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
