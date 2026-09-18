# Independent publication-policy regressions using invented labels only.
# The real frozen scorer supplies every primary case; no empirical artifact,
# source database, human export, gate or release is read or changed.
source("studies/demokrscanstvo-barometar/06_validation_score.R", encoding = "UTF-8")

run_barometar_release_policy_tests <- function() {
  frozen_paths <- c("R/lib/barometar_validation.R", "R/lib/barometar_engine.R", "R/lib/barometar_metrics.R")
  before <- vapply(frozen_paths, digikat_hash_file, character(1L))
  fixture <- function(a1_correct = 0L, include_a1 = TRUE, disagree = FALSE, masked = FALSE) {
    routes <- c(if (include_a1) rep("A1", 20L), rep("B", 20L), rep("C", 20L), rep("", 10L))
    pop <- data.frame(item_id = sprintf("invented-policy-%03d", seq_along(routes)), development = FALSE,
      route_set = routes, source_batch = "luka_opce", near_miss = FALSE, recall_probe = routes == "", themes = "work")
    draw <- barometar_validation_draw(pop)
    truth <- ifelse(routes %in% c("B", "C"), routes, "ništa")
    if (include_a1 && a1_correct > 0L) truth[seq_len(a1_correct)] <- "A1"
    labels <- function(ids, role) {
      constructs <- truth[match(ids, pop$item_id)]
      data.frame(item_id = ids, coder_type = role, qualifies = ifelse(constructs == "ništa", "ne", "da"),
        construct = constructs, speaker_type = "ostalo / nepripisano", geography = "domaće", register = "supstancijski",
        themes = "work", axis1 = "genuine", axis2 = "domestic", axis3 = "both", axis4 = "other", masked_evidence = "ne")
    }
    ids <- draw$assignments$item_id
    second <- labels(ids[draw$assignments$double_code], "human_second")
    if (disagree) second$qualifies <- ifelse(second$qualifies == "da", "ne", "da")
    final <- labels(ids, "human_PI_adjudicated")
    if (masked) final$masked_evidence[1L] <- "da"
    raw <- barometar_score_validation(draw, labels(ids, "human_PI"), second, final, "invented-policy-v1")
    list(raw = raw, policy = barometar_apply_release_policy(raw))
  }
  cases <- list(dropped = fixture(0L), experimental = fixture(14L), unvalidated = fixture(include_a1 = FALSE),
    accepted_broad = fixture(16L), accepted_narrow = fixture(16L, disagree = TRUE), masked = fixture(16L, masked = TRUE))
  checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) stop("Release policy fixture failed: ", label)
  }
  for (name in names(cases)) {
    x <- cases[[name]]
    diagnostics <- setdiff(names(x$raw), c("broad_publishable", "narrow_publishable", "release_scope"))
    check(identical(x$raw[diagnostics], x$policy[diagnostics]), paste(name, "preserves every statistical diagnostic"))
    check(identical(barometar_apply_release_policy(x$policy), x$policy), paste(name, "is idempotent"))
  }
  for (name in c("dropped", "experimental", "unvalidated")) {
    x <- cases[[name]]
    check(isTRUE(x$raw$broad_publishable) && x$raw$release_scope == "siri", paste(name, "reproduces the frozen scorer counterexample"))
    check(!x$policy$broad_publishable && !x$policy$narrow_publishable && x$policy$release_scope == "none" &&
      x$policy$release_policy == "no_go_A1", paste(name, "blocks all empirical publication"))
  }
  check(identical(cases$accepted_broad$raw, cases$accepted_broad$policy) && cases$accepted_broad$policy$release_scope == "siri",
    "accepted A1 preserves passing broad publication")
  check(identical(cases$accepted_narrow$raw, cases$accepted_narrow$policy) && cases$accepted_narrow$policy$release_scope == "uze",
    "accepted A1 preserves narrow fallback after poor agreement")
  check(cases$masked$policy$release_scope == "none" && !cases$masked$policy$broad_publishable && !cases$masked$policy$narrow_publishable,
    "a confirmed masking loss still blocks publication")
  valid <- cases$accepted_broad$raw
  for (variant in c("duplicate", "missing", "nonfinite", "route_missing", "narrow_false")) {
    x <- valid
    if (variant == "duplicate") x$validation <- rbind(x$validation, x$validation[x$validation$route == "A1", ])
    if (variant == "missing") x$validation <- x$validation[x$validation$route != "A1", ]
    if (variant == "nonfinite") x$validation$precision[x$validation$route == "A1"] <- Inf
    if (variant == "route_missing") x$accepted_routes <- c("B", "C")
    if (variant == "narrow_false") x$narrow_publishable <- FALSE
    check(barometar_apply_release_policy(x)$release_scope == "none", paste(variant, "A1 evidence fails closed"))
  }
  check(identical(before, vapply(frozen_paths, digikat_hash_file, character(1L))), "frozen implementation files remain unchanged")
  cat(sprintf("PASS: %d independent invented A1 release-policy checks.\n", checked))
  invisible(checked)
}

run_barometar_release_policy_tests()
