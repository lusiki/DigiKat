#!/usr/bin/env Rscript
# moral-economy — THE FOUR FIGURES FOR THE RSP SUBMISSION, IN PRINT MONOCHROME.
#
# RSP prints monochrome (PROPOSAL_v5 Part II): greyscale or B/W only, white background, Arial
# lettering, >= 300 dpi, and a source line beneath every figure. The DigiKat house theme
# (R/theme_digikat.R) is cream-paper and hue-encoded, so it is exactly wrong here — Trap 12 says
# never submit a figure whose meaning depends on hue. This script therefore defines
# `theme_digikat_print()` locally rather than editing the shared theme, which the website depends on.
#
# Every encoding is redundant with position or fill VALUE (light-to-dark grey), never hue, and no
# figure needs its legend to be read in colour.
#
#   Rscript studies/moral-economy/24_rsp_figures.R
suppressPackageStartupMessages({ library(here); library(ggplot2) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_labels.R"))   # DOM/TERM labels shared with the tables

FIGDIR <- file.path(ME_OUT, "figures"); dir.create(FIGDIR, showWarnings = FALSE, recursive = TRUE)
DPI <- 300

theme_digikat_print <- function(base_size = 9) {
  theme_bw(base_size = base_size, base_family = "Arial") +
    theme(panel.background = element_rect(fill = "white", colour = NA),
          plot.background  = element_rect(fill = "white", colour = NA),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(colour = "grey88", linewidth = 0.3),
          panel.border = element_rect(colour = "grey40", linewidth = 0.4),
          axis.ticks = element_line(colour = "grey40", linewidth = 0.3),
          strip.background = element_rect(fill = "grey92", colour = "grey40", linewidth = 0.4),
          strip.text = element_text(colour = "black", size = base_size - 0.5),
          legend.position = "bottom", legend.title = element_blank(),
          legend.key = element_rect(fill = "white", colour = NA),
          plot.caption = element_text(hjust = 0, size = base_size - 1.5, colour = "grey25"),
          plot.title = element_text(size = base_size + 1, face = "bold"))
}
GREY <- c("grey25", "grey55", "grey80")

# The manuscript is English (IX.1), so labels are English. Domain and term names are translated
# once, in rsp_labels.R, so the paper, its tables and its figures cannot drift apart.

## ---- FIGURE 1: the gradient, raw and precision-corrected ------------------------------------
adj <- read.csv(file.path(ME_OUT, "cst_gradient_adjusted.csv"), fileEncoding = "UTF-8")
a <- adj[adj$code == "ax1_link_genuine", ]
f1 <- rbind(
  data.frame(domain = a$domain, panel = "As measured", rate = a$raw_rate,
             lo = NA_real_, hi = NA_real_),
  data.frame(domain = a$domain, panel = "Corrected for linkage precision", rate = a$adj_rate,
             lo = a$adj_lo, hi = a$adj_hi))
# Wilson intervals for the raw panel come from the robustness detail, which is the gated source
det <- read.csv(file.path(ME_OUT, "cst_robustness_detail.csv"), fileEncoding = "UTF-8")
b <- det[det$variant == "baseline", ]
f1$lo[f1$panel == "As measured"] <- b$lo[match(f1$domain[f1$panel == "As measured"], b$domain)]
f1$hi[f1$panel == "As measured"] <- b$hi[match(f1$domain[f1$panel == "As measured"], b$domain)]
f1$label <- DOM[f1$domain]
ord <- a$domain[order(a$raw_rate)]
f1$label <- factor(f1$label, levels = DOM[ord])
f1$panel <- factor(f1$panel, levels = c("As measured", "Corrected for linkage precision"))

p1 <- ggplot(f1, aes(label, rate)) +
  geom_col(aes(fill = panel), width = 0.68, colour = "grey20", linewidth = 0.25) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.25, linewidth = 0.35, colour = "grey15") +
  scale_fill_manual(values = c("As measured" = "grey70",
                               "Corrected for linkage precision" = "grey35"), guide = "none") +
  facet_wrap(~ panel, scales = "free_x") +
  coord_flip() +
  labs(x = NULL, y = "Linked pairs invoking magisterial doctrine (%)",
       title = "Figure 1. Doctrinal invocation by economic domain",
       caption = paste0("Source: authors' calculation on the DigiKat corpus of 710 307 Croatian ",
                        "digital media posts, 2021-2026.\nBars are per-domain rates; whiskers are ",
                        "95% intervals. Right panel divides each denominator by that domain's\n",
                        "hand-coded genuine-linkage rate (n = 60 linked pairs per domain)."))
p1 <- p1 + theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig1_gradient.png"), p1, width = 6.7, height = 4.1, dpi = DPI, bg = "white")

## ---- FIGURE 2: era composition by domain ------------------------------------------------------
era <- read.csv(file.path(ME_OUT, "cst_core_domain_era.csv"), fileEncoding = "UTF-8")
tot <- aggregate(Freq ~ domain, era, sum)
era$share <- 100 * era$Freq / tot$Freq[match(era$domain, tot$domain)]
keep <- c("green_energy", "poverty_social", "business_comp", "wages_income", "housing")
e <- era[era$domain %in% keep & era$era %in% c("classical", "conciliar", "francis"), ]
e$label <- factor(DOM[e$domain], levels = DOM[c("green_energy", "poverty_social", "business_comp",
                                                "wages_income", "housing")])
e$era <- factor(e$era, levels = c("classical", "conciliar", "francis"),
                labels = c("Classical (1891-1991)", "Conciliar", "Francis era"))
p2 <- ggplot(e, aes(label, share, fill = era)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68,
           colour = "grey20", linewidth = 0.25) +
  scale_fill_manual(values = c("grey25", "grey60", "grey88")) +
  labs(x = NULL, y = "Share of the domain's doctrinal pairs (%)",
       title = "Figure 2. Which vintage of doctrine surfaces where",
       caption = paste0("Source: authors' calculation. Rows are the eras of the magisterial ",
                        "documents named in each post; posts naming only a\ndoctrine marker and ",
                        "no document are excluded from this figure and reported separately in the text.")) +
  theme_digikat_print() +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
ggsave(file.path(FIGDIR, "rsp_fig2_era.png"), p2, width = 6.7, height = 3.9, dpi = DPI, bg = "white")

## ---- FIGURE 3: the confessional / secular boundary --------------------------------------------
v <- det[det$variant %in% c("confessional_only", "secular_min", "secular_max"), ]
v$panel <- factor(v$variant, levels = c("confessional_only", "secular_min", "secular_max"),
                  labels = c("Confessional outlets", "Secular outlets (narrow)",
                             "Secular outlets (widest)"))
v$label <- DOM[v$domain]
v$label <- factor(v$label, levels = DOM[ord])
p3 <- ggplot(v, aes(label, rate)) +
  geom_col(width = 0.68, fill = "grey60", colour = "grey20", linewidth = 0.25) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.25, linewidth = 0.35, colour = "grey15") +
  facet_wrap(~ panel, nrow = 1) + coord_flip() +
  labs(x = NULL, y = "Linked pairs invoking magisterial doctrine (%)",
       title = "Figure 3. Topical selection happens at the confessional/secular boundary",
       caption = paste0("Source: authors' calculation. 'Narrow' counts only outlets labelled ",
                        "secular; 'widest' additionally counts every unlabelled\noutlet as secular, ",
                        "the most hostile available assumption. Whiskers are 95% intervals.")) +
  theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig3_boundary.png"), p3, width = 6.9, height = 4.3, dpi = DPI, bg = "white")

## ---- FIGURE 4: which doctrinal vocabulary actually circulates ---------------------------------
# The paper's §6 claim is a comparison between terms, not a single count, so the whole detected
# vocabulary is shown rather than the one term the argument turns on: a reader can see that the
# option for the poor sits below eight encyclical titles without being told so.
ct <- read.csv(file.path(ME_OUT, "cst_core_terms.csv"), fileEncoding = "UTF-8")
ct$label <- factor(TERM_PLOT[ct$term], levels = TERM_PLOT[ct$term[order(ct$n)]])
ct$kind <- factor(ct$kind, levels = c("document", "marker"),
                  labels = c("Magisterial document", "Doctrinal principle"))
p4 <- ggplot(ct, aes(label, n)) +
  geom_col(aes(fill = kind), width = 0.7, colour = "grey20", linewidth = 0.25) +
  geom_text(aes(label = n), hjust = -0.25, size = 2.6, colour = "grey15") +
  scale_fill_manual(values = c("Magisterial document" = "grey35",
                               "Doctrinal principle" = "grey78")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  coord_flip() +
  labs(x = NULL, y = "Posts in the doctrinal population carrying the term",
       title = "Figure 4. Which doctrinal vocabulary circulates",
       caption = paste0("Source: authors' calculation. All 23 Tier-1 terms detected in the\n",
                        "1 198-post doctrinal population; a post may carry more than one term.\n",
                        "The preferential option for the poor - the tradition's own principle for\n",
                        "the largest contact zone in the corpus - is carried by 29 posts.")) +
  theme_digikat_print() +
  theme(panel.grid.major.x = element_line(colour = "grey88", linewidth = 0.3))
ggsave(file.path(FIGDIR, "rsp_fig4_vocabulary.png"), p4, width = 7.0, height = 5.2, dpi = DPI, bg = "white")

cat("wrote:\n"); print(list.files(FIGDIR, pattern = "^rsp_fig", full.names = FALSE))
cat("\nAll four are greyscale, white-backgrounded, Arial, 300 dpi, with a source line.\n")
