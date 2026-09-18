# Independent release audit: every outlet, article and count below is invented.
run_barometar_release_audit_tests <- function(strict = TRUE) {
  source("R/lib/barometar_release.R", encoding = "UTF-8")
  failures <- character(); checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  rejects <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")
  close <- function(x, y) isTRUE(all.equal(unname(x), unname(y), tolerance = 1e-10))
  days <- data.frame(day = as.character(seq(as.Date("2024-01-01"), as.Date("2024-03-31"), by = "day")))
  days$observed <- !startsWith(days$day, "2024-02")
  panel <- data.frame(outlet_id = letters[1:4], display_name = paste("Invented outlet", 1:4),
    outlet_domain = paste0(letters[1:4], ".example.invalid"),
    segment = c("national", "regional", "confessional", "political_portal"))
  denominator <- expand.grid(day = days$day[days$observed], outlet_id = panel$outlet_id, stringsAsFactors = FALSE)
  denominator$N <- 10L
  facet <- function(route, themes = "", principles = "", speaker = "ostalo / nepripisano")
    data.frame(route = route, themes = themes, principles = principles,
      register = "supstancijski", reference_geography = "domaće", speaker_type = speaker)
  encode <- function(...) as.character(jsonlite::toJSON(do.call(rbind, list(...)), dataframe = "rows", auto_unbox = TRUE))
  decisions <- data.frame(doc_key = paste0("invented-", 1:6), day = "2024-01-08",
    outlet_id = c("a", "b", "c", "d", "a", "a"), route_set = c("A1;B", "B", "A1;C;D", "A1", "A2", "A?"),
    facet_data = c(
      encode(facet("A1", "politics", "dostojanstvo_osobe"), facet("B", "work", "solidarnost", "crkveni govornik")),
      encode(facet("B", "work", "solidarnost", "crkveni govornik")),
      encode(facet("A1", "politics", "dostojanstvo_osobe;opce_dobro", "demokršćanski akter"),
        facet("C", "politics;family", "solidarnost", "drugi politički akter")),
      encode(facet("A1", "family")), "[]", "[]"),
    hdz_only = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE))
  versions <- list(panel_version = "invented-panel", definition_version = "invented-definition", release_version = "invented-release")
  labels <- list(politics = "Invented politics", work = "Invented work", family = "Invented family", unclassified = "Unclassified")
  theme_validation <- data.frame(theme_id = names(labels), theme_status = "confirmed")
  build <- function(d = denominator, a = decisions, p = panel, routes = c("A1", "B", "C"), scopes = c("siri", "uze"), validation = theme_validation)
    barometar_build_tables(d, a, days, p, versions, routes, scopes, validation, theme_labels = labels)
  tables <- build()
  month <- function(table = tables$monthly, scope = "siri", period = "2024-01") table[table$scope == scope & table$period_id == period, , drop = FALSE]
  broad <- month(); narrow <- month(scope = "uze")
  check(broad$total_articles == 1240 && narrow$total_articles == 1240, "scope denominators are identical")
  check(broad$matching_articles == 4 && narrow$matching_articles == 3, "article union counts each multi-route article once")
  check(broad$matching_outlets == 4 && narrow$matching_outlets == 3 && narrow$breadth_pct == 75, "breadth uses distinct outlets and the fixed panel")
  check(close(broad$visibility_per_10000, 10000 * 4/1240), "visibility is a pooled count ratio")
  theme <- function(id, scope = "siri", period = "2024-01", source = tables)
    source$themes[source$themes$frequency == "monthly" & source$themes$scope == scope & source$themes$period_id == period & source$themes$theme_id == id, , drop = FALSE]
  check(theme("work")$articles_with_theme == 2 && theme("work", "uze")$articles_with_theme == 0, "A1 narrow themes exclude separate B passages")
  check(theme("family")$articles_with_theme == 2 && theme("family", "uze")$articles_with_theme == 1, "A1 narrow themes exclude separate C passages")
  check(theme("politics")$articles_with_theme == 2, "same theme on two routes counts an article once")
  check(theme("work", "uze")$theme_status == "unconfirmed" && theme("work")$theme_status == "confirmed", "pooled broad theme precision cannot certify a narrow theme")
  check(is.na(theme("work", period = "2024-02")$rate_per_10000) && theme("work", period = "2024-02")$period_status == "unavailable", "missing coverage produces unavailable theme rates")
  check(theme("work", period = "2024-03")$rate_per_10000 == 0 && theme("work", period = "2024-03")$period_status == "published", "observed absence produces an explicit zero theme rate")
  composition <- function(facet, scope = "siri") {
    x <- tables$composition
    x[x$frequency == "monthly" & x$scope == scope & x$period_id == "2024-01" & x$facet == facet, , drop = FALSE]
  }
  routes <- composition("route_set")
  check(sum(routes$articles) == 4 && all(c("A1;B", "B", "A1;C;D", "A1") %in% routes$value), "route composition exports exact disjoint combinations")
  check(!any(grepl("B|C", composition("route_set", "uze")$value)), "narrow route composition excludes broad-only routes")
  principles <- composition("principles")
  check(sum(principles$articles) == 6 && principles$articles[principles$value == "solidarnost"] == 3, "principles remain overlapping article indicators")
  check(all(vapply(c("speaker_type", "reference_geography", "register", "outlet_segment"), function(f) sum(composition(f)$articles) == 4, logical(1L))), "single-valued composition facets partition the article union")
  sensitivity <- function(variant, scope = "siri") {
    x <- tables$sensitivity
    x[x$frequency == "monthly" & x$scope == scope & x$period_id == "2024-01" & x$variant == variant, , drop = FALSE]
  }
  for (variant in c("without_confessional", "without_political_portals")) {
    x <- sensitivity(variant)
    check(x$total_articles == 930 && x$matching_articles == 3 && x$panel_outlets == 3 && x$filter_basis == "outlet_subset_N_D_P", paste("outlet sensitivity changes N D P:", variant))
  }
  church <- sensitivity("without_church_speakers")
  check(church$total_articles == 1240 && church$matching_articles == 2 && church$panel_outlets == 4, "church exclusion changes the numerator only")
  check(sensitivity("without_church_speakers", "uze")$matching_articles == 3, "a church speaker on an excluded B passage does not remove narrow A1")
  hdz <- sensitivity("without_registered_HDZ_only")
  check(hdz$total_articles == 1240 && hdz$matching_articles == 3 && hdz$panel_outlets == 4 && sensitivity("without_registered_HDZ_only", "uze")$matching_articles == 2, "registered actor-only exclusion preserves common N and P")
  check(all(tables$outlets$eligible_articles == 620) && !any(c("matching_articles", "D", "doc_key", "article_hash") %in% names(tables$outlets)), "public outlet inventory contains annual denominators only")
  check(!length(barometar_public_inspect(tables)$issues), "aggregate release tables contain no private fields or links")
  concentration <- tables$concentration
  january <- concentration[concentration$frequency == "monthly" & concentration$period_id == "2024-01", ]
  check(all(january$top10_share == 1) && close(january$hhi[january$scope == "siri"], .25) &&
    close(january$hhi[january$scope == "uze"], 1/3), "anonymous concentration uses scope-specific numerator shares")
  check(all(is.na(concentration$hhi[concentration$period_id == "2024-03"])) &&
    !any(c("outlet_id", "display_name", "D", "matching_articles") %in% names(concentration)),
    "zero-numerator concentration is undefined and no outlet numerators are disclosed")
  larger_panel <- panel[rep(1L, 12L), ]; rownames(larger_panel) <- NULL
  larger_panel$outlet_id <- paste0("invented-", 1:12)
  larger_panel$display_name <- paste("Invented outlet", 1:12)
  larger_panel$outlet_domain <- paste0("invented-", 1:12, ".example.invalid")
  larger_denominator <- expand.grid(day = days$day[days$observed], outlet_id = larger_panel$outlet_id, stringsAsFactors = FALSE)
  larger_denominator$N <- 10L
  larger_decisions <- decisions[rep(4L, 13L), ]; rownames(larger_decisions) <- NULL
  larger_decisions$doc_key <- paste0("invented-larger-", 1:13)
  larger_decisions$outlet_id <- c(larger_panel$outlet_id[1L], larger_panel$outlet_id)
  larger_tables <- build(d = larger_denominator, a = larger_decisions, p = larger_panel, routes = "A1", scopes = "uze")
  larger <- larger_tables$concentration
  larger <- larger[larger$frequency == "monthly" & larger$period_id == "2024-01", ]
  check(close(larger$top10_share, 11/13) && close(larger$hhi, 15/169), "top-ten concentration truncates to ten ranked outlet contributions")
  scoped_validation <- data.frame(scope = c("siri", "uze"), theme_id = "politics", theme_status = c("confirmed", "unconfirmed"))
  narrow_tables <- build(scopes = "uze", validation = scoped_validation)
  scoped <- names(narrow_tables)[vapply(narrow_tables, function(x) "scope" %in% names(x), logical(1L))]
  check(all(vapply(narrow_tables[scoped], function(x) all(x$scope == "uze"), logical(1L))), "narrow-only release has no broad rows in any scoped artifact")
  validation <- list(release_scope = "uze", accepted_routes = c("A1", "B", "C"), human_validation_complete = FALSE)
  summary <- barometar_release_summary(narrow_tables, versions, days, panel, validation, synthetic = TRUE)
  check(identical(summary$available_scopes, "uze") && summary$default_scope == "uze" && !summary$human_validation_complete, "narrow-only synthetic summary neither offers broad scope nor claims human precision")
  check(summary$cards$weekly$frequency == "rolling28" && summary$cards$weekly$period_end == summary$weekly_comparison$period_end && summary$cards$weekly$coverage_days_calendar == 28L, "weekly headline is trailing 28 days ending with the latest complete week")
  check(summary$weekly_comparison$frequency == "weekly", "weekly comparison retains the non-overlapping weekly estimate")
  check(!length(barometar_public_inspect(summary)$issues), "release summary contains no private fields")

  # Exercise the real writer and loader, with only invented aggregates. The
  # checked dictionary is public method metadata, never corpus material.
  source("studies/demokrscanstvo-barometar/08_aggregate.R", encoding = "UTF-8")
  source("R/lib/barometar_page.R", encoding = "UTF-8")
  definition <- barometar_definition()
  validation$validation <- data.frame(route = character(), stratum = character(), n = integer(), k = integer(), precision = numeric())
  validation$per_batch <- data.frame(route = "A1", source_batch = "invented", n = 20L, k = 18L, precision = .9, lo = .7, hi = .98)
  validation$theme_precision <- data.frame(theme_id = "politics", n = 10L, k = 8L, precision = .8, theme_status = "confirmed")
  validation$miss_diagnostics <- data.frame(stratum = "recall_probe", n = 20L, misses = 1L, fraction = .05, lo = .01, hi = .2)
  validation$route_set_precision <- data.frame(route_set = "A1", population_share = 1, precision = .9)
  validation$broad_precision <- .9
  validation$agreement <- c(kappa = .8, agreement = .9)
  validation$construct_agreement <- c(kappa = .7, agreement = .85)
  validation$second_coder_n <- 20L
  validation$masked_evidence_losses <- 0L
  directory <- tempfile("barometar-release-audit-")
  barometar_write_release(narrow_tables, summary, definition, validation,
    data.frame(scope = character(), ratio = numeric(), lo = numeric(), hi = numeric()), directory)
  inventory <- jsonlite::fromJSON(file.path(directory, "definitions_v1.json"), simplifyVector = FALSE)
  public_entries <- setNames(inventory$entries, vapply(inventory$entries, `[[`, character(1L), "id"))
  check(all(vapply(definition$compiled, function(rule) {
    entry <- public_entries[[rule$id]]
    identical(as.character(unlist(entry$forms)), as.character(rule$entry$forms))
  }, logical(1L))), "public rule inventory retains enumerated surface forms")
  phrases <- Filter(function(rule) length(rule$entry$slots) > 0L, definition$compiled)
  check(length(phrases) > 0L && all(vapply(phrases, function(rule) {
    entry <- public_entries[[rule$id]]
    identical(as.character(unlist(entry$slots)), as.character(unlist(rule$entry$slots))) &&
      identical(as.character(entry$order), as.character(rule$entry$order)) &&
      identical(as.character(entry$gap_max), as.character(rule$entry$gap_max))
  }, logical(1L))), "public rule inventory retains phrase slots, order and gap limits")
  loaded <- barometar_read_release(directory, synthetic_allowed = TRUE)
  check(all(vapply(loaded$tables, function(x) all(x$scope == "uze"), logical(1L))), "written narrow-only package reloads without broad series")
  check(rejects(barometar_read_release(directory)), "synthetic package cannot load as a production release")
  diagnostic_files <- paste0("validation_", c("per_batch", "theme_precision", "miss_diagnostics", "route_set_precision"), ".csv")
  check(all(file.exists(file.path(directory, diagnostic_files))), "public diagnostic exports include batch/theme/miss/route-set estimates")
  public_validation <- jsonlite::fromJSON(file.path(directory, "validation_summary.json"), simplifyVector = FALSE)
  check(!public_validation$human_validation_complete && public_validation$broad_precision == .9 &&
    public_validation$double_coded_items == 20L && !length(barometar_public_inspect(public_validation)$issues),
    "invented validation summary preserves aggregate diagnostics without human certification")
  check(!any(file.exists(file.path(directory, c("monthly_siri.csv", "weekly_siri.csv")))) &&
    all(file.exists(file.path(directory, c("monthly_uze.csv", "weekly_uze.csv", "concentration.csv")))),
    "scope-specific downloads and concentration preserve narrow-only availability")
  files <- list.files(directory, recursive = TRUE, full.names = TRUE)
  bytes <- lapply(files, function(path) readBin(path, "raw", n = file.info(path)$size))
  check(all(vapply(bytes, function(x) !as.raw(13L) %in% x, logical(1L))), "written release files use LF endings")
  csv <- grepl("[.]csv$", files)
  check(all(vapply(bytes[csv], function(x) identical(head(x, 3L), as.raw(c(239L, 187L, 191L))), logical(1L))), "CSV artifacts have a UTF-8 BOM")
  writeLines("invented tampering", file.path(directory, "monthly.csv"), useBytes = TRUE)
  check(rejects(barometar_read_release(directory, synthetic_allowed = TRUE)), "release loader rejects modified artifact hashes")

  # Invariant fixtures: malformed upstream counts must never become a release.
  duplicate <- rbind(denominator, denominator[1L, ])
  check(rejects(barometar_daily_facts(duplicate, decisions[1:4, ], panel$outlet_id, "siri")), "duplicate denominator rows are rejected")
  missing <- denominator[!(denominator$day == "2024-01-08" & denominator$outlet_id == "a"), ]
  check(rejects(barometar_daily_facts(missing, decisions[1:4, ], panel$outlet_id, "siri")), "positive outside denominator is rejected")
  bad <- denominator; bad$N[1L] <- NA_real_
  check(rejects(barometar_daily_facts(bad, decisions[1:4, ], panel$outlet_id, "siri")), "missing denominator count is rejected")
  bad <- denominator; bad$N[1L] <- 0
  check(rejects(barometar_daily_facts(bad, decisions[1:4, ], panel$outlet_id, "siri")), "zero row denominator is rejected")
  bad <- denominator; bad$N[1L] <- Inf
  check(rejects(barometar_daily_facts(bad, decisions[1:4, ], panel$outlet_id, "siri")), "nonfinite denominator count is rejected")
  bad <- denominator; bad$N[1L] <- 1.5
  check(rejects(barometar_daily_facts(bad, decisions[1:4, ], panel$outlet_id, "siri")), "fractional denominator count is rejected")
  impossible <- barometar_daily_facts(denominator, decisions[1:4, ], panel$outlet_id, "siri")
  impossible$D[1L] <- impossible$N[1L] + 1L
  check(rejects(barometar_aggregate_daily(impossible, days, panel$outlet_id, versions, "monthly")), "numerator larger than denominator cannot produce a period")
  check(rejects(build(a = rbind(decisions, decisions[1L, ]))), "duplicate classified article keys are rejected")
  check(rejects(build(routes = "B", scopes = "uze")), "narrow publication requires accepted A1")

  cat("Barometer release audit: ", checked - length(failures), "/", checked, " invented checks passed.\n", sep = "")
  if (length(failures)) {
    cat(paste0("- ", failures, collapse = "\n"), "\n")
    if (strict) stop("Release audit failed.", call. = FALSE)
  }
  invisible(list(checks = checked, failures = failures))
}
run_barometar_release_audit_tests()
