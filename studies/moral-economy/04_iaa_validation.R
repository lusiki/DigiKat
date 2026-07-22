#!/usr/bin/env Rscript
# moral-economy GATE 2 — inter-annotator agreement + majority adjudication (NO master read).
# Reads N filled annotator copies of coding_sheet.csv, computes per-AXIS Fleiss' kappa (multi-rater)
# and the register axis at BOTH 5-way and collapsed 3-way (justice / charity / object) levels — the
# pre-prereg reliability check that decides at which level H1/H4 are tested (CODEBOOK.md; the sister
# study's register kappa was 0.46, the number to beat). Adjudicates majority labels -> coded_core.csv.
#
# Annotator files: output/coding_sheet_ann*.csv (>=2). Self-test: pass --selftest.
#   "/c/Program Files/R/R-4.4.1/bin/Rscript.exe" studies/moral-economy/04_iaa_validation.R
suppressPackageStartupMessages({ library(here); library(dplyr) })
out_dir <- here::here("studies/moral-economy/output")

AXES <- c("ax1_link_genuine","ax2_geography","ax3_actor_commentator",
          "ax4_register","ax5_poverty_split","ax6_ksn_principle","ax7_encyclical")

# Fleiss' kappa for a subjects x raters matrix of category labels (NA-tolerant per subject).
fleiss_kappa <- function(mat) {
  mat <- mat[apply(mat, 1, function(r) sum(!is.na(r)) >= 2), , drop = FALSE]  # need >=2 raters/subject
  if (!nrow(mat)) return(NA_real_)
  cats <- sort(unique(na.omit(as.vector(mat)))); if (length(cats) < 2) return(NA_real_)
  Pi <- apply(mat, 1, function(r) {
    r <- r[!is.na(r)]; n <- length(r); if (n < 2) return(NA_real_)
    (sum(table(factor(r, levels = cats))^2) - n) / (n * (n - 1))
  })
  n_per <- apply(mat, 1, function(r) sum(!is.na(r)))
  pj <- sapply(cats, function(cc) sum(mat == cc, na.rm = TRUE)) / sum(n_per)
  Pbar <- mean(Pi, na.rm = TRUE); Pe <- sum(pj^2)
  if (Pe >= 1) return(NA_real_); (Pbar - Pe) / (1 - Pe)
}
majority <- function(r) { r <- r[!is.na(r) & r != ""]; if (!length(r)) return(NA_character_)
  t <- sort(table(r), decreasing = TRUE); names(t)[1] }
collapse3 <- function(x) dplyr::case_when(
  x %in% c("object_institution","object_cost_relig_life") ~ "object",
  x == "justice" ~ "justice", x == "charity" ~ "charity",
  x %in% c("devotional","other","") ~ "remainder", TRUE ~ x)

# ---- self-test: fabricate 3 annotators with known agreement, verify the kappa math --------------
if ("--selftest" %in% commandArgs(trailingOnly = TRUE)) {
  set.seed(20260707)
  n <- 120; truth <- sample(c("object_institution","charity","justice","devotional"), n, TRUE, c(.5,.25,.1,.15))
  noisy <- function(p) sapply(truth, function(t) if (runif(1) < p) t else
    sample(c("object_institution","charity","justice","devotional"), 1))
  m <- cbind(noisy(.9), noisy(.85), noisy(.8))
  cat("self-test Fleiss kappa (register, 4-way):", round(fleiss_kappa(m), 3),
      "| 3-way:", round(fleiss_kappa(apply(m, 2, collapse3)), 3), "\n")
  cat("(expect 4-way ~0.6-0.75; 3-way >= 4-way since it merges the two object codes)\n"); quit(save = "no")
}

files <- list.files(out_dir, pattern = "^coding_sheet_ann.*\\.csv$", full.names = TRUE)
if (length(files) < 2) stop("Need >=2 annotator files output/coding_sheet_ann*.csv. (Run coding first; or --selftest.)")
ann <- lapply(files, read.csv, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
cat("Annotators:", length(ann), "| rows:", nrow(ann[[1]]), "\n")
ids <- ann[[1]]$rid
stopifnot(all(sapply(ann, function(a) identical(a$rid, ids))))   # aligned sheets

# per-axis kappa + majority
res <- lapply(AXES, function(ax) {
  mat <- sapply(ann, function(a) a[[ax]]); mat[mat == ""] <- NA
  k <- fleiss_kappa(mat)
  out <- data.frame(axis = ax, level = "raw", kappa = round(k, 3),
                    n_subjects = sum(apply(mat, 1, function(r) sum(!is.na(r)) >= 2)))
  if (ax == "ax4_register") {
    k3 <- fleiss_kappa(apply(mat, 2, collapse3))
    out <- rbind(out, data.frame(axis = ax, level = "3way(justice/charity/object)", kappa = round(k3, 3),
                                 n_subjects = out$n_subjects))
  }
  out
})
kappa_tab <- bind_rows(res)
write.csv(kappa_tab, file.path(out_dir, "gate2_iaa.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# majority-adjudicated core
core <- data.frame(rid = ids, domain = ann[[1]]$domain, n_ann = length(ann), stringsAsFactors = FALSE)
for (ax in AXES) core[[ax]] <- apply(sapply(ann, function(a) a[[ax]]), 1, majority)
core$ax4_register_3way <- collapse3(core$ax4_register)
write.csv(core, file.path(out_dir, "coded_core.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\n== GATE 2: inter-annotator agreement (Fleiss kappa) ==\n")
print(kappa_tab, row.names = FALSE)
reg5 <- kappa_tab$kappa[kappa_tab$axis=="ax4_register" & kappa_tab$level=="raw"]
reg3 <- kappa_tab$kappa[kappa_tab$level=="3way(justice/charity/object)"]
cat(sprintf("\nRegister reliability: 5-way kappa = %.3f | 3-way kappa = %.3f  (sister benchmark 0.46)\n", reg5, reg3))
cat("Pre-declared confirmatory level (PLAN §3, fallback order 5-way -> 3-way -> binary):\n")
cat("  -> run H1/H4 at the FIRST level clearing the prereg floor;",
    if (!is.na(reg5) && reg5 >= 0.6) "5-way clears 0.6." else
    if (!is.na(reg3) && reg3 >= 0.6) "5-way < 0.6, use 3-way." else "both < 0.6 -> H1/H4 exploratory; lean on the map.", "\n")
cat("Incidental rate (ax1):",
    round(mean(core$ax1_link_genuine == "incidental", na.rm = TRUE), 3), "\n")
cat("Files: gate2_iaa.csv | coded_core.csv ->", out_dir, "\n")
