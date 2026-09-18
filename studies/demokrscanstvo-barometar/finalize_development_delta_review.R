# Record the assistant's bounded development decisions, with snapshot checks.
# No human labels or empirical period indicators are produced.
source("studies/demokrscanstvo-barometar/03_candidates.R",encoding="UTF-8")
workdir <- barometar_workdir()
manifest <- readRDS(file.path(workdir,"development_review_manifest.rds"))
plan <- readRDS(file.path(manifest$folder,"nlp_delta_plan_private.rds"))
expected_version <- "1.0.0+33429974d0b8"
expected_hash <- "5f11b27f69e4779b07904921784124f249e8b0e6b32f587ef713aa2056c1c8b6"
actual_hash <- digest::digest(file=file.path(manifest$folder,"review-private.rds"),algo="sha256",serialize=FALSE)
stopifnot(identical(manifest$definition_version,expected_version),
  identical(plan$identity$definition_version,expected_version),
  identical(plan$identity$review_sha256,expected_hash),identical(actual_hash,expected_hash),
  identical(plan$delta$index,c(6L,56L,88L,97L,177L,179L)),
  identical(plan$delta$index,plan$delta$old_index),
  identical(attr(readRDS(file.path(workdir,"boilerplate.rds")),"boilerplate_version"),plan$identity$boilerplate_version))
findings <- plan$delta
findings$decision <- "accept_change"
findings$explanation <- c(
  "Reviewed Europe inflection supports the theme in the qualifying context.",
  "Application of social teaching to a party programme supports B; previous lexical miss repaired.",
  "Document calling for revision of economic policy supports B; past-feminine application repaired.",
  "Ecclesial council is not a political institution; inspected alternative passages do not independently satisfy political application.",
  "Ideological conservatism cue resolves the direct label to A1 rather than party-only A2.",
  "Reviewed Europe inflection supports the theme in the qualifying context.")
findings$critical_issue <- FALSE
findings$coder_type <- "assistant_development_review"
findings$definition_version <- expected_version
findings$boilerplate_version <- plan$identity$boilerplate_version
barometar_write_csv(findings,file.path(manifest$folder,"nlp_delta_findings_private.csv"))
acceptance <- list(definition_version=expected_version,recommendation="freeze",
  all_changed_cases_reviewed=TRUE,unresolved_critical_issues=0L,
  report="quality_reports/2026-09-18_barometar-development-delta-review.md",
  coder_type="assistant_development_review",boilerplate_version=plan$identity$boilerplate_version,
  review_sha256=expected_hash,changed_cases_reviewed=nrow(findings),new_samples=0L,
  review_date="2026-09-18",human_validation=FALSE)
jsonlite::write_json(acceptance,file.path(workdir,"development-acceptance.json"),auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(acceptance,auto_unbox=TRUE),"\n")
