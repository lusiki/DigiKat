# Independent regression probes for validation design and private human context.
# All rows, labels and passages below are invented. No source database, private
# artifact or empirical coding sheet is read. Source from the repository root.
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/barometar_engine.R", encoding = "UTF-8")
source("R/lib/barometar_validation.R", encoding = "UTF-8")
source("R/lib/barometar_coding.R", encoding = "UTF-8")

run_barometar_validation_audit_tests <- function() {
  failures <- character()
  checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  close <- function(x, y) isTRUE(all.equal(unname(x), unname(y), tolerance = 1e-10))
  fails <- function(expr) inherits(tryCatch({ force(expr); NULL }, error = identity), "error")
  contains <- function(x, literal) isTRUE(stringi::stri_detect_fixed(x, literal))
  population <- function(routes, batches = rep("luka_opce", length(routes))) {
    data.frame(item_id = sprintf("invented-audit-%04d", seq_along(routes)),
      development = FALSE, route_set = routes, source_batch = batches,
      near_miss = FALSE, recall_probe = FALSE, themes = "work", stringsAsFactors = FALSE)
  }
  coding <- function(ids, truth, type) {
    at <- match(ids, truth$item_id)
    stopifnot(!anyNA(at))
    data.frame(item_id = ids, coder_type = type, qualifies = truth$qualifies[at],
      construct = truth$construct[at], speaker_type = "ostalo / nepripisano",
      geography = "domaće", register = "supstancijski", themes = truth$themes[at],
      axis1 = "genuine", axis2 = "domestic", axis3 = "both", axis4 = "other",
      masked_evidence = "ne", stringsAsFactors = FALSE)
  }
  sheets <- function(draw, truth) {
    ids <- draw$assignments$item_id
    list(pi = coding(ids, truth, "human_PI"),
      second = coding(ids[draw$assignments$double_code], truth, "human_second"),
      adjudicated = coding(ids, truth, "human_PI_adjudicated"))
  }
  score <- function(draw, labels) barometar_score_validation(
    draw, labels$pi, labels$second, labels$adjudicated, "invented-audit-definition")

  # A short post-seam stratum is a census, with the unused quota transferred.
  # The route's population precision is 90%, not the unweighted sample's 5/6.
  pop <- population(rep("A1", 100L), c(rep("luka_opce", 90L), rep("mediaspace_full", 10L)))
  draw <- barometar_validation_draw(pop)
  truth <- data.frame(item_id = pop$item_id,
    qualifies = ifelse(pop$source_batch == "luka_opce", "da", "ne"),
    construct = ifelse(pop$source_batch == "luka_opce", "A1", "ništa"), themes = "work")
  labels <- sheets(draw, truth)
  result <- score(draw, labels)
  route <- result$validation[result$validation$route == "A1", ]
  design <- draw$design[draw$design$stratum == "A1", ]
  check(identical(draw, barometar_validation_draw(pop)), "draw is reproducible")
  check(sum(design$n) == 60L && route$n == 60L, "route quota is 60 after reallocation")
  check(design$n[design$batch == "luka_opce"] == 50L &&
    design$n[design$batch == "mediaspace_full"] == 10L, "90/10 frame draws 50/10")
  check(close(route$precision, .9) && route$k == 50L, "route precision uses 90/10 population weights")
  check(route$gate == "accepted", "population 90% route passes the 80% gate")
  check(close(result$broad_precision, .9), "broad route-set precision uses inclusion weights")
  check(all(draw$assignments$selection_probability[draw$assignments$source_batch == "luka_opce"] == 50/90) &&
    all(draw$assignments$selection_probability[draw$assignments$source_batch == "mediaspace_full"] == 1),
    "stored inclusion probabilities reflect reallocation and census")
  check(route$interval_method == "Wilson_Kish" && route$n_eff > 0 && route$n_eff < route$n &&
    route$lo < route$precision && route$precision < route$hi,
    "weighted interval is explicitly labelled and has valid bounds")
  check(result$per_batch$precision[result$per_batch$source_batch == "luka_opce"] == 1 &&
    result$per_batch$precision[result$per_batch$source_batch == "mediaspace_full"] == 0,
    "batch precision is reported separately")
  check(result$release_scope == "siri" && result$broad_publishable, "passing draw selects broad release")
  check(close(result$theme_precision$precision[result$theme_precision$theme_id == "work"], .9),
    "theme precision accounts for unequal inclusion probabilities")

  masked_labels <- labels
  masked_labels$adjudicated$masked_evidence[1L] <- "da"
  masked <- score(draw, masked_labels)
  check(masked$masked_evidence_losses == 1L && masked$release_scope == "none" &&
    !masked$broad_publishable && !masked$narrow_publishable,
    "one confirmed masked argument blocks every release scope")

  # Diagnostic strata are not inclusion routes. Human A? resolution is retained.
  pop <- population(rep(c("A1", "A2", "A?", "A1;D"), each = 25L),
    rep(c("luka_opce", "mediaspace_full"), each = 50L))
  draw <- barometar_validation_draw(pop)
  truth <- data.frame(item_id = pop$item_id,
    qualifies = ifelse(pop$route_set == "A2", "ne", "da"),
    construct = ifelse(pop$route_set == "A?", "A1", pop$route_set), themes = "work")
  labels <- sheets(draw, truth)
  result <- score(draw, labels)
  a2 <- result$validation[result$validation$route == "A2", ]
  d <- result$validation[result$validation$route == "D", ]
  check(a2$n == 25L && a2$k == 25L && a2$precision == 1 && a2$gate == "diagnostic",
    "correct A2-only negative qualifications score as correct A2 labels")
  check(d$precision == 1 && d$gate == "diagnostic" && !"D" %in% result$accepted_routes,
    "D is scored but never admitted as an inclusion route")
  check(!"A?" %in% result$validation$route && sum(result$unresolved_resolution$Freq) == 25L,
    "A? yields a complete human resolution table rather than impossible precision")
  check(close(result$construct_agreement[["kappa"]], 1), "identical multi-label coders agree")
  reordered <- labels
  reordered$second$construct[reordered$second$construct == "A1;D"] <- "D;A1"
  check(close(score(draw, reordered)$construct_agreement[["kappa"]], 1),
    "construct set order does not create disagreement")
  discordant <- labels
  discordant$second$construct[discordant$second$construct == "A1;D"] <- "A1"
  disagreement <- score(draw, discordant)
  check(disagreement$construct_agreement[["agreement"]] < 1 &&
    disagreement$construct_agreement[["kappa"]] < 1,
    "omitting D is visible in full construct-set agreement")
  shuffled <- labels
  shuffled$pi <- shuffled$pi[nrow(shuffled$pi):1L, ]
  shuffled$adjudicated <- shuffled$adjudicated[nrow(shuffled$adjudicated):1L, ]
  check(identical(score(draw, shuffled)$validation, result$validation), "coding joins use IDs, not row positions")
  invalid <- labels$pi
  invalid$construct[1L] <- "A1;ništa"
  check(fails(barometar_validate_coding(invalid, draw$assignments$item_id, "human_PI")),
    "nothing cannot accompany a positive construct")
  invalid <- labels$pi
  invalid$axis4[1L] <- "unknown-register"
  check(fails(barometar_validate_coding(invalid, draw$assignments$item_id, "human_PI")),
    "unrecognized codebook labels are rejected")

  # Do not count a positive *dropped* human construct as correct in the retained
  # union. Both marginal samples are censuses, so no sampling noise is involved.
  pop <- population(rep("A1;C", 20L))
  draw <- barometar_validation_draw(pop)
  truth <- data.frame(item_id = pop$item_id, qualifies = "da",
    construct = c(rep("A1", 16L), rep("C", 4L)), themes = "work")
  result <- score(draw, sheets(draw, truth))
  check(identical(result$accepted_routes, "A1"), "only the 80% A1 route is retained")
  check(close(result$broad_precision, .8), "accepted-union truth excludes dropped human C-only constructs")
  check(close(result$theme_precision$precision[result$theme_precision$theme_id == "work"], .8),
    "theme truth also requires a retained human inclusion construct")

  # A false-positive probe is counted only within its declared rejection frame.
  pop <- population(rep("", 8L))
  pop$near_miss <- pop$recall_probe <- TRUE
  draw <- barometar_validation_draw(pop)
  truth <- data.frame(item_id = pop$item_id,
    qualifies = rep(c("da", "ne"), each = 4L),
    construct = rep(c("B", "ništa"), each = 4L), themes = "work")
  result <- score(draw, sheets(draw, truth))
  check(all(result$miss_diagnostics$n == 8L) && all(result$miss_diagnostics$misses == 4L) &&
    all(result$miss_diagnostics$fraction == .5), "miss diagnostics retain their own frame denominators")
  check(result$release_scope == "none" && !result$broad_publishable,
    "positive recall probes alone do not create a publishable route")

  # Context coordinates are derived from the original unmasked paragraphs.
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  filler <- paste(rep("Ovaj izmišljeni odlomak služi samo za provjeru duljine.", 90L), collapse = " ")
  before <- "NEPOSREDNI PRETHODNI ODJELJAK objašnjava pozadinu izmišljenoga razgovora."
  late <- "KASNI SINTETIČKI MARKER: Stranka se poziva na demokršćanska načela."
  after <- "NEPOSREDNI SLJEDEĆI ODJELJAK zaključuje izmišljeni razgovor."
  body <- paste(c(paste("RANI NEPOVEZANI MARKER", filler), "Drugi neutralni odlomak.",
    before, late, after, "ZAVRŠNI NEPOVEZANI MARKER"), collapse = "\n\n")
  context <- barometar_coding_context("Izmišljeni naslov", body, definition)
  check(stringi::stri_locate_first_fixed(body, "KASNI SINTETIČKI MARKER")[1L] > 3000L &&
    contains(context$passage, late), "late evidence beyond character 3000 reaches the human coder")
  check(contains(context$passage, before) && contains(context$passage, after),
    "late evidence retains adjacent complete paragraphs")
  check(!contains(context$passage, "RANI NEPOVEZANI MARKER") &&
    !contains(context$passage, "ZAVRŠNI NEPOVEZANI MARKER"),
    "unrelated remote paragraphs are not substituted for late evidence")
  check(identical(names(context), c("passage", "mask_audit")),
    "context payload contains no automatic routes, matches or facets")

  boiler <- "Kršćanska etika i solidarnost pojavljuju se samo u ovom izmišljenom ponovljenom predlošku."
  key <- digest::digest(barometar_boilerplate_key_text(boiler), algo = "md5", serialize = FALSE)
  multi_body <- paste(boiler, body,
    "DRUGI KONSTRUKT: Socijalni nauk Crkve zahtijeva izmjene zakona.", sep = "\n\n")
  context <- barometar_coding_context("Izmišljeni naslov", multi_body, definition, key)
  check(contains(context$passage, late) && contains(context$passage, "DRUGI KONSTRUKT"),
    "independent early and late construct passages both reach human coding")
  check(identical(context$mask_audit, boiler) && contains(context$passage, boiler),
    "masked original argument is independently available for human loss review")
  check(!contains(context$mask_audit, late), "unmasked evidence is not mislabeled as a masked segment")
  title <- "Demokršćanstvo kao ideja u izmišljenoj raspravi"
  title_body <- paste0(title, ": PRVI TJELESNI ODJELJAK daje dodatni izmišljeni kontekst.\n", filler)
  context <- barometar_coding_context(title, title_body, definition)
  check(contains(context$passage, title) && contains(context$passage, "PRVI TJELESNI ODJELJAK"),
    "title evidence is accompanied by the first body paragraph")

  if (length(failures)) stop("Barometer validation audit: ", length(failures), "/", checked,
    " failed:\n- ", paste(failures, collapse = "\n- "), call. = FALSE)
  cat("Barometer validation audit: ", checked,
    " invented sampling, scoring, agreement and context checks passed.\n", sep = "")
  invisible(TRUE)
}

run_barometar_validation_audit_tests()
