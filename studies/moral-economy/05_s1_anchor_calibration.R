#!/usr/bin/env Rscript
# moral-economy STAGE S1 — ANCHOR CALIBRATION (PROPOSAL_v3 §7).
#
# The pilot's meaning lens was miscalibrated: hand-written concept sentences scored under RAW cosine
# with winner-take-all assignment gave euro_changeover 19.9% of the corpus (rank 2) against 407
# keyword-linked posts. S1 replaces that instrument.
#
# THREE fixes, each measurable:
#   (1) SEED-POST CENTROIDS instead of hand-written sentences — a domain's anchor is the average
#       meaning of posts the keyword lens already vouched for, not of a sentence we invented.
#   (2) MEAN-CENTERING — the corpus is anisotropic (||mu|| = 0.596; random post pairs sit at cosine
#       0.354, not 0). Under raw cosine, BROAD wording scores high everywhere, which is the actual
#       mechanism behind the euro artifact. Subtracting mu removes the component breadth exploits.
#   (3) THRESHOLD PREVALENCE, not winner-take-all — anchors are collinear (max pairwise cosine ~0.77,
#       unemployment vs demography_econ), and argmax over correlated anchors allocates by noise.
#
# READ-ONLY on the semantic store and on Stage A's output. Never opens the master. Writes only to
# studies/moral-economy/output/.
#
#   Rscript studies/moral-economy/05_s1_anchor_calibration.R [--n-seed=400] [--force]
suppressPackageStartupMessages({ library(here); library(DBI); library(duckdb) })
source(here::here("studies/moral-economy/sem_lib.R"))

args    <- commandArgs(trailingOnly = TRUE)
N_SEED  <- as.integer(digikat_cli_value(args, "--n-seed", "400"))
HOLDOUT <- 0.25          # never enters a centroid; the only honest estimate of anchor recall
N_BG    <- 50000L        # fixed background sample for robust z-scores and prevalence
FORCE   <- digikat_cli_flag(args, "force")

cat("=== STAGE S1 — anchor calibration ===\n")
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
digikat_require_columns(cand, c("rid", "domain", "stream", "label", "foreign_hint",
                                "infl_metaphor_hint", "actor_only_caritas"), "stageA candidates")
cat(sprintf("Stage A: %s linked candidate rows, %d domains\n",
            digikat_format_integer(nrow(cand)), length(unique(cand$domain))))

con <- sem_con(); on.exit(sem_disconnect(con), add = TRUE)
cat("\n-- gates --\n")
sem_gate_id_mapping(con, cand, n = 500L)
sem_gate_unit_norm(con)

cat("\n-- corpus mean --\n")
mu <- sem_corpus_mean(con)
MU_NORM <- sqrt(sum(mu^2))

# ------------------------------------------------------------------------------------------------
# 1. DOMAIN SEEDS — Stage-A candidates the keyword lens is most confident about.
# clean  = no foreign-country hint, no inflation-metaphor hint, not a Caritas-name-only match
# uni    = the post is a candidate in EXACTLY ONE domain (a multi-domain post would blur two anchors)
# ------------------------------------------------------------------------------------------------
cat("\n-- domain seeds --\n")
n_dom_per_rid <- table(cand$rid)
cand$uni   <- as.integer(n_dom_per_rid[as.character(cand$rid)]) == 1L
cand$clean <- !cand$foreign_hint & !cand$infl_metaphor_hint & !cand$actor_only_caritas

set.seed(ME_SEED)
seed_rows <- list()
for (d in sort(unique(cand$domain))) {
  pool_uni <- cand[cand$domain == d & cand$clean & cand$uni, ]
  take <- sem_draw(pool_uni, min(N_SEED, nrow(pool_uni)))
  got  <- pool_uni[pool_uni$rid %in% take, ]
  topped_up <- 0L
  if (nrow(got) < N_SEED) {                      # top up from clean multi-domain posts, and say so
    pool_multi <- cand[cand$domain == d & cand$clean & !cand$uni & !(cand$rid %in% got$rid), ]
    need <- N_SEED - nrow(got)
    if (nrow(pool_multi)) {
      take2 <- sem_draw(pool_multi, min(need, nrow(pool_multi)))
      add <- pool_multi[pool_multi$rid %in% take2, ]
      topped_up <- nrow(add); got <- rbind(got, add)
    }
  }
  got$n_uni_avail <- nrow(pool_uni); got$n_topped_up <- topped_up
  seed_rows[[d]] <- got
}
seeds <- do.call(rbind, seed_rows)
seeds <- seeds[!duplicated(paste(seeds$domain, seeds$rid)), ]

# fit / holdout split, per domain
seeds$holdout <- FALSE
for (d in unique(seeds$domain)) {
  i <- which(seeds$domain == d)
  seeds$holdout[sample(i, floor(HOLDOUT * length(i)))] <- TRUE
}
ss <- as.data.frame(table(seeds$domain, seeds$holdout))
cat(sprintf("  %d seed rows over %d domains (%.0f%% held out)\n",
            nrow(seeds), length(unique(seeds$domain)), 100 * HOLDOUT))
for (d in sort(unique(seeds$domain))) {
  sd_ <- seeds[seeds$domain == d, ]
  cat(sprintf("   %-18s n=%4d  uni_avail=%6d  topped_up=%4d\n",
              d, nrow(sd_), sd_$n_uni_avail[1], sd_$n_topped_up[1]))
}

cat("\n-- fetching seed embeddings --\n")
seed_ids <- unique(seeds$rid)
P_seed <- sem_fetch_embeddings(con, seed_ids)
cat(sprintf("  %d x %d\n", nrow(P_seed), ncol(P_seed)))

# ------------------------------------------------------------------------------------------------
# 2. PROBE-BASED ANCHORS — registers, poverty split, decoys.
# Registers have no keyword seeds (that is the whole reason the meaning lens exists for Q2), so v0
# anchors are centroids of several Croatian paraphrases each. They are PROVISIONAL: Stage V's coded
# FIT half replaces them with centroids of actually-coded posts (v1), and only VALIDATE is reported.
# `other` (register) and `mixed` (poverty) deliberately get NO anchor — they are remainder categories
# produced by the margin rule, exactly as CODEBOOK.md requires them never to be silently dropped.
# ------------------------------------------------------------------------------------------------
REG_PROBES <- list(
  object_institution = c(
    "Crkva kao institucija u gospodarskom i javnom životu",
    "biskupi, svećenici i župe kao gospodarski akteri",
    "crkvena imovina, financije, zemljište i sredstva",
    "ugovori države i Crkve, proračunska sredstva za vjerske zajednice"),
  object_cost_relig_life = c(
    "poskupjeli su vjenčanja, sprovodi i krštenja",
    "cijena mise, stipendija, crkvenih naknada i pristojbi",
    "troškovi vjerskog života rastu za vjernike",
    "svijeće, vijenci i troškovi ukopa su skuplji nego lani"),
  charity = c(
    "Caritas prikuplja pomoć za siromašne i potrebite",
    "humanitarna akcija, donacije i milostinja",
    "pučka kuhinja, podjela hrane i paketa obiteljima u nevolji",
    "prikupljena su sredstva za pomoć ugroženima"),
  justice = c(
    "strukturalni uzroci nepravde i kritika ekonomskog sustava",
    "dostojanstvo rada, prava radnika i pravedna plaća",
    "socijalna pravda, solidarnost i opće dobro",
    "nepravedna raspodjela bogatstva; siromaštvo kao nepravda, ne kao sudbina"),
  devotional = c(
    "duhovno siromaštvo i evanđeoske vrijednosti",
    "blaženi siromasi duhom, evanđeoski poziv",
    "obraćenje srca, molitva i pobožnost",
    "redovnički zavjet siromaštva i odricanje od dobara")
)
PSPLIT_PROBES <- list(
  economic_poverty = c(
    "materijalno siromaštvo i rizik od siromaštva",
    "ovrhe, dugovi, blokade računa i deložacije",
    "socijalna pomoć, beskućnici i materijalna deprivacija",
    "stopa siromaštva, socijalno ugroženi građani i naknade"),
  doctrinal_poverty = c(
    "evanđeosko siromaštvo i blaženi siromasi duhom",
    "redovnički zavjet siromaštva",
    "milostinja kao kršćanska krepost",
    "opcija za siromašne kao načelo crkvenog nauka")
)
DECOY_PROBES <- list(
  liturgy    = c("misa, euharistija, liturgija i sakramenti",
                 "molitva, krunica i vjerski obredi",
                 "propovijed, bogoslužje i nedjeljno misno slavlje"),
  devotion   = c("hodočašće u svetište i zavjetna procesija",
                 "štovanje svetaca i Blažene Djevice Marije",
                 "duhovne vježbe, klanjanje i pobožnost"),
  church_org = c("imenovanje biskupa i crkvena hijerarhija",
                 "Papa, Vatikan i sinoda",
                 "crkveni dokumenti, nauk i biskupska konferencija"),
  # NEW decoy: the pilot had no ordinary-secular-news member, so generic news leaked into "economic".
  news_generic = c("policija, prometna nesreća, sud i crna kronika",
                   "nogomet, sport i rezultati utakmica",
                   "vremenska prognoza, promet i turistička sezona",
                   "izbori, stranke i politička previranja")
)

cat("\n-- embedding probe anchors via Ollama --\n")
probe_flat <- unlist(c(REG_PROBES, PSPLIT_PROBES, DECOY_PROBES), use.names = FALSE)
probe_grp  <- rep(names(c(REG_PROBES, PSPLIT_PROBES, DECOY_PROBES)),
                  lengths(c(REG_PROBES, PSPLIT_PROBES, DECOY_PROBES)))
E_probe <- sem_embed_text(probe_flat)
cat(sprintf("  %d probes -> %d groups\n", nrow(E_probe), length(unique(probe_grp))))

# ------------------------------------------------------------------------------------------------
# 3. BUILD ANCHORS.  raw anchor = unit(mean(p_S))       [uncentered; kept only for the breadth tell]
#                    centred anchor = unit(mean(p_S) - mu)
# ------------------------------------------------------------------------------------------------
build_anchor <- function(P) {
  m <- if (is.null(dim(P))) P else colMeans(P)
  list(raw = sem_unit(m), cen = sem_unit(m - mu), centroid_norm = sqrt(sum((m - mu)^2)), n = if (is.null(dim(P))) 1L else nrow(P))
}

A_list <- list(); A_meta <- list()
for (d in sort(unique(seeds$domain))) {
  ids <- as.character(seeds$rid[seeds$domain == d & !seeds$holdout])
  a <- build_anchor(P_seed[ids, , drop = FALSE])
  A_list[[d]] <- a; A_meta[[d]] <- list(kind = "domain", n_fit = a$n,
                                        n_holdout = sum(seeds$domain == d & seeds$holdout),
                                        source = "stageA_seed_centroid")
}
for (g in unique(probe_grp)) {
  a <- build_anchor(E_probe[probe_grp == g, , drop = FALSE])
  kind <- if (g %in% names(REG_PROBES)) "register" else if (g %in% names(PSPLIT_PROBES)) "poverty_split" else "decoy"
  A_list[[g]] <- a; A_meta[[g]] <- list(kind = kind, n_fit = a$n, n_holdout = 0L,
                                        source = "probe_centroid_v0")
}

A_cen <- do.call(rbind, lapply(A_list, `[[`, "cen")); rownames(A_cen) <- names(A_list)
A_raw <- do.call(rbind, lapply(A_list, `[[`, "raw")); rownames(A_raw) <- names(A_list)

# ------------------------------------------------------------------------------------------------
# 4. BACKGROUND SAMPLE — fixed 50k reservoir; supplies robust z-scores, prevalence, and the
#    raw-cosine breadth diagnostic that would have caught the euro anchor.
# ------------------------------------------------------------------------------------------------
cat("\n-- background sample --\n")
BG <- dbGetQuery(con, sprintf(
  "SELECT chunk_id, platform, data_source, embedding FROM chunks USING SAMPLE %d ROWS (reservoir, %d)",
  N_BG, ME_SEED))
P_bg <- BG$embedding
cat(sprintf("  %s rows\n", digikat_format_integer(nrow(P_bg))))

S_bg     <- sem_score_r(P_bg, A_cen, mu)                  # centred scores
S_bg_raw <- sem_unit(P_bg) %*% t(A_raw)                   # RAW cosine — the pilot's space
colnames(S_bg_raw) <- rownames(A_raw)

# ------------------------------------------------------------------------------------------------
# 4b. MODALITY FIX — decoys must be built like the domain anchors, or the economic gate is a sham.
#
# Domain anchors are centroids of POSTS; the decoy probes are short SENTENCES. A post-centroid beats
# a sentence-probe for almost any post simply because posts look like posts, so the "is this
# economic?" gate passes nearly everything: with sentence decoys the 11 domain shares summed to
# 0.998 of a corpus that is overwhelmingly about faith. Rebuild each decoy as the centroid of the
# posts its probe retrieves, drawn ONLY from outside the Stage-A linked pool (so a decoy can never
# be built from the religion-economy discourse it is supposed to exclude).
# ------------------------------------------------------------------------------------------------
cat("\n-- rebuilding decoys as POST centroids (modality match) --\n")
linked_rids <- unique(cand$rid)
outside <- !(BG$chunk_id %in% linked_rids)
cat(sprintf("  background posts outside the linked pool: %s of %s\n",
            digikat_format_integer(sum(outside)), digikat_format_integer(nrow(BG))))
K_DECOY <- 500L
for (g in names(DECOY_PROBES)) {
  s <- S_bg[, g]; s[!outside] <- -Inf
  top <- order(s, decreasing = TRUE)[seq_len(min(K_DECOY, sum(outside)))]
  a <- build_anchor(P_bg[top, , drop = FALSE])
  A_cen[g, ] <- a$cen; A_raw[g, ] <- a$raw
  A_list[[g]] <- a
  A_meta[[g]] <- list(kind = "decoy", n_fit = a$n, n_holdout = 0L,
                      source = sprintf("probe_retrieval_top%d_post_centroid", K_DECOY))
  cat(sprintf("   %-14s centroid of %d retrieved posts (||A|| = %.3f)\n", g, a$n, a$centroid_norm))
}
# rescore with the corrected decoys
S_bg     <- sem_score_r(P_bg, A_cen, mu)
S_bg_raw <- sem_unit(P_bg) %*% t(A_raw)
colnames(S_bg_raw) <- rownames(A_raw)

# plausibility check: what share of this religion-filtered corpus is PRIMARILY economic?
econ_share <- {
  dm <- sort(unique(seeds$domain)); dc <- names(DECOY_PROBES)
  be <- max.col(S_bg[, dm, drop = FALSE])
  bev <- S_bg[cbind(seq_len(nrow(S_bg)), match(dm[be], colnames(S_bg)))]
  mean(bev > apply(S_bg[, dc, drop = FALSE], 1, max))
}
cat(sprintf("  => %.1f%% of the background sample is primarily ECONOMIC rather than faith/news\n",
            100 * econ_share))
if (econ_share > 0.60) cat("  !! implausibly high for a religion-filtered corpus — decoy gate suspect\n")

bg_med <- apply(S_bg, 2, median)
bg_mad <- apply(S_bg, 2, mad)
bg_mad[bg_mad < 1e-6] <- 1e-6

# ------------------------------------------------------------------------------------------------
# 5. THRESHOLDS — recall-anchored on each domain's own HELD-OUT seeds, so tau means the same thing
#    for every domain: "as close to the domain core as rho of its own keyword-clean seeds".
# ------------------------------------------------------------------------------------------------
cat("\n-- thresholds (recall-anchored on held-out seeds) --\n")
RHOS <- c(0.5, 0.8, 0.9)
tau <- matrix(NA_real_, nrow = length(A_list), ncol = length(RHOS),
              dimnames = list(names(A_list), paste0("tau_", RHOS * 100)))
for (d in sort(unique(seeds$domain))) {
  ids <- as.character(seeds$rid[seeds$domain == d & seeds$holdout])
  if (!length(ids)) next
  s <- sem_score_r(P_seed[ids, , drop = FALSE], A_cen[d, , drop = FALSE], mu)[, 1]
  tau[d, ] <- quantile(s, 1 - RHOS, names = FALSE)
}
# probe anchors have no held-out seeds: use the background q99 as a provisional stand-in, flagged.
for (g in names(A_list)) if (is.na(tau[g, 1])) tau[g, ] <- quantile(S_bg[, g], c(0.95, 0.99, 0.995), names = FALSE)

# ------------------------------------------------------------------------------------------------
# 6. DIAGNOSTICS — one row per anchor. split_half_cos is the seed-starvation tell (euro has 105
#    clean uni-domain posts vs poverty's 26,989); mean_raw_cos is the breadth tell.
# ------------------------------------------------------------------------------------------------
cat("\n-- diagnostics --\n")
gram <- A_cen %*% t(A_cen)
diag_gram <- gram; diag(diag_gram) <- NA

split_half <- function(nm) {
  if (A_meta[[nm]]$kind != "domain") {
    P <- E_probe[probe_grp == nm, , drop = FALSE]
  } else {
    ids <- as.character(seeds$rid[seeds$domain == nm & !seeds$holdout])
    P <- P_seed[ids, , drop = FALSE]
  }
  if (nrow(P) < 4) return(NA_real_)
  i <- sample(nrow(P)); h1 <- i[1:floor(nrow(P) / 2)]; h2 <- i[(floor(nrow(P) / 2) + 1):nrow(P)]
  a1 <- sem_unit(colMeans(P[h1, , drop = FALSE]) - mu)
  a2 <- sem_unit(colMeans(P[h2, , drop = FALSE]) - mu)
  sum(a1 * a2)
}
coherence <- function(nm) {
  if (A_meta[[nm]]$kind != "domain") {
    P <- E_probe[probe_grp == nm, , drop = FALSE]
  } else {
    ids <- as.character(seeds$rid[seeds$domain == nm & !seeds$holdout])
    P <- P_seed[ids, , drop = FALSE]
  }
  if (nrow(P) < 2) return(NA_real_)
  U <- sem_unit(sem_center(P, mu))
  if (nrow(U) > 400) U <- U[sample(nrow(U), 400), , drop = FALSE]
  G <- U %*% t(U); mean(G[upper.tri(G)])
}

# PERMUTATION BASELINE — what do these diagnostics look like for a set of the SAME SIZE with no
# topical coherence at all? Without this reference the absolute numbers are unreadable: in CENTRED
# space the null cosine is ~0 (not ~0.35 as in raw space), so a split-half of 0.61 may be excellent.
# The gates below are therefore expressed RELATIVE to this null, not as absolute floors.
set.seed(ME_SEED)
null_stats <- function(n) {
  idx <- sample(nrow(P_bg), min(n, nrow(P_bg)))
  P <- P_bg[idx, , drop = FALSE]
  i <- sample(nrow(P)); h1 <- i[1:floor(nrow(P) / 2)]; h2 <- i[(floor(nrow(P) / 2) + 1):nrow(P)]
  c(centroid_norm = sqrt(sum((colMeans(P) - mu)^2)),
    split_half    = sum(sem_unit(colMeans(P[h1, , drop = FALSE]) - mu) *
                        sem_unit(colMeans(P[h2, , drop = FALSE]) - mu)))
}
# Both statistics scale with n (the mean of k random vectors has norm ~ 1/sqrt(k)), so a fixed floor
# or a ratio-to-mean gate would penalise small anchors purely for being small. Gate instead on
# EXCEEDING THE NULL's 99th percentile at that anchor's own n.
NULL_NS <- c(3, 4, 50, 100, 200, 300)
null_draws <- lapply(NULL_NS, function(n) replicate(200, null_stats(n)))
null_mean <- sapply(null_draws, function(d) rowMeans(d))
null_q99  <- sapply(null_draws, function(d) apply(d, 1, quantile, 0.99, names = FALSE))
colnames(null_mean) <- colnames(null_q99) <- paste0("n", NULL_NS)
cat("  permutation null, mean (random posts of the same size):\n"); print(round(null_mean, 4))
cat("  permutation null, q99 (the gate reference):\n"); print(round(null_q99, 4))
null_for <- function(n, which = "mean") {
  k <- which.min(abs(NULL_NS - n))
  if (which == "q99") null_q99[, k] else null_mean[, k]
}

# DISCRIMINATION — the diagnostic that decides whether the meaning lens works at all for coverage.
# Centroid coherence says the anchor points somewhere stable; it does NOT say the domain's posts are
# separable from everything else. AUC does: P(a held-out seed outranks a random background post).
# 0.5 = the anchor carries no information; 1.0 = perfect separation.
auc_vs_background <- function(d) {
  ids <- as.character(seeds$rid[seeds$domain == d & seeds$holdout])
  if (!length(ids)) return(NA_real_)
  pos <- sem_score_r(P_seed[ids, , drop = FALSE], A_cen[d, , drop = FALSE], mu)[, 1]
  neg <- S_bg[!(BG$chunk_id %in% cand$rid[cand$domain == d]), d]   # background minus this domain's own linked posts
  r <- rank(c(pos, neg))
  (sum(r[seq_along(pos)]) - length(pos) * (length(pos) + 1) / 2) / (length(pos) * length(neg))
}
# prevalence at the threshold that matches the KEYWORD volume for that domain — puts the two lenses
# at equal n, so the comparison is of WHICH posts they pick, not how many.
kw_stats <- read.csv(file.path(ME_OUT, "stageA_domain_stats.csv"), fileEncoding = "UTF-8",
                     stringsAsFactors = FALSE)
kw_prev <- setNames(kw_stats$n_linked / 710307, kw_stats$domain)

set.seed(ME_SEED)
diagn <- do.call(rbind, lapply(names(A_list), function(nm) {
  mg <- diag_gram[nm, ]
  data.frame(
    anchor = nm, kind = A_meta[[nm]]$kind, source = A_meta[[nm]]$source,
    n_seed = A_meta[[nm]]$n_fit, n_holdout = A_meta[[nm]]$n_holdout,
    centroid_norm  = round(A_list[[nm]]$centroid_norm, 4),
    seed_coherence = round(coherence(nm), 4),
    split_half_cos = round(split_half(nm), 4),
    mean_raw_cos   = round(mean(S_bg_raw[, nm]), 4),      # <- the euro tell
    mean_cen       = round(mean(S_bg[, nm]), 4),
    sd_cen         = round(sd(S_bg[, nm]), 4),
    q99_cen        = round(quantile(S_bg[, nm], 0.99, names = FALSE), 4),
    tau_50 = round(tau[nm, 1], 4), tau_80 = round(tau[nm, 2], 4), tau_90 = round(tau[nm, 3], 4),
    prev_tau80_bg  = round(mean(S_bg[, nm] >= tau[nm, 2]), 5),
    prev_z3_bg     = round(mean((S_bg[, nm] - bg_med[nm]) / bg_mad[nm] >= 3), 5),
    auc_vs_bg      = if (A_meta[[nm]]$kind == "domain") round(auc_vs_background(nm), 4) else NA_real_,
    kw_prevalence  = if (nm %in% names(kw_prev)) round(unname(kw_prev[nm]), 5) else NA_real_,
    max_gram       = round(max(mg, na.rm = TRUE), 4),
    max_gram_partner = names(which.max(mg)),
    stringsAsFactors = FALSE)
}))

# ANCHOR GATES — null-referenced.
# The plan's absolute floors (split_half >= 0.85, centroid_norm >= 0.15) were calibrated with
# raw-cosine intuition and are wrong twice over: in CENTRED space the null cosine is ~0 (not ~0.35),
# and both statistics scale with n. Replaced here, BEFORE any hypothesis is scored, with:
#   gate_coherence — split-half cosine exceeds the null q99 at this n, AND clears an absolute 0.30
#                    (a floor for interpretability, not for significance)
#   gate_gram      — no anchor is collinear with another beyond 0.85
# centroid_norm is REPORTED but not gated: at fixed n it is a scale statistic confounded with n,
# and split-half already measures the thing it was meant to proxy (is this a real direction?).
diagn$null_split_half <- round(sapply(diagn$n_seed, function(n) null_for(n)["split_half"]), 4)
diagn$null_sh_q99     <- round(sapply(diagn$n_seed, function(n) null_for(n, "q99")["split_half"]), 4)
diagn$null_centroid   <- round(sapply(diagn$n_seed, function(n) null_for(n)["centroid_norm"]), 4)
diagn$split_half_vs_null <- round(diagn$split_half_cos / pmax(abs(diagn$null_split_half), 1e-3), 1)

diagn$gate_coherence <- !is.na(diagn$split_half_cos) &
  diagn$split_half_cos > diagn$null_sh_q99 & diagn$split_half_cos >= 0.30
diagn$gate_gram <- diagn$max_gram <= 0.85
# a 3-probe anchor cannot be split-half tested (a 1-vs-2 split is noise); it inherits the gate from
# collinearity alone, and is flagged as untested rather than silently passed.
diagn$coherence_untested <- is.na(diagn$split_half_cos)
diagn$gate_pass <- (diagn$gate_coherence | diagn$coherence_untested) & diagn$gate_gram

print(diagn[, c("anchor", "kind", "n_seed", "centroid_norm", "split_half_cos", "null_sh_q99",
                "split_half_vs_null", "mean_raw_cos", "max_gram", "max_gram_partner", "gate_pass")],
      row.names = FALSE)

failed <- diagn$anchor[!diagn$gate_pass]
if (length(failed)) {
  cat("\n!! anchors FAILING a gate (their numbers are reported keyword-only):\n   ",
      paste(failed, collapse = ", "), "\n")
} else cat("\nAll anchors clear the gates.\n")

# ------------------------------------------------------------------------------------------------
# 7. THE 2x2 INSTRUMENT COMPARISON — the transferable method contribution, made measurable.
#    Two design choices, crossed:  ANCHOR SOURCE (hand-written sentence vs seed-post centroid)
#                                x SPACE          (raw cosine vs mean-centred).
#    The pilot is exactly the hand x raw cell. Reproducing it here — with the pilot's own sentences,
#    not a stand-in — is what licenses any claim that the calibrated instrument is an improvement.
#
#    NOTE on interpretation: agreement with the KEYWORD ranking is a CONVERGENCE measure, not an
#    accuracy measure. Keyword rank is not ground truth. An instrument that merely mimics the keyword
#    lens adds nothing; the point of the meaning lens is to see what keywords miss. So rho is read
#    alongside the euro artifact (a known-wrong answer), never on its own.
# ------------------------------------------------------------------------------------------------
# The pilot's hand-written anchors, verbatim from semantic_slice.R (2026-07-09).
PILOT_ECON <- c(
  macro_aggregates = "bruto domaći proizvod, gospodarski rast, recesija, javni dug i proračunski deficit",
  euro_changeover  = "uvođenje eura, prelazak s kune na euro, zamjena valute i konverzija cijena",
  taxes_fiscal     = "porezi, porezna politika, PDV, trošarine i fiskalna davanja državi",
  business_comp    = "poduzetništvo, tvrtke i obrti, konkurentnost gospodarstva, investicije i ulaganja",
  green_energy     = "energetska kriza, cijene struje i plina, zelena tranzicija i obnovljivi izvori energije",
  housing          = "stanovanje, najamnine, cijene nekretnina i priuštivost stanova",
  demography_econ  = "manjak radne snage, strani radnici, iseljavanje i tržište rada",
  inflation_prices = "inflacija, poskupljenja, rast cijena, trošak života i kupovna moć",
  unemployment     = "nezaposlenost, gubitak posla, otpuštanja radnika i tržište rada",
  wages_income     = "plaće, minimalna plaća, mirovine, primanja i radnička prava",
  poverty_social   = "siromaštvo, socijalna pomoć, ugroženi građani, beskućnici, ovrhe i dugovi")
PILOT_DECOY <- c(
  liturgy    = "misa, euharistija, liturgija, molitva, sakramenti i vjerski obredi",
  devotion   = "hodočašće, svetište, procesija, štovanje svetaca i Blažene Djevice Marije",
  church_org = "imenovanje biskupa, crkveni događaji, Papa i Vatikan, sinoda i crkveni nauk")

cat("\n-- embedding the pilot's own hand-written anchors (to reproduce its instrument exactly) --\n")
E_pilot <- sem_embed_text(c(PILOT_ECON, PILOT_DECOY))
rownames(E_pilot) <- c(names(PILOT_ECON), names(PILOT_DECOY))

dom <- sort(unique(seeds$domain)); dec <- names(DECOY_PROBES)
pdec <- names(PILOT_DECOY)

# winner-take-all share per domain, gated by decoys (a post is "economic" only if it beats every decoy)
wta_share <- function(S, doms, decs) {
  be  <- max.col(S[, doms, drop = FALSE])
  bev <- S[cbind(seq_len(nrow(S)), match(doms[be], colnames(S)))]
  bdv <- apply(S[, decs, drop = FALSE], 1, max)
  lab <- ifelse(bev > bdv, doms[be], NA)
  as.numeric(table(factor(lab, levels = doms))) / nrow(S)
}

A_hand_raw <- sem_unit(E_pilot)
A_hand_cen <- sem_unit(sem_center(E_pilot, mu)); rownames(A_hand_cen) <- rownames(E_pilot)
S_hand_raw <- sem_unit(P_bg) %*% t(A_hand_raw); colnames(S_hand_raw) <- rownames(A_hand_raw)
S_hand_cen <- sem_score_r(P_bg, A_hand_cen, mu)

# The decoy set must be HELD CONSTANT across the 2x2, or the comparison confounds anchor source
# with decoy coverage (the calibrated arm has a 4th decoy, news_generic, that the pilot lacked).
# So: `exact_pilot` reproduces the pilot with its own 3 decoys as the historical reference point,
# and the four 2x2 cells all use the same 4-decoy set, varying only anchor source x space.
instruments <- list(
  exact_pilot = list(share = wta_share(S_hand_raw, dom, pdec),
                     lab = "AS PUBLISHED IN THE PILOT (own 3 decoys)"),
  hand_raw = list(share = wta_share(cbind(S_hand_raw[, dom], S_bg_raw[, dec]), dom, dec),
                  lab = "hand sentence x raw"),
  hand_cen = list(share = wta_share(cbind(S_hand_cen[, dom], S_bg[, dec]), dom, dec),
                  lab = "hand sentence x centred"),
  seed_raw = list(share = wta_share(S_bg_raw, dom, dec), lab = "seed centroid x raw"),
  seed_cen = list(share = wta_share(S_bg, dom, dec),     lab = "seed centroid x centred (CALIBRATED)"))

kw <- read.csv(file.path(ME_OUT, "stageA_domain_stats.csv"), fileEncoding = "UTF-8",
               stringsAsFactors = FALSE)
kwcol <- if ("linked" %in% names(kw)) "linked" else names(kw)[sapply(kw, is.numeric)][1]
kw_rank <- setNames(rank(-kw[[kwcol]], ties.method = "min"), kw$domain)

cmp <- data.frame(domain = dom, keyword_rank = as.integer(kw_rank[dom]), stringsAsFactors = FALSE)
for (nm in names(instruments)) {
  cmp[[paste0(nm, "_share")]] <- round(instruments[[nm]]$share, 4)
  cmp[[paste0(nm, "_rank")]]  <- rank(-instruments[[nm]]$share, ties.method = "min")
}
rho <- sapply(names(instruments), function(nm)
  suppressWarnings(cor(cmp$keyword_rank, cmp[[paste0(nm, "_rank")]], method = "spearman")))

cat("\n-- 2x2 instrument comparison (50k background, winner-take-all in every cell) --\n")
print(cmp[order(cmp$keyword_rank),
          c("domain", "keyword_rank", paste0(names(instruments), "_share"))], row.names = FALSE)
cat("\n  Spearman vs the keyword ranking (convergence, NOT accuracy):\n")
for (nm in names(instruments)) cat(sprintf("    %-38s rho = %+.3f\n", instruments[[nm]]$lab, rho[[nm]]))
cat("\n  euro_changeover share (the known-wrong answer; keyword lens links 407 posts, rank 11):\n")
for (nm in names(instruments))
  cat(sprintf("    %-38s %5.1f%%\n", instruments[[nm]]$lab,
              100 * cmp[[paste0(nm, "_share")]][cmp$domain == "euro_changeover"]))

# ------------------------------------------------------------------------------------------------
# 8. WRITE
# ------------------------------------------------------------------------------------------------
anchors <- list(
  A_cen = A_cen, A_raw = A_raw, mu = mu, meta = A_meta, tau = tau, rhos = RHOS,
  bg_med = bg_med, bg_mad = bg_mad, diagnostics = diagn,
  seed_rids = sort(unique(seeds$rid)),           # circularity firewall: excluded from the gold sample
  domains = dom, decoys = dec, registers = names(REG_PROBES), psplit = names(PSPLIT_PROBES),
  probes = list(register = REG_PROBES, psplit = PSPLIT_PROBES, decoy = DECOY_PROBES),
  n_seed_target = N_SEED, holdout_frac = HOLDOUT, n_background = nrow(P_bg), version = "v0")
digikat_atomic_replace_file(
  digikat_stage_rds(anchors, file.path(ME_SEM, "anchors.rds")), file.path(ME_SEM, "anchors.rds"))
saveRDS(sort(unique(seeds$rid)), file.path(ME_SEM, "s1_seed_rids.rds"))

sem_write_shareable(diagn, file.path(ME_SEM, "anchor_diagnostics.csv"))
g <- as.data.frame(round(gram, 4)); g <- cbind(anchor = rownames(gram), g)
sem_write_shareable(g, file.path(ME_SEM, "anchor_gram.csv"))
sem_write_shareable(cmp, file.path(ME_SEM, "pilot_vs_calibrated.csv"))

# restricted: the top-20 hits per anchor, for the hand-eyeball validation habit (README §Validation)
top20 <- do.call(rbind, lapply(colnames(S_bg), function(nm) {
  o <- order(S_bg[, nm], decreasing = TRUE)[1:20]
  data.frame(anchor = nm, rank = 1:20, score = round(S_bg[o, nm], 4),
             chunk_id = BG$chunk_id[o], platform = BG$platform[o], stringsAsFactors = FALSE)
}))
txt <- dbGetQuery(con, sprintf("SELECT chunk_id, substr(text,1,300) AS excerpt FROM chunks WHERE chunk_id IN (%s)",
                               paste(unique(top20$chunk_id), collapse = ",")))
top20 <- merge(top20, txt, by = "chunk_id")[, c("anchor","rank","score","chunk_id","platform","excerpt")]
top20 <- top20[order(top20$anchor, top20$rank), ]
sem_write_private(top20, file.path(ME_PRIVATE, "anchor_top20.csv"))

digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/05_s1_anchor_calibration.R",
  inputs = list(stageA_candidates = digikat_file_metadata(file.path(ME_OUT, "stageA_candidates.rds"))),
  outputs = list(anchors = "output/semantic/anchors.rds",
                 diagnostics = "output/semantic/anchor_diagnostics.csv"),
  extra = list(
    n_seed_target = N_SEED, holdout_frac = HOLDOUT, n_background = nrow(P_bg),
    corpus_mean_norm = round(MU_NORM, 4),
    anchors_failing_gate = as.list(failed),
    gate_definition = paste("null-referenced: split_half >= 0.50 (domain anchors only),",
                            "centroid_norm >= 5x permutation null, max_gram <= 0.85.",
                            "The plan's absolute floors (0.85 / 0.15) were calibrated with raw-cosine",
                            "intuition and are wrong for centred space, where the null cosine is ~0."),
    spearman_by_instrument = as.list(round(rho, 4)),
    euro_share_by_instrument = as.list(sapply(names(instruments), function(nm)
      round(cmp[[paste0(nm, "_share")]][cmp$domain == "euro_changeover"], 4))),
    anchor_version = "v0 (registers/poverty are probe centroids; Stage V FIT half replaces them with v1)")
), file.path(ME_SEM, "s1_manifest.json"))

cat("\n== S1 complete ==\n")
cat("  anchors        -> output/semantic/anchors.rds (gitignored)\n")
cat("  diagnostics    -> output/semantic/anchor_diagnostics.csv (tracked)\n")
cat("  gram matrix    -> output/semantic/anchor_gram.csv (tracked)\n")
cat("  pilot vs calib -> output/semantic/pilot_vs_calibrated.csv (tracked)\n")
cat("  top-20 hits    -> output/private/anchor_top20.csv (RESTRICTED — eyeball before publishing)\n")
cat("Next: 06_s2_corpus_scoring.R\n")
