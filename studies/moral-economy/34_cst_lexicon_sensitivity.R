#!/usr/bin/env Rscript
# Construct sensitivity for the explicit Tier-1 CST marker repertoire.
#
# A pair can carry several adjacent Tier-1 terms. Each specification removes a term (or the grouped
# ecology-specific markers) and retains the pair if at least one non-removed adjacent term remains.
# Denominators stay fixed because this test concerns numerator construction, not Stage-A linkage.
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))

rsp_assert_official_inputs()
core <- cst_build_core(verbose = FALSE)
pairs <- cst_core_pairs(core)
cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand_pairs <- unique(data.frame(rid = as.integer(cand$rid), domain = as.character(cand$domain)))
den <- as.data.frame(table(domain = factor(cand_pairs$domain, levels = names(ME_ECON))),
                     stringsAsFactors = FALSE)
names(den)[2] <- "linked_pairs"

t1 <- names(CST_TERMS)[CST_TIER %in% c("1_document", "1_marker")]
specs <- c(list(baseline = character()), stats::setNames(lapply(t1, function(x) x),
                                                         paste0("leave_out_", t1)))
specs$leave_out_ecology_markers <- c("laudato_si", "laudate_deum", "integralna_ekologija")

term_sets <- strsplit(pairs$terms, "\\s+")
detail <- do.call(rbind, lapply(names(specs), function(spec) {
  omitted <- specs[[spec]]
  keep <- vapply(term_sets, function(tt) any(!tt %in% omitted), logical(1))
  num <- as.data.frame(table(domain = factor(pairs$domain[keep], levels = names(ME_ECON))),
                       stringsAsFactors = FALSE)
  names(num)[2] <- "core_pairs"
  z <- merge(den, num, by = "domain", sort = FALSE)
  z$detected_rate <- 100 * z$core_pairs / z$linked_pairs
  z$specification <- spec
  z$omitted_terms <- if (length(omitted)) paste(omitted, collapse = " ") else "none"
  z
}))
detail$detected_rate <- round(detail$detected_rate, 4)

summary <- do.call(rbind, lapply(split(detail, detail$specification), function(z) {
  z <- z[order(-z$detected_rate, z$domain), ]
  data.frame(specification = z$specification[1], omitted_terms = z$omitted_terms[1],
             retained_core_pairs = sum(z$core_pairs), top_domain = z$domain[1],
             top_rate = z$detected_rate[1], runner_up = z$domain[2],
             runner_rate = z$detected_rate[2], green_rate = z$detected_rate[z$domain == "green_energy"],
             green_first = z$domain[1] == "green_energy", stringsAsFactors = FALSE)
}))
summary <- summary[match(names(specs), summary$specification), ]
rownames(summary) <- NULL

# Apply the fresh R4 domain precision only as the same denominator-only sensitivity used in step 20.
# This does not turn the ratios into validated prevalence estimates; every detected numerator pair is
# still assumed to qualify. Rank shares are conditional posterior-simulation summaries, not p-values.
prec <- read.csv(file.path(ME_OUT, "r4_linkage_precision.csv"), fileEncoding = "UTF-8",
                 stringsAsFactors = FALSE)
if (!all(c("code", "domain", "k", "n", "precision") %in% names(prec)) ||
    !setequal(unique(prec$code), c("ax1_link_genuine", "ax1_strict"))) {
  stop("Fresh R4 precision output is missing or malformed; run step 20 before step 34.", call. = FALSE)
}
DRAWS <- 20000L
adj_rows <- list(); adj_summary <- list(); q <- 0L
for (spec in names(specs)) for (code in c("ax1_link_genuine", "ax1_strict")) {
  z <- detail[detail$specification == spec, ]
  pp <- prec[prec$code == code, ]
  pp <- pp[match(z$domain, pp$domain), ]
  if (anyNA(pp$k) || any(pp$n <= 0L)) stop("R4 precision domains do not match lexicon sensitivity.")
  z$code <- code
  z$denominator_sensitivity_rate <- z$detected_rate / (pp$precision / 100)
  set.seed(ME_SEED + match(spec, names(specs)) + if (code == "ax1_strict") 1000L else 0L)
  P <- matrix(rbeta(DRAWS * nrow(z), rep(pp$k + 0.5, each = DRAWS),
                    rep(pp$n - pp$k + 0.5, each = DRAWS)), nrow = DRAWS)
  R <- matrix(rep(z$detected_rate, each = DRAWS), nrow = DRAWS) / P
  colnames(R) <- z$domain
  first <- colnames(R)[apply(R, 1, which.max)]
  ord <- order(-z$denominator_sensitivity_rate, z$domain)
  q <- q + 1L
  adj_rows[[q]] <- z
  adj_summary[[q]] <- data.frame(
    specification = spec, code = code,
    adjusted_top_domain = z$domain[ord[1]], adjusted_top_rate = z$denominator_sensitivity_rate[ord[1]],
    adjusted_runner_up = z$domain[ord[2]], adjusted_runner_rate = z$denominator_sensitivity_rate[ord[2]],
    adjusted_green_rate = z$denominator_sensitivity_rate[z$domain == "green_energy"],
    adjusted_green_first_share = mean(first == "green_energy"), stringsAsFactors = FALSE)
}
adjusted <- do.call(rbind, adj_rows)
adjusted_summary <- do.call(rbind, adj_summary)
for (nm in c("denominator_sensitivity_rate")) adjusted[[nm]] <- round(adjusted[[nm]], 4)
for (nm in c("adjusted_top_rate", "adjusted_runner_rate", "adjusted_green_rate"))
  adjusted_summary[[nm]] <- round(adjusted_summary[[nm]], 4)
adjusted_summary$adjusted_green_first_share <- round(adjusted_summary$adjusted_green_first_share, 5)

base <- detail[detail$specification == "baseline", ]
if (sum(base$core_pairs) != nrow(pairs) ||
    !identical(as.integer(base$core_pairs),
               as.integer(table(factor(pairs$domain, levels = base$domain))))) {
  stop("Lexicon-sensitivity baseline does not reproduce the canonical core.", call. = FALSE)
}

sem_write_shareable(detail, file.path(ME_OUT, "cst_lexicon_sensitivity.csv"))
sem_write_shareable(summary, file.path(ME_OUT, "cst_lexicon_sensitivity_summary.csv"))
sem_write_shareable(adjusted, file.path(ME_OUT, "cst_lexicon_sensitivity_adjusted.csv"))
sem_write_shareable(adjusted_summary,
                    file.path(ME_OUT, "cst_lexicon_sensitivity_adjusted_summary.csv"))
digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/34_cst_lexicon_sensitivity.R",
  inputs = list(database_sha256 = rsp_read_input_manifest()$database$sha256,
                core_sha256 = digikat_hash_file(RSP_CORE_CACHE),
                candidates_sha256 = digikat_hash_file(RSP_STAGEA_CANDIDATES),
                r4_precision_sha256 = digikat_hash_file(file.path(ME_OUT, "r4_linkage_precision.csv"))),
  outputs = list(detail = "output/cst_lexicon_sensitivity.csv",
                 detail_sha256 = digikat_hash_file(file.path(ME_OUT, "cst_lexicon_sensitivity.csv")),
                 summary = "output/cst_lexicon_sensitivity_summary.csv",
                 summary_sha256 = digikat_hash_file(file.path(ME_OUT, "cst_lexicon_sensitivity_summary.csv")),
                 adjusted = "output/cst_lexicon_sensitivity_adjusted.csv",
                 adjusted_sha256 = digikat_hash_file(file.path(ME_OUT, "cst_lexicon_sensitivity_adjusted.csv")),
                 adjusted_summary = "output/cst_lexicon_sensitivity_adjusted_summary.csv",
                 adjusted_summary_sha256 = digikat_hash_file(
                   file.path(ME_OUT, "cst_lexicon_sensitivity_adjusted_summary.csv"))),
  extra = list(ecology_markers = specs$leave_out_ecology_markers,
               rule = "retain a pair when at least one adjacent non-omitted Tier-1 term remains")
), file.path(ME_OUT, "cst_lexicon_sensitivity_manifest.json"))

print(summary, row.names = FALSE)
cat("\nKey denominator-sensitivity rows:\n")
print(adjusted_summary[adjusted_summary$specification %in%
  c("baseline", "leave_out_laudato_si", "leave_out_ecology_markers"), ], row.names = FALSE)
cat("wrote raw and denominator-sensitivity lexicon outputs\n")
