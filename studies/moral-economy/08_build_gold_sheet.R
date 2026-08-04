#!/usr/bin/env Rscript
# moral-economy STAGE V (part 1) — build the BLIND gold sheet.
#
# 560 posts, stratified so that every claim the meaning lens makes has a hand-checked counterpart:
#   domain_core    220  11 x 20 top-scoring linked candidates -> per-domain retrieval precision
#   register_cell  120  5 registers x 2 focus domains x 12    -> semantic-vs-human register agreement
#   poverty_split   60  spread across the economic<->doctrinal margin, incl. the ambiguous band
#   recall_gap      88  11 x 8 semantic-picked / keyword-missed -> makes S2's 80% divergence readable
#   precision_gap   44  11 x 4 keyword-linked / semantic-missed -> the other side of the same audit
#   random_linked   28  an unstratified anchor so the sheet is not all extremes
#
# Two firewalls:
#   * S1 seed rids are EXCLUDED — an anchor must never be validated on the posts that built it.
#   * The sheet is split 50/50 into FIT and VALIDATE (recorded in the KEY, invisible to the coder).
#     FIT rebuilds the register anchors and fits the margins; every published agreement number comes
#     from VALIDATE. Fitting and validating on disjoint posts removes the circularity by construction.
#
# The sheet carries NO outlet, date, URL, stratum or machine label — a coder who can see the outlet
# codes the outlet, not the text, and a coder who can see the machine's guess agrees with it.
#
#   Rscript studies/moral-economy/08_build_gold_sheet.R [--n=560]
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb) })
source(here::here("studies/moral-economy/sem_lib.R"))

args <- commandArgs(trailingOnly = TRUE)
TEXT_CHARS <- 800L

cat("=== STAGE V — building the blind gold sheet ===\n")
anch <- readRDS(file.path(ME_SEM, "anchors.rds"))
S    <- readRDS(file.path(ME_SEM, "scores_full.rds"))
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
gapi <- readRDS(file.path(ME_SEM, "gap_ids.rds"))
regs <- readRDS(file.path(ME_SEM, "candidate_registers_v0.rds"))
dom  <- anch$domains
seed_rids <- anch$seed_rids
cat(sprintf("excluding %s S1 seed rids (circularity firewall)\n", digikat_format_integer(length(seed_rids))))

set.seed(ME_SEED)
sc <- function(d) S[[paste0("s_", d)]]
pick <- function(ids, k) { ids <- setdiff(unique(ids), seed_rids); if (length(ids) <= k) ids else sample(ids, k) }
rows <- list()

# --- domain_core: the posts the meaning lens is MOST sure about, per domain -----------------------
for (d in dom) {
  linked <- unique(cand$rid[cand$domain == d])
  o <- linked[order(sc(d)[match(linked, S$chunk_id)], decreasing = TRUE)]
  rows[[length(rows) + 1]] <- data.frame(rid = pick(head(o, 200), 20), domain = d,
                                         stratum = "domain_core", stringsAsFactors = FALSE)
}
# --- register_cell: where the grid claims its sharpest contrast ------------------------------------
for (d in c("poverty_social", "wages_income")) {
  for (r in anch$registers) {
    ids <- regs$rid[regs$domain == d & regs$register == r]
    rows[[length(rows) + 1]] <- data.frame(rid = pick(ids, 12), domain = d,
                                           stratum = "register_cell", stringsAsFactors = FALSE)
  }
}
# --- poverty_split: spread ACROSS the margin, not just the extremes -------------------------------
z_ec <- (S$s_economic_poverty - anch$bg_med["economic_poverty"]) / anch$bg_mad["economic_poverty"]
z_dc <- (S$s_doctrinal_poverty - anch$bg_med["doctrinal_poverty"]) / anch$bg_mad["doctrinal_poverty"]
pov  <- unique(cand$rid[cand$domain == "poverty_social"])
dz   <- (z_ec - z_dc)[match(pov, S$chunk_id)]
bands <- cut(dz, breaks = quantile(dz, seq(0, 1, length.out = 6), na.rm = TRUE),
             include.lowest = TRUE, labels = FALSE)
for (b in 1:5) rows[[length(rows) + 1]] <- data.frame(rid = pick(pov[which(bands == b)], 12),
                                                      domain = "poverty_social",
                                                      stratum = "poverty_split", stringsAsFactors = FALSE)
# --- the two gap strata: what makes S2's cross-lens divergence interpretable -----------------------
for (d in dom) {
  rows[[length(rows) + 1]] <- data.frame(rid = pick(gapi[[d]]$sem_only, 8), domain = d,
                                         stratum = "recall_gap", stringsAsFactors = FALSE)
  rows[[length(rows) + 1]] <- data.frame(rid = pick(gapi[[d]]$kw_only, 4), domain = d,
                                         stratum = "precision_gap", stringsAsFactors = FALSE)
}
# --- random anchor ---------------------------------------------------------------------------------
rows[[length(rows) + 1]] <- data.frame(rid = pick(cand$rid, 28), domain = NA_character_,
                                       stratum = "random_linked", stringsAsFactors = FALSE)

sheet <- do.call(rbind, rows)
sheet <- sheet[!duplicated(sheet$rid), ]           # a post is coded once, in its first-drawn context
# a random_linked row needs a domain for the ax5 gate; take its first Stage-A domain
fill <- is.na(sheet$domain)
sheet$domain[fill] <- cand$domain[match(sheet$rid[fill], cand$rid)]
cat("\nstratum allocation:\n"); print(table(sheet$stratum))
cat(sprintf("total: %d posts\n", nrow(sheet)))

# --- text: the +-220-char Stage-A window (where it exists) + an 800-char excerpt from the store ----
# The window alone is what 03_build_coding_sheet.R showed the coder; the sister study's register
# kappa of 0.46 is partly a too-short-window artifact, so the coder also gets real context here.
con <- sem_con(); on.exit(sem_disconnect(con), add = TRUE)
txt <- dbGetQuery(con, sprintf(
  "SELECT chunk_id AS rid, substr(text, 1, %d) AS text_800 FROM chunks WHERE chunk_id IN (%s)",
  TEXT_CHARS, paste(sheet$rid, collapse = ",")))
sheet <- merge(sheet, txt, by = "rid", all.x = TRUE)
w <- cand[!duplicated(paste(cand$rid, cand$domain)), c("rid", "domain", "window")]
sheet <- merge(sheet, w, by = c("rid", "domain"), all.x = TRUE)
sheet$window[is.na(sheet$window)] <- "(nije iz ključne riječi — vidi tekst)"
if (any(is.na(sheet$text_800))) stop("Some sheet rows have no text in the store.", call. = FALSE)

# --- FIT / VALIDATE split (recorded in the KEY only) -----------------------------------------------
sheet$split <- "validate"
for (st in unique(sheet$stratum)) {
  i <- which(sheet$stratum == st)
  sheet$split[sample(i, floor(length(i) / 2))] <- "fit"
}
cat("\nfit/validate split:\n"); print(table(sheet$stratum, sheet$split))

# --- BLIND coder sheet ------------------------------------------------------------------------------
set.seed(ME_SEED + 1L)
sheet <- sheet[sample(nrow(sheet)), ]        # shuffle so stratum structure is invisible
blind <- data.frame(rid = sheet$rid, domain = sheet$domain, window = sheet$window,
                    text_800 = sheet$text_800, stringsAsFactors = FALSE)
for (a in ME_AXES) blind[[a]] <- ""
forbidden <- c("stratum", "split", "label", "FROM", "URL", "DATE", "stream", "register", "score")
if (any(forbidden %in% names(blind))) stop("Blind sheet leaks a withheld field.", call. = FALSE)
sem_write_private(blind, file.path(ME_PRIVATE, "gold_sheet.csv"))

# --- KEY (withheld until after coding) ---------------------------------------------------------------
meta <- cand[match(sheet$rid, cand$rid), c("DATE","year","FROM","SOURCE_TYPE","stream","label")]
key <- cbind(sheet[, c("rid","domain","stratum","split")], meta,
             sem_register = regs$register[match(sheet$rid, regs$rid)],
             z_econ_minus_doct = round((z_ec - z_dc)[match(sheet$rid, S$chunk_id)], 3))
key$sem_domain_score <- NA_real_          # preallocate: assigning inside the loop would size the
for (d in unique(sheet$domain)) {         # column to the first domain's row count
  i <- which(key$domain == d)
  key$sem_domain_score[i] <- round(sc(d)[match(key$rid[i], S$chunk_id)], 4)
}
sem_write_private(key, file.path(ME_PRIVATE, "gold_key.csv"))

alloc <- as.data.frame(table(sheet$stratum, sheet$domain, sheet$split))
names(alloc) <- c("stratum", "domain", "split", "n")
alloc <- alloc[alloc$n > 0, ]
sem_write_shareable(alloc, file.path(ME_OUT, "gold_allocation.csv"))

digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/08_build_gold_sheet.R",
  inputs = list(anchors = "output/semantic/anchors.rds", scores = "output/semantic/scores_full.rds"),
  outputs = list(sheet = "output/private/gold_sheet.csv (RESTRICTED)",
                 key = "output/private/gold_key.csv (RESTRICTED)"),
  extra = list(n_posts = nrow(sheet), text_chars = TEXT_CHARS,
               strata = as.list(table(sheet$stratum)),
               n_fit = sum(sheet$split == "fit"), n_validate = sum(sheet$split == "validate"),
               seed_rids_excluded = length(seed_rids),
               blindness = "sheet carries rid, domain, window, text only — no outlet, date, URL, stratum, or machine label")
), file.path(ME_SEM, "gold_sheet_manifest.json"))

cat("\n== gold sheet built ==\n")
cat(sprintf("  %d posts -> output/private/gold_sheet.csv (RESTRICTED, blind)\n", nrow(sheet)))
cat("  key      -> output/private/gold_key.csv (RESTRICTED, withheld from coders)\n")
cat("Next: 09 — three blind annotator passes, then IAA + semantic-vs-human validation.\n")
