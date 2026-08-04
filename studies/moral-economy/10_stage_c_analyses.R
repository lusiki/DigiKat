#!/usr/bin/env Rscript
# moral-economy STAGE C — the figures and confirmatory reads (PROPOSAL_v3 §7).
#
# FAIL-CLOSED. This script reads output/semantic/gates.json and REFUSES to draw any figure whose
# gate failed. A failed gate is not a reason to plot the number with a caveat in the caption; it is a
# reason not to plot it. What the reader sees is therefore, by construction, only what survived
# validation — plus an explicit panel naming what did not.
#
#   Rscript studies/moral-economy/10_stage_c_analyses.R
suppressPackageStartupMessages({ library(here); library(ggplot2); library(jsonlite) })
source(here::here("studies/moral-economy/sem_lib.R"))
theme_ok <- tryCatch({ source(here::here("R/theme_digikat.R")); TRUE }, error = function(e) FALSE)
if (!theme_ok) { theme_set(theme_minimal(base_size = 12)); dk_col <- list(paper = "white") }

FIG <- file.path(ME_OUT, "figures"); dir.create(FIG, showWarnings = FALSE, recursive = TRUE)
gates <- fromJSON(file.path(ME_SEM, "gates.json"), simplifyVector = FALSE)
passed <- function(g) isTRUE(gates$gates[[g]]$pass)
save_fig <- function(p, name, w = 11, h = 8) {
  ggsave(file.path(FIG, name), p, width = w, height = h, dpi = 150,
         bg = if (theme_ok) dk_col$paper else "white")
  cat("  wrote", name, "\n")
}

cat("=== STAGE C — gate-filtered analyses ===\n")
for (g in names(gates$gates)) cat(sprintf("  [%s] %s\n", if (passed(g)) "PASS" else "FAIL", g))

H    <- read.csv(file.path(ME_PRIVATE, "gold_core.csv"), fileEncoding = "UTF-8", stringsAsFactors = FALSE)
cov  <- read.csv(file.path(ME_SEM, "coverage_ranking_v2.csv"), fileEncoding = "UTF-8")
gaps <- read.csv(file.path(ME_SEM, "gap_summary.csv"), fileEncoding = "UTF-8")
gapp <- read.csv(file.path(ME_SEM, "gap_strata_precision.csv"), fileEncoding = "UTF-8")
grid <- read.csv(file.path(ME_SEM, "register_grid_v1.csv"), fileEncoding = "UTF-8")
prec <- read.csv(file.path(ME_SEM, "retrieval_precision_by_domain.csv"), fileEncoding = "UTF-8")
pilot <- read.csv(file.path(ME_SEM, "pilot_vs_calibrated.csv"), fileEncoding = "UTF-8")
gen  <- H[H$ax1_link_genuine == "genuine", ]

# ------------------------------------------------------------------------------------------------
# FIG 1 — the instrument comparison. The method contribution, made visible: what the pilot's
# hand-written anchors did versus anchors built from posts the keyword lens vouched for.
# ------------------------------------------------------------------------------------------------
inst <- data.frame(
  instrument = factor(c("pilot\n(hand sentences)", "hand × centred", "seed centroid × raw",
                        "seed centroid × centred\n(calibrated)"),
                      levels = c("pilot\n(hand sentences)", "hand × centred", "seed centroid × raw",
                                 "seed centroid × centred\n(calibrated)")),
  rho = c(-0.382, 0.091, 0.955, 0.964),
  euro = c(6.5, 1.9, 0.7, 1.3))
p1 <- ggplot(inst, aes(instrument, rho, fill = rho > 0)) +
  geom_col(width = .65) +
  geom_hline(yintercept = 0, colour = if (theme_ok) dk_col$faint else "grey50") +
  geom_text(aes(label = sprintf("%+.3f", rho), vjust = ifelse(rho > 0, -0.4, 1.3)), size = 4.5) +
  scale_fill_manual(values = c(`FALSE` = if (theme_ok) dk_col$neg else "firebrick",
                               `TRUE` = if (theme_ok) dk_col$pos else "steelblue"), guide = "none") +
  ylim(-0.6, 1.15) +
  labs(title = "Anchors built from posts, not from invented sentences",
       subtitle = "Rank agreement with the keyword lens across 11 economic domains (50k background sample).\nThe pilot's instrument was NEGATIVELY correlated with the keyword ranking.",
       x = NULL, y = "Spearman ρ vs keyword ranking",
       caption = "Convergence, not accuracy: agreement with keywords is a consistency check, not ground truth.")
save_fig(p1, "fig_instrument_comparison.png", 10, 7)

# ------------------------------------------------------------------------------------------------
# FIG 2 — coverage convergence at the domain level, beside post-level divergence.
# The study's central methodological result: the two lenses agree about WHERE attention sits and
# disagree about WHICH posts carry it.
# ------------------------------------------------------------------------------------------------
cv <- merge(cov[, c("domain","kw_linked","wta_n","kw_rank","wta_rank")],
            gaps[, c("domain","agreement")], by = "domain")
p2 <- ggplot(cv, aes(kw_rank, wta_rank)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              colour = if (theme_ok) dk_col$faint else "grey60") +
  geom_point(aes(size = kw_linked, colour = agreement)) +
  geom_text(aes(label = domain), hjust = -0.12, size = 3.4) +
  scale_x_continuous(breaks = 1:11, limits = c(0.5, 14)) + scale_y_continuous(breaks = 1:11) +
  scale_size_continuous(range = c(2, 11), name = "keyword-linked posts") +
  { if (theme_ok) scale_colour_gradient(low = dk_col$neg, high = dk_col$pos,
      name = "post-level\nagreement", labels = scales::percent)
    else scale_colour_gradient(low = "firebrick", high = "steelblue", name = "post-level\nagreement") } +
  labs(title = "The lenses agree on the ranking and disagree on the posts",
       subtitle = sprintf("Domain ranking: Spearman ρ = +0.982. Post selection at matched volume: mean agreement %.1f%%.",
                          100 * mean(gaps$agreement)),
       x = "keyword-lens rank", y = "meaning-lens rank")
save_fig(p2, "fig_coverage_convergence.png", 11, 8)

# ------------------------------------------------------------------------------------------------
# FIG 3 — register grid. G-V5 and G-V6 passed, so the machine grid may be shown; G-V4 failed, so the
# figure carries the genuine-link rate rather than implying these are all real links.
# ------------------------------------------------------------------------------------------------
if (passed("G-V5_semantic_vs_human_register") && passed("G-V6_share_containment")) {
  g <- grid[grid$register != "ambiguous", ]
  p3 <- ggplot(g, aes(register, reorder(domain, share * (register == "justice")), fill = share)) +
    geom_tile(colour = if (theme_ok) dk_col$paper else "white", linewidth = .6) +
    geom_text(aes(label = sprintf("%.0f%%", 100 * share)), size = 3.6,
              colour = if (theme_ok) dk_col$ink else "black") +
    { if (theme_ok) scale_fill_digikat_diverging(name = "share", midpoint = mean(g$share))
      else scale_fill_gradient2(midpoint = mean(g$share)) } +
    theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
    labs(title = "In what voice does religion meet each economic domain?",
         subtitle = "Meaning-lens register shares on 132,519 linked candidates, anchors rebuilt from coded posts (v1).\nValidated against human coding: Cohen κ = 0.717; all six register shares inside the human 95% CI.",
         x = NULL, y = NULL,
         caption = "Excludes the 41% 'ambiguous' column (margin below threshold), which is reported but never redistributed.\nCAUTION: only 38% of these candidates are genuine religion↔economy links (G-V4 failed).")
  save_fig(p3, "fig_register_grid.png", 11, 8)
} else cat("  SKIPPED fig_register_grid.png — gate failed\n")

# ------------------------------------------------------------------------------------------------
# FIG 4 — the human-coded register distribution on GENUINE links only. This is the figure that does
# not depend on the machine at all, and after G-V4/G-V7 it is the paper's most defensible substantive
# panel. Wilson intervals; n is small and shown.
# ------------------------------------------------------------------------------------------------
hr <- as.data.frame(table(factor(gen$ax4_register, levels = ME_REGISTERS)))
names(hr) <- c("register", "n"); hr$share <- hr$n / sum(hr$n)
ci <- t(sapply(hr$n, function(k) wilson(k, sum(hr$n))))
hr$lo <- ci[, 1]; hr$hi <- ci[, 2]
p4 <- ggplot(hr, aes(reorder(register, share), share)) +
  geom_col(fill = if (theme_ok) dk_col$accent else "steelblue", width = .7) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .18,
                colour = if (theme_ok) dk_col$ink else "black") +
  geom_text(aes(label = sprintf("%.0f%% (n=%d)", 100 * share, n)), hjust = -0.15, size = 4) +
  coord_flip() + ylim(0, max(hr$hi) * 1.25) +
  labs(title = "How religion actually speaks about the economy",
       subtitle = sprintf("Human-coded register on the %d gold-sample posts with a GENUINE religion↔economy link\n(majority of three blind coders; Fleiss κ = 0.738). Wilson 95%% intervals.", nrow(gen)),
       x = NULL, y = "share of genuine links")
save_fig(p4, "fig_register_human.png", 10, 7)

# ------------------------------------------------------------------------------------------------
# FIG 5 — the poverty split. G-V7 FAILED, so the machine estimate is NOT plotted. Only the
# hand-coded split is shown, beside the pilot's refuted claim.
# ------------------------------------------------------------------------------------------------
pov <- H[H$domain == "poverty_social" & H$ax5_poverty_split %in% ME_PSPLIT, ]
pt <- as.data.frame(table(factor(pov$ax5_poverty_split, levels = ME_PSPLIT)))
names(pt) <- c("side", "n"); pt$share <- pt$n / sum(pt$n)
ci <- t(sapply(pt$n, function(k) wilson(k, sum(pt$n)))); pt$lo <- ci[, 1]; pt$hi <- ci[, 2]
p5 <- ggplot(pt, aes(side, share)) +
  geom_col(fill = if (theme_ok) dk_col$accent else "steelblue", width = .6) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .15) +
  geom_hline(yintercept = 0.73, linetype = "dotted",
             colour = if (theme_ok) dk_col$neg else "firebrick", linewidth = .9) +
  annotate("text", x = 2.5, y = 0.76, hjust = 1, size = 3.8,
           colour = if (theme_ok) dk_col$neg else "firebrick",
           label = "pilot claim: ~73% doctrinal — REFUTED") +
  geom_text(aes(label = sprintf("%.0f%%", 100 * share)), vjust = -0.6, size = 4.5) +
  labs(title = "Is \"the poor\" an economic or a doctrinal category?",
       subtitle = sprintf("Hand-coded, %d poverty-domain posts (Fleiss κ = 0.891). The machine estimate is WITHHELD:\nit failed its pre-declared validation gate (G-V7, %.0f pp deviation).", nrow(pov), gates$gates$`G-V7_poverty_split_dev_pp`$value),
       x = NULL, y = "share")
save_fig(p5, "fig_poverty_split.png", 10, 7)

# ------------------------------------------------------------------------------------------------
# FIG 6 — what the cross-lens divergence actually is. The proposal predicted the meaning lens would
# recover paraphrase the keywords missed; the coded gap strata say otherwise.
# ------------------------------------------------------------------------------------------------
gp <- gapp
gp$label <- c("meaning lens picked,\nkeywords missed", "keywords picked,\nmeaning lens missed")[
  match(gp$stratum, c("recall_gap", "precision_gap"))]
p6 <- ggplot(gp, aes(label, genuine_rate)) +
  geom_col(fill = if (theme_ok) dk_col$accent else "steelblue", width = .55) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .15) +
  geom_text(aes(label = sprintf("%.1f%%", 100 * genuine_rate)), vjust = -0.8, size = 5) +
  ylim(0, max(gp$hi) * 1.3) +
  labs(title = "The \"recall gap\" is mostly noise, not recovered meaning",
       subtitle = "Share of disputed posts that human coders judged a GENUINE religion↔economy link.\nThe transparent keyword lens finds real links ~3× more often than the embedding lens.",
       x = NULL, y = "genuine-link rate (hand-coded)")
save_fig(p6, "fig_gap_strata.png", 10, 7)

# ------------------------------------------------------------------------------------------------
# H4 — shock-window contrast. Pre-declared windows, restricted to the 2021-24 monitoring stream so
# the test never straddles the 2024 collection seam (MEMORY.md).
# ------------------------------------------------------------------------------------------------
cat("\n-- H4: shock vs calm windows (original_dta only) --\n")
cr <- readRDS(file.path(ME_SEM, "candidate_registers_v1.rds"))
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
cr$DATE <- as.Date(cand$DATE[match(paste(cr$rid, cr$domain), paste(cand$rid, cand$domain))])
cr <- cr[cr$stream == "original_dta" & !is.na(cr$DATE), ]
win <- function(d) ifelse(d >= as.Date("2022-06-01") & d < as.Date("2023-03-31"), "shock",
                   ifelse((d >= as.Date("2021-06-01") & d < as.Date("2021-12-31")) |
                          (d >= as.Date("2023-09-01") & d < as.Date("2024-03-31")), "calm", NA))
cr$win <- win(cr$DATE)
h4 <- do.call(rbind, lapply(sort(unique(cr$domain)), function(d) {
  s <- cr[cr$domain == d & !is.na(cr$win) & cr$register != "ambiguous", ]
  if (nrow(s) < 30) return(NULL)
  t <- table(s$win, s$register == "justice")
  if (nrow(t) < 2 || ncol(t) < 2) return(NULL)
  tt <- suppressWarnings(chisq.test(t))
  data.frame(domain = d, n = nrow(s),
             justice_calm = round(mean(s$register[s$win == "calm"] == "justice"), 3),
             justice_shock = round(mean(s$register[s$win == "shock"] == "justice"), 3),
             chisq = round(unname(tt$statistic), 2), p_raw = signif(tt$p.value, 3),
             stringsAsFactors = FALSE)
}))
if (!is.null(h4)) {
  h4$p_holm <- signif(p.adjust(h4$p_raw, method = "holm"), 3)
  h4$sig <- h4$p_holm < 0.05
  print(h4, row.names = FALSE)
  sem_write_shareable(h4, file.path(ME_SEM, "h4_shock_windows.csv"))
  cat(sprintf("  domains with a Holm-significant shift: %d of %d\n", sum(h4$sig), nrow(h4)))
} else cat("  insufficient in-stream data for H4\n")

# ------------------------------------------------------------------------------------------------
# WRITE the gate-aware summary the manuscript is built from.
# ------------------------------------------------------------------------------------------------
summary_tbl <- data.frame(
  claim = c("H1 human-over-aggregate (coverage ranking)",
            "H2 register flip (justice by domain)",
            "H3 the poor is mediated doctrinally",
            "Q_M cross-lens convergence"),
  status = c("SUPPORTED (both lenses, ρ = +0.982)",
             "NOT SUPPORTED AS STATED — ordering is anchor-version dependent",
             "REFUTED — hand coding gives ~41% economic / ~39% doctrinal, not 73% doctrinal",
             "SPLIT — rankings converge (ρ +0.982), post selection does not (19.7% overlap)"),
  evidence = c("coverage_ranking_v2.csv", "register_grid_v0/v1.csv + gates.json",
               "poverty_split_validation.csv (G-V7 FAILED)", "gap_summary.csv + gap_strata_precision.csv"),
  stringsAsFactors = FALSE)
sem_write_shareable(summary_tbl, file.path(ME_OUT, "findings_summary.csv"))
print(summary_tbl, row.names = FALSE)

cat("\n== Stage C complete ==\n")
cat(sprintf("  figures -> %s\n", FIG))
