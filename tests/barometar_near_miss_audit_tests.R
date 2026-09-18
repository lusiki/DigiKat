# Independent invented-hit regression cases for the bounded R3 near-miss frame.
# Authorized amendment: one absent lexical condition within one attached clause;
# attachment-only and distance-only cases are outside this diagnostic stratum.
# No database, private material or empirical human label is read.
# Source from the repository root, then call the function. The optional
# strict=FALSE mode prints unresolved failures while implementation is reviewed.
source("R/lib/barometar_engine.R", encoding = "UTF-8")

run_barometar_near_miss_audit_tests <- function(strict = TRUE) {
  evidence <- function(family, source, tier, token,
                       clause = rep(1L, length(family))) {
    txt <- paste(rep("x", max(token)), collapse = " ")
    positions <- seq.int(1L, nchar(txt), 2L)
    hits <- data.frame(
      family = family, source_group = source, tier = tier,
      token_start = token, token_end = token, clause_id = clause,
      sentence_id = 1L, excluded_reason = NA_character_,
      entry_id = paste0("invented_", seq_along(family)), form = family,
      field = "body", start = token * 2L - 1L, end = token * 2L - 1L,
      stringsAsFactors = FALSE
    )
    list(txt = txt, hits = hits,
         tokens = data.frame(start = positions, end = positions),
         sentences = data.frame(start = 1L, end = nchar(txt), sentence_id = 1L))
  }
  b_missing <- evidence(c("document", "connector"),
    c("doctrinal_anchors.yaml", "argument_connectors.yaml"),
    c("strong", "generic"), c(1L, 5L))
  b_two_failures <- b_missing
  b_two_failures$hits$clause_id <- c(1L, 2L)
  b_relation <- evidence(c("document", "public", "connector"),
    c("doctrinal_anchors.yaml", "public_context.yaml", "argument_connectors.yaml"),
    c("strong", "generic", "generic"), c(1L, 4L, 5L), c(1L, 2L, 2L))
  b_distance <- evidence(c("document", "public", "connector"),
    c("doctrinal_anchors.yaml", "public_context.yaml", "argument_connectors.yaml"),
    c("strong", "generic", "generic"), c(1L, 82L, 83L))
  b_distance_relation <- b_distance
  b_distance_relation$hits$clause_id <- c(1L, 2L, 2L)
  c_two_failures <- evidence(c("public", "solidarity", "worker_rights", "connector"),
    c("public_context.yaml", "concept_families.yaml", "concept_families.yaml", "argument_connectors.yaml"),
    rep("generic", 4L), c(1L, 3L, 4L, 6L), c(1L, 2L, 2L, 3L))
  excluded <- b_missing
  excluded$hits$excluded_reason[] <- "invented_explicit_exclusion"
  mayor_attribution <- evidence(c("public", "attribution"),
    c("public_context.yaml", "argument_connectors.yaml"),
    c("generic", "generic"), c(1L, 4L))
  mayor_attribution$hits$entry_id[1L] <- "public_institutions"
  mayor_attribution$hits$form[1L] <- "gradonačelnik"

  probes <- list(
    b_missing_public_only = b_missing,
    b_missing_public_and_attachment = b_two_failures,
    b_relation_only = b_relation,
    b_distance_only = b_distance,
    b_distance_and_relation = b_distance_relation,
    c_missing_grounding_and_relation = c_two_failures,
    all_hits_excluded = excluded,
    mayor_attribution_missing_anchor_and_application = mayor_attribution
  )
  actual <- lapply(probes, barometar_near_miss_conditions)
  expected_member <- c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)
  result <- data.frame(
    case = names(probes), expected_member = expected_member,
    actual_member = lengths(actual) > 0L,
    failed_conditions = vapply(actual, paste, character(1L), collapse = ";"),
    stringsAsFactors = FALSE
  )
  result$passed <- result$expected_member == result$actual_member
  print(result, row.names = FALSE)
  if (strict && any(!result$passed)) stop("Near-miss audit: ", sum(!result$passed), " failed membership checks.")
  invisible(result)
}

run_barometar_near_miss_audit_tests()
