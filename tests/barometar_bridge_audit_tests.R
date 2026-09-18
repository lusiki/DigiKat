# Independent aggregate-only bridge fixtures. All counts are invented.
run_barometar_bridge_audit_tests <- function(strict = TRUE) {
  audit <- new.env(parent = globalenv())
  sys.source("R/lib/barometar_bridge.R", envir = audit)
  previous_rng <- RNGkind()
  had_seed <- exists(".Random.seed", .GlobalEnv, inherits = FALSE)
  previous_seed <- if (had_seed) get(".Random.seed", .GlobalEnv) else NULL
  on.exit({
    do.call(RNGkind, as.list(previous_rng))
    if (had_seed) assign(".Random.seed", previous_seed, .GlobalEnv)
    else if (exists(".Random.seed", .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  failures <- character(); checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  rejects <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")
  close <- function(x, y) isTRUE(all.equal(unname(x), unname(y), tolerance = 1e-10))
  counts <- expand.grid(outlet_id = c("a", "b", "c"), batch = c("old", "new"),
    scope = c("siri", "uze"), stringsAsFactors = FALSE)
  counts$N <- c(100, 200, 50, 100, 200, 100, 100, 200, 50, 100, 200, 100)
  counts$D <- c(10, 20, 0, 20, 20, 10, 10, 0, 0, 0, 20, 0)
  estimate <- function(x = counts, panel = c("a", "b", "c"), reps = 100L)
    audit$barometar_bridge_estimate(x, panel, repetitions = reps)
  result <- estimate()
  narrow <- result[result$scope == "uze", ]; broad <- result[result$scope == "siri", ]
  check(narrow$N_old == 350 && narrow$N_new == 400 && narrow$D_old == 10 && narrow$D_new == 20,
    "point sums use pooled outlet counts")
  check(close(narrow$ratio, 1.75) && close(broad$ratio, 35/24), "point ratio is a ratio of pooled rates")
  check(narrow$breadth_difference_pp == 0 && close(broad$breadth_difference_pp, 100/3),
    "point breadth uses frozen panel denominator")

  # A deterministic supplied draw exposes duplicate-cluster handling directly.
  audit$sample.int <- function(n, size, replace) {
    stopifnot(n == 3L, size == 3L, isTRUE(replace))
    c(1L, 1L, 2L)
  }
  fixed <- estimate(reps = 2L)
  narrow <- fixed[fixed$scope == "uze", ]; broad <- fixed[fixed$scope == "siri", ]
  check(close(c(narrow$ratio_lo, narrow$ratio_hi), c(1, 1)), "fixed paired narrow ratio equals 1")
  check(close(c(narrow$breadth_lo, narrow$breadth_hi), rep(-100/3, 2L)), "duplicate outlet draws retain breadth multiplicity")
  check(close(c(broad$ratio_lo, broad$ratio_hi), c(1.5, 1.5)), "both scopes reuse the same draw")
  check(close(c(broad$breadth_lo, broad$breadth_hi), c(0, 0)), "paired broad breadth difference is zero")
  swapped <- counts; swapped$batch <- ifelse(counts$batch == "old", "new", "old")
  inverse <- estimate(swapped, reps = 2L)
  check(close(inverse$ratio_lo, 1/fixed$ratio_hi) && close(inverse$breadth_lo, -fixed$breadth_hi),
    "swapping instruments reciprocates ratios and negates paired differences")
  rm("sample.int", envir = audit)

  identical_capture <- counts
  identical_capture$N <- rep(c(100, 200, 50), 4L)
  identical_capture$D <- rep(c(10, 20, 5), 4L)
  same <- estimate(identical_capture, reps = 2000L)
  check(all(same$ratio == 1 & same$ratio_lo == 1 & same$ratio_hi == 1), "identical captures have degenerate ratio-one intervals")
  check(all(same$breadth_difference_pp == 0 & same$breadth_lo == 0 & same$breadth_hi == 0), "paired identical captures have zero breadth intervals")
  check(all(same$gate_pass) && all(same$bootstrap_repetitions == 2000L), "both estimable identical scopes pass the declared bridge thresholds")
  shifted <- identical_capture; shifted$D[shifted$batch == "new"] <- 2 * shifted$D[shifted$batch == "new"]
  check(!any(estimate(shifted)$gate_pass), "a doubled visibility ratio fails certification")
  zero <- identical_capture; zero$D[zero$batch == "old"] <- 0L
  zero_result <- estimate(zero)
  check(!any(zero_result$gate_pass) && all(is.na(zero_result$ratio_lo)) && all(zero_result$bootstrap_undefined == 100L),
    "zero old numerator is unavailable and never passes")
  check(all(is.finite(zero_result$breadth_lo)), "breadth intervals survive an undefined ratio")
  extra <- estimate(identical_capture, panel = c("a", "b", "c", "zero"))
  check(all(extra$panel_outlets == 4L & extra$M_old == 3L & extra$active_old == 3L), "frozen zero-count outlet stays in the paired panel")
  check(!any(extra$gate_pass), "insufficient active-outlet coverage blocks bridge")
  scarce <- identical_capture; scarce$N[] <- 4L; scarce$D[] <- 1L
  sparse <- estimate(scarce)
  check(all(sparse$M_old == 3L & sparse$active_old == 0L) && !any(sparse$gate_pass), "matching outlets may exceed monthly active outlets")
  check(identical(estimate(), estimate()), "fixed-seed bootstrap is deterministic")
  check(identical(estimate(), estimate(counts[nrow(counts):1L, ])), "count-row ordering cannot change the resampling frame")
  check(identical(estimate(), estimate(panel = c("c", "a", "b"))), "panel ordering is canonicalized before sampling")
  set.seed(1909L); rng_before <- RNGkind(); seed_before <- .Random.seed
  invisible(estimate())
  check(identical(rng_before, RNGkind()) && identical(seed_before, .Random.seed), "restore caller RNG kind and seed")
  rm(".Random.seed", envir = .GlobalEnv)
  invisible(estimate())
  check(!exists(".Random.seed", .GlobalEnv, inherits = FALSE), "do not leave a seed when caller had none")

  invalid <- identical_capture; invalid$D[1L] <- .5
  check(rejects(estimate(invalid)), "reject fractional article counts")
  invalid <- identical_capture; invalid$N[1L] <- Inf
  check(rejects(estimate(invalid)), "reject nonfinite article counts")
  invalid <- identical_capture; invalid$N[1L] <- 101L
  check(rejects(estimate(invalid)), "same outlet/batch denominator must agree across scopes")
  check(rejects(estimate(panel = c("a", "b", "c", NA_character_))), "reject missing panel IDs")
  check(rejects(estimate(panel = c("a", "b", "c", ""))), "reject empty panel IDs")
  check(rejects(estimate(reps = 2.5)), "reject fractional bootstrap repetitions")
  check(rejects(estimate(rbind(counts, counts[1L, ]))), "reject duplicate outlet/batch/scope rows")
  check(rejects(estimate(panel = c("a", "b", "a"))), "reject duplicate panel IDs")
  one <- identical_capture[identical_capture$outlet_id == "a", ]
  one_result <- tryCatch(estimate(one, panel = "a", reps = 2L), error = function(e) NULL)
  check(!is.null(one_result) && all(one_result$gate_pass), "one-outlet valid input retains a two-dimensional replicate matrix")

  if (length(failures) && strict) stop(paste(c("Bridge audit failed:", failures), collapse = "\n"))
  if (length(failures)) message(paste(c("Bridge audit unresolved:", failures), collapse = "\n"))
  else message("All ", checked, " invented bridge checks passed.")
  invisible(list(checked = checked, failures = failures))
}

run_barometar_bridge_audit_tests()
