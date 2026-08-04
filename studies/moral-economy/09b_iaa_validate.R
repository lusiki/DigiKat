#!/usr/bin/env Rscript
# moral-economy STAGE V (part 2b) — assemble the three blind codings, measure reliability, and put
# the meaning lens on trial against human judgment.
#
# This is the study's honesty spine. Nothing the meaning lens claims is publishable until it clears
# the pre-declared floors below; where it fails, the failure is reported and the keyword lens (or the
# hand-coded cell) stands alone.
#
# FIT / VALIDATE discipline: the gold sample was split 50/50 before any coding. FIT rebuilds the
# register anchors (v1) and fits the poverty margin; every reported agreement comes from VALIDATE.
# Fitting and validating on disjoint posts removes the circularity by construction.
#
#   Rscript studies/moral-economy/09b_iaa_validate.R
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb) })
source(here::here("studies/moral-economy/sem_lib.R"))

cat("=== STAGE V — reliability + semantic-vs-human validation ===\n")
anch <- readRDS(file.path(ME_SEM, "anchors.rds"))
S    <- readRDS(file.path(ME_SEM, "scores_full.rds"))
key  <- read.csv(file.path(ME_PRIVATE, "gold_key.csv"), fileEncoding = "UTF-8", stringsAsFactors = FALSE)
rid_order <- as.integer(readLines(file.path(ME_PRIVATE, "gold_rid_order.txt")))

# ------------------------------------------------------------------------------------------------
# 1. ASSEMBLE — three annotators, aligned by rid.
# ------------------------------------------------------------------------------------------------
read_ann <- function(k) {
  d <- file.path(ME_PRIVATE, sprintf("ann%d", k))
  fs <- sort(list.files(d, pattern = "^batch_\\d+\\.tsv$", full.names = TRUE))
  if (!length(fs)) stop("No coding files for annotator ", k, call. = FALSE)
  x <- do.call(rbind, lapply(fs, function(f)
    read.delim(f, fileEncoding = "UTF-8", stringsAsFactors = FALSE, colClasses = "character",
               quote = "", na.strings = character(0))))
  x$rid <- as.integer(x$rid)
  digikat_require_columns(x, c("rid", ME_AXES), sprintf("annotator %d", k))
  x[match(rid_order, x$rid), c("rid", ME_AXES)]
}
ANN <- lapply(1:3, read_ann)
for (k in 1:3) {
  if (!identical(ANN[[k]]$rid, rid_order)) stop("Annotator ", k, " is not aligned to the sheet.", call. = FALSE)
  cat(sprintf("annotator %d: %d rows\n", k, nrow(ANN[[k]])))
}

# vocabulary validation — an out-of-vocabulary code becomes NA and is COUNTED, never coerced
VOCAB <- list(
  ax1_link_genuine = c("genuine","incidental"),
  ax2_geography = c("domestic","foreign","mixed"),
  ax3_actor_commentator = c("actor","commentator","both"),
  ax4_register = ME_REGISTERS,
  ax5_poverty_split = c(ME_PSPLIT, "NA"))
n_invalid <- 0L
for (k in 1:3) for (a in names(VOCAB)) {
  bad <- !(ANN[[k]][[a]] %in% VOCAB[[a]])
  n_invalid <- n_invalid + sum(bad)
  ANN[[k]][[a]][bad] <- NA_character_
}
cat(sprintf("out-of-vocabulary codes set to NA: %d of %d\n", n_invalid, 3 * nrow(ANN[[1]]) * length(VOCAB)))

mat_of <- function(a) sapply(ANN, function(x) x[[a]])
maj_of <- function(a) apply(mat_of(a), 1, majority)

H <- data.frame(rid = rid_order, stringsAsFactors = FALSE)
for (a in ME_AXES) H[[a]] <- maj_of(a)
H$ax4_3way <- collapse3(H$ax4_register)
H$n_agree_ax1 <- apply(mat_of("ax1_link_genuine"), 1, function(r) max(table(r[!is.na(r)])))
H <- merge(H, key[, c("rid","domain","stratum","split","sem_register","z_econ_minus_doct","label","stream")],
           by = "rid", all.x = TRUE)

# The machine labels in the key came from the v0 (probe-centroid) anchors. Once 07 has been re-run
# with --anchors=v1, prefer those: v1 is what the paper would actually publish, so v1 is what has to
# survive validation. Both are reported — an instrument whose answer depends on its anchor version
# is a finding, not a detail.
ML_VERSION <- "v0"
v1f <- file.path(ME_SEM, "candidate_registers_v1.rds")
if (file.exists(v1f)) {
  r1 <- readRDS(v1f)
  H$sem_register_v0 <- H$sem_register
  H$sem_register_v1 <- r1$register[match(H$rid, r1$rid)]
  H$sem_register <- H$sem_register_v1
  ML_VERSION <- "v1"
  agree_v0v1 <- mean(H$sem_register_v0 == H$sem_register_v1, na.rm = TRUE)
  cat(sprintf("\nmachine labels: using v1 (v0 also retained; v0-vs-v1 agreement on the gold sample = %.1f%%)\n",
              100 * agree_v0v1))
} else {
  cat("\nmachine labels: v0 only (run 07 --anchors=v1 then re-run this script to validate v1)\n")
}

# ------------------------------------------------------------------------------------------------
# 2. RELIABILITY (Fleiss' kappa).
#    ax4/ax5 are ALSO reported on the genuine-link subset: an `incidental` post has no register, so
#    coders default it to `other`, which makes the full-sample register kappa partly an artifact of
#    ax1 agreement rather than a measure of register agreement. CODEBOOK.md specifies the subset.
# ------------------------------------------------------------------------------------------------
cat("\n-- inter-annotator agreement (Fleiss' kappa, 3 coders) --\n")
gen <- which(H$ax1_link_genuine == "genuine")
iaa <- do.call(rbind, lapply(ME_AXES, function(a) {
  m <- mat_of(a)
  data.frame(axis = a, level = "raw (all 555)", kappa = round(fleiss_kappa(m), 3),
             n_subjects = sum(apply(m, 1, function(r) sum(!is.na(r)) >= 2)), stringsAsFactors = FALSE)
}))
extra <- rbind(
  data.frame(axis = "ax4_register", level = "raw, genuine-link subset",
             kappa = round(fleiss_kappa(mat_of("ax4_register")[gen, , drop = FALSE]), 3),
             n_subjects = length(gen), stringsAsFactors = FALSE),
  data.frame(axis = "ax4_register", level = "3way (justice/charity/object), genuine subset",
             kappa = round(fleiss_kappa(apply(mat_of("ax4_register")[gen, , drop = FALSE], 2, collapse3)), 3),
             n_subjects = length(gen), stringsAsFactors = FALSE),
  data.frame(axis = "ax4_register", level = "binary (justice vs rest), genuine subset",
             kappa = round(fleiss_kappa(ifelse(mat_of("ax4_register")[gen, , drop = FALSE] == "justice",
                                               "justice", "rest")), 3),
             n_subjects = length(gen), stringsAsFactors = FALSE),
  data.frame(axis = "ax5_poverty_split", level = "3way, poverty domain only",
             kappa = round(fleiss_kappa(mat_of("ax5_poverty_split")[H$domain == "poverty_social", , drop = FALSE]), 3),
             n_subjects = sum(H$domain == "poverty_social"), stringsAsFactors = FALSE))
iaa <- rbind(iaa, extra)
print(iaa, row.names = FALSE)

# same-model baseline honesty: three passes from one model family is NOT three independent coders
cat("\n  NB three passes by one model are not three independent annotators — this kappa is\n")
cat("     inter-PASS reliability and overstates what independent human coders would achieve.\n")

k_of <- function(ax, lv) iaa$kappa[iaa$axis == ax & iaa$level == lv][1]

# ------------------------------------------------------------------------------------------------
# 3. WHAT THE HUMANS FOUND — the incidental rate, which corrects every keyword denominator.
# ------------------------------------------------------------------------------------------------
cat("\n-- genuine-link rate by stratum (majority of 3) --\n")
gr <- do.call(rbind, lapply(sort(unique(H$stratum)), function(st) {
  i <- H$stratum == st; k <- sum(H$ax1_link_genuine[i] == "genuine", na.rm = TRUE); n <- sum(i)
  ci <- wilson(k, n)
  data.frame(stratum = st, n = n, genuine = k, rate = round(k / n, 3),
             lo = round(ci[1], 3), hi = round(ci[2], 3), stringsAsFactors = FALSE)
}))
print(gr, row.names = FALSE)

cat("\n-- per-domain retrieval precision (domain_core stratum: the posts the lens is most sure of) --\n")
dp <- do.call(rbind, lapply(sort(unique(H$domain[H$stratum == "domain_core"])), function(d) {
  i <- H$stratum == "domain_core" & H$domain == d
  k <- sum(H$ax1_link_genuine[i] == "genuine", na.rm = TRUE); n <- sum(i); ci <- wilson(k, n)
  data.frame(domain = d, n = n, precision = round(k / n, 3),
             lo = round(ci[1], 3), hi = round(ci[2], 3),
             gate_GV4 = (k / n) >= 0.70, stringsAsFactors = FALSE)
}))
print(dp, row.names = FALSE)

# ------------------------------------------------------------------------------------------------
# 4. FIT HALF -> v1 REGISTER ANCHORS (seeds curated by actual coding, not by eyeballing retrieval).
# ------------------------------------------------------------------------------------------------
cat("\n-- rebuilding register anchors from the coded FIT half --\n")
con <- sem_con(); on.exit(sem_disconnect(con), add = TRUE)
fitset <- H[H$split == "fit" & H$ax1_link_genuine == "genuine" & !is.na(H$ax4_register), ]
cat(sprintf("  FIT posts with a genuine link and a register: %d\n", nrow(fitset)))
print(table(fitset$ax4_register))

A1 <- anch$A_cen; built <- character(0)
if (nrow(fitset) >= 20) {
  P_fit <- sem_fetch_embeddings(con, fitset$rid)
  for (r in ME_REGISTERS) {
    ids <- as.character(fitset$rid[fitset$ax4_register == r])
    ids <- intersect(ids, rownames(P_fit))
    if (length(ids) >= 8) {
      A1[r, ] <- sem_unit(colMeans(P_fit[ids, , drop = FALSE]) - anch$mu)
      built <- c(built, r)
    }
  }
}
# the poverty-split anchors get the same treatment: FIT posts the coders judged economic vs doctrinal
povfit <- H[H$split == "fit" & H$domain == "poverty_social" & H$ax5_poverty_split %in% c("economic_poverty","doctrinal_poverty"), ]
if (nrow(povfit) >= 16) {
  P_pf <- sem_fetch_embeddings(con, povfit$rid)
  for (p in c("economic_poverty","doctrinal_poverty")) {
    ids <- intersect(as.character(povfit$rid[povfit$ax5_poverty_split == p]), rownames(P_pf))
    if (length(ids) >= 8) {
      A1[p, ] <- sem_unit(colMeans(P_pf[ids, , drop = FALSE]) - anch$mu)
      built <- c(built, p)
    }
  }
}
cat(sprintf("  v1 anchors rebuilt for: %s\n", if (length(built)) paste(built, collapse = ", ") else "(none — too few coded seeds)"))
cat(sprintf("  registers left at v0 (probe centroids): %s\n",
            paste(setdiff(ME_REGISTERS, built), collapse = ", ")))

# The key's z_econ_minus_doct was computed with the v0 poverty anchors. If v1 poverty anchors were
# just rebuilt from coded FIT posts, the poverty gate must be tested against THOSE — otherwise the
# gate reports on an instrument the paper would not use.
if (all(c("economic_poverty", "doctrinal_poverty") %in% built)) {
  cat("  rescoring the poverty split with the v1 (coded) poverty anchors\n")
  A1p <- A1[c("economic_poverty", "doctrinal_poverty"), , drop = FALSE]
  pv_all <- dbGetQuery(con, sem_score_sql(A1p, anch$mu, extra_cols = "chunk_id"))
  med_e <- median(pv_all$s_economic_poverty);  mad_e <- max(mad(pv_all$s_economic_poverty), 1e-6)
  med_d <- median(pv_all$s_doctrinal_poverty); mad_d <- max(mad(pv_all$s_doctrinal_poverty), 1e-6)
  o <- match(H$rid, pv_all$chunk_id)
  H$z_econ_minus_doct_v0 <- H$z_econ_minus_doct
  H$z_econ_minus_doct <- round((pv_all$s_economic_poverty[o] - med_e) / mad_e -
                               (pv_all$s_doctrinal_poverty[o] - med_d) / mad_d, 3)
}

# ------------------------------------------------------------------------------------------------
# 5. SEMANTIC vs HUMAN on VALIDATE — the numbers that decide publication.
# ------------------------------------------------------------------------------------------------
cat("\n-- semantic classifier vs human majority (VALIDATE half, genuine links only) --\n")
val <- H[H$split == "validate" & H$ax1_link_genuine == "genuine" &
         !is.na(H$ax4_register) & !is.na(H$sem_register) & H$sem_register != "ambiguous", ]
cat(sprintf("  comparable rows: %d\n", nrow(val)))
k_reg <- cohen_kappa(val$sem_register, val$ax4_register)
k_reg3 <- cohen_kappa(collapse3(val$sem_register), collapse3(val$ax4_register))
cat(sprintf("  Cohen kappa, register 5-way: %s | 3-way: %s\n",
            ifelse(is.na(k_reg), "NA", sprintf("%+.3f", k_reg)),
            ifelse(is.na(k_reg3), "NA", sprintf("%+.3f", k_reg3))))
if (nrow(val) >= 10) {
  cat("\n  confusion (rows = machine, cols = human):\n")
  print(table(machine = val$sem_register, human = val$ax4_register))
}

# per-domain register agreement (G-V5)
reg_by_dom <- do.call(rbind, lapply(sort(unique(val$domain)), function(d) {
  i <- val$domain == d
  data.frame(domain = d, n = sum(i),
             kappa = round(cohen_kappa(val$sem_register[i], val$ax4_register[i]), 3),
             agree = round(mean(val$sem_register[i] == val$ax4_register[i]), 3),
             stringsAsFactors = FALSE)
}))
print(reg_by_dom, row.names = FALSE)

# share containment (G-V6): is the machine's register share inside the human bootstrap CI?
set.seed(ME_SEED)
hshare <- prop.table(table(factor(val$ax4_register, levels = ME_REGISTERS)))
mshare <- prop.table(table(factor(val$sem_register, levels = ME_REGISTERS)))
bs <- replicate(2000, prop.table(table(factor(sample(val$ax4_register, replace = TRUE),
                                              levels = ME_REGISTERS))))
cont <- data.frame(register = ME_REGISTERS,
                   human = round(as.numeric(hshare), 3),
                   human_lo = round(apply(bs, 1, quantile, .025), 3),
                   human_hi = round(apply(bs, 1, quantile, .975), 3),
                   machine = round(as.numeric(mshare), 3), stringsAsFactors = FALSE)
cont$contained <- cont$machine >= cont$human_lo & cont$machine <= cont$human_hi
cat("\n-- register share containment --\n"); print(cont, row.names = FALSE)

# poverty split: fit delta_p on FIT, report on VALIDATE (G-V7)
cat("\n-- poverty split: machine vs human --\n")
povH <- H[H$domain == "poverty_social" & H$ax5_poverty_split %in% ME_PSPLIT, ]
fit_p <- povH[povH$split == "fit", ]; val_p <- povH[povH$split == "validate", ]
band <- function(dz, dp) ifelse(dz >= dp, "economic_poverty", ifelse(dz <= -dp, "doctrinal_poverty", "mixed"))
grid_dp <- seq(0, 3, by = 0.05)
bal_acc <- sapply(grid_dp, function(dp) {
  pr <- band(fit_p$z_econ_minus_doct, dp)
  mean(sapply(ME_PSPLIT, function(l) { i <- fit_p$ax5_poverty_split == l
    if (!sum(i)) NA_real_ else mean(pr[i] == l) }), na.rm = TRUE)
})
DP <- if (all(is.na(bal_acc))) 0.5 else grid_dp[which.max(bal_acc)]
cat(sprintf("  delta_p fitted on FIT (n=%d): %.2f (balanced accuracy %.3f)\n",
            nrow(fit_p), DP, max(bal_acc, na.rm = TRUE)))
pv <- data.frame(
  side = ME_PSPLIT,
  human = round(as.numeric(prop.table(table(factor(val_p$ax5_poverty_split, levels = ME_PSPLIT)))), 3),
  machine = round(as.numeric(prop.table(table(factor(band(val_p$z_econ_minus_doct, DP), levels = ME_PSPLIT)))), 3),
  stringsAsFactors = FALSE)
pv$diff_pp <- round(100 * (pv$machine - pv$human), 1)
cat(sprintf("  VALIDATE n = %d\n", nrow(val_p))); print(pv, row.names = FALSE)
max_dev <- max(abs(pv$diff_pp), na.rm = TRUE)

# gap strata: what makes S2's 19.7% cross-lens agreement interpretable (G-V8)
cat("\n-- gap strata: are the disputed posts genuine? --\n")
gapp <- do.call(rbind, lapply(c("recall_gap","precision_gap"), function(st) {
  i <- H$stratum == st; k <- sum(H$ax1_link_genuine[i] == "genuine", na.rm = TRUE); n <- sum(i)
  ci <- wilson(k, n)
  data.frame(stratum = st, n = n, genuine_rate = round(k / n, 3),
             lo = round(ci[1], 3), hi = round(ci[2], 3), stringsAsFactors = FALSE)
}))
print(gapp, row.names = FALSE)

# ------------------------------------------------------------------------------------------------
# 6. THE PRE-DECLARED GATES — fail-closed. 10 refuses to plot anything whose gate failed.
# ------------------------------------------------------------------------------------------------
cat("\n-- pre-declared gates --\n")
reg5 <- k_of("ax4_register", "raw, genuine-link subset")
reg3 <- k_of("ax4_register", "3way (justice/charity/object), genuine subset")
regb <- k_of("ax4_register", "binary (justice vs rest), genuine subset")
gates <- list(
  `G-V1_iaa_register_5way`  = list(value = reg5, floor = 0.60, pass = isTRUE(reg5 >= 0.60)),
  `G-V1b_iaa_register_3way` = list(value = reg3, floor = 0.60, pass = isTRUE(reg3 >= 0.60)),
  `G-V1c_iaa_register_binary` = list(value = regb, floor = 0.60, pass = isTRUE(regb >= 0.60)),
  `G-V2_iaa_ax1_genuine`    = list(value = k_of("ax1_link_genuine", "raw (all 555)"), floor = 0.55,
                                   pass = isTRUE(k_of("ax1_link_genuine", "raw (all 555)") >= 0.55)),
  `G-V3_iaa_ax5_3way`       = list(value = k_of("ax5_poverty_split", "3way, poverty domain only"),
                                   floor = 0.60,
                                   pass = isTRUE(k_of("ax5_poverty_split", "3way, poverty domain only") >= 0.60)),
  `G-V4_retrieval_precision`= list(value = round(mean(dp$precision), 3), floor = 0.70,
                                   pass = all(dp$gate_GV4), detail = paste(dp$domain[!dp$gate_GV4], collapse = ",")),
  `G-V5_semantic_vs_human_register` = list(value = round(k_reg, 3), floor = 0.40, pass = isTRUE(k_reg >= 0.40)),
  `G-V6_share_containment`  = list(value = sum(cont$contained), floor = 4, pass = sum(cont$contained) >= 4),
  `G-V7_poverty_split_dev_pp` = list(value = max_dev, floor = 10, pass = isTRUE(max_dev <= 10)))
for (g in names(gates)) {
  v <- gates[[g]]$value
  cat(sprintf("  [%s] %-34s value = %s (floor %s)\n", if (isTRUE(gates[[g]]$pass)) "PASS" else "FAIL",
              g, ifelse(is.na(v), "NA", format(round(v, 3))), format(gates[[g]]$floor)))
}
# the pre-declared register fallback ladder: 5-way -> 3-way -> binary -> exploratory
reg_level <- if (isTRUE(reg5 >= 0.60)) "5way" else if (isTRUE(reg3 >= 0.60)) "3way" else
             if (isTRUE(regb >= 0.60)) "binary" else "exploratory"
cat(sprintf("\n  register analysis runs at: %s\n", reg_level))

# ------------------------------------------------------------------------------------------------
# 7. WRITE
# ------------------------------------------------------------------------------------------------
sem_write_shareable(iaa, file.path(ME_OUT, "gate2_iaa.csv"))
sem_write_shareable(gr, file.path(ME_SEM, "genuine_rate_by_stratum.csv"))
sem_write_shareable(dp, file.path(ME_SEM, "retrieval_precision_by_domain.csv"))
sem_write_shareable(reg_by_dom, file.path(ME_SEM, "semantic_vs_human_register.csv"))
sem_write_shareable(cont, file.path(ME_SEM, "register_share_containment.csv"))
sem_write_shareable(pv, file.path(ME_SEM, "poverty_split_validation.csv"))
sem_write_shareable(gapp, file.path(ME_SEM, "gap_strata_precision.csv"))
sem_write_private(H, file.path(ME_PRIVATE, "gold_core.csv"))

anch1 <- anch; anch1$A_cen <- A1; anch1$version <- "v1"
anch1$v1_registers_rebuilt <- built; anch1$delta_p <- DP
digikat_atomic_replace_file(digikat_stage_rds(anch1, file.path(ME_SEM, "anchors_v1.rds")),
                            file.path(ME_SEM, "anchors_v1.rds"))

digikat_write_json_atomic(list(
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/09b_iaa_validate.R",
  n_coded = nrow(H), n_annotators = 3L, n_invalid_codes = n_invalid,
  annotator_provenance = "three blind passes by one LLM family (Claude), differing framing emphasis; NOT independent human coders; no human double-code was performed (PI decision 2026-08-04)",
  external_data_exception = "555 blind post excerpts (no URL/outlet/date) were sent to an external model for coding, an explicit exception to R/semantic/README.md's local-only rule, authorised by the PI on 2026-08-04",
  register_level = reg_level, delta_p_fitted = DP,
  v1_registers_rebuilt = as.list(built),
  gates = gates), file.path(ME_SEM, "gates.json"))

cat("\n== Stage V complete ==\n")
cat("  reliability -> output/gate2_iaa.csv (tracked)\n")
cat("  validation  -> output/semantic/semantic_vs_human_register.csv etc. (tracked)\n")
cat("  gates       -> output/semantic/gates.json (10_stage_c reads this and fails closed)\n")
cat("  coded core  -> output/private/gold_core.csv (RESTRICTED)\n")
