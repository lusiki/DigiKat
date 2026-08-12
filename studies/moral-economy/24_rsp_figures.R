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
# A figure's TITLE AND SOURCE LINE ARE NOT DRAWN INTO THE PNG. Rasterised at 300 dpi in the plot's
# own font they can never match the page they are placed on, they are not selectable or searchable
# in the PDF, and they clip silently when a label runs wider than expected. So each figure registers
# its words here and this script emits them as a markdown fragment, exactly as 26_rsp_tables.R does
# for a table: caption line, image, source note. 27_sync_tables.R installs the fragment into the
# manuscript and 25_paper_checks.R asserts it is still there byte-for-byte, so the words a reader
# sees under a figure cannot drift from the script that drew it.
#
#   Rscript studies/moral-economy/24_rsp_figures.R
suppressPackageStartupMessages({ library(here); library(ggplot2) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_labels.R"))   # DOM/TERM labels shared with the tables
source(here::here("studies/moral-economy/rsp_input.R"))

input_manifest <- rsp_read_input_manifest()
CORPUS_N <- as.integer(input_manifest$database$rows)
DATE_SPAN <- paste0(substr(input_manifest$database$date_min, 1, 4), "–",
                    substr(input_manifest$database$date_max, 1, 4))

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

# Categorical axis labels are set horizontally and wrapped rather than slanted: an angled label is
# harder to read, and Figure 4's longest specification name used to run under the panel.
wrap_labels <- function(width) {
  function(x) vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"), character(1))
}

# ---- figure register ---------------------------------------------------------------------------
# One entry per figure: the caption the manuscript prints, and the source note beneath it. The note
# is stored as one long string and hard-wrapped on the way out, so the fragment matches the width of
# the table fragments and a wording edit never has to be re-wrapped by hand.
SRC_STEM <- paste0("Source: authors' calculation on the official DigiKat corpus of ",
                   rsp_int(CORPUS_N), " Croatian digital media posts, ", DATE_SPAN, ".")
FIG_REGISTER <- list()
register_fig <- function(n, slug, file, title, note) {
  FIG_REGISTER[[as.character(n)]] <<- list(n = n, slug = slug, file = file, title = title, note = note)
  invisible(TRUE)
}

write_fig_fragments <- function() {
  for (f in FIG_REGISTER[order(vapply(FIG_REGISTER, `[[`, numeric(1), "n"))]) {
    note <- gsub("[[:space:]]+", " ", trimws(f$note))
    lines <- c(sprintf("**Figure %d.** %s", f$n, f$title),
               "",
               sprintf("![](output/figures/%s)", f$file),
               "",
               paste0("*", paste(strwrap(note, width = 95), collapse = "\n"), "*"),
               "")
    out <- file.path(FIGDIR, sprintf("fig%d_%s.md", f$n, f$slug))
    con <- file(out, open = "wt", encoding = "UTF-8"); writeLines(lines, con); close(con)
    cat(sprintf("[fragment] %s\n", basename(out)))
  }
}

# The manuscript is English (IX.1), so labels are English. Domain and term names are translated
# once, in rsp_labels.R, so the paper, its tables and its figures cannot drift apart.

## ---- FIGURE 1: detected gradient and denominator-only sensitivity ----------------------------
adj <- read.csv(file.path(ME_OUT, "cst_gradient_adjusted.csv"), fileEncoding = "UTF-8")
a <- adj[adj$code == "ax1_link_genuine", ]
f1 <- rbind(
  data.frame(domain = a$domain, panel = "Detected marker rate", rate = a$raw_rate,
             lo = NA_real_, hi = NA_real_),
  data.frame(domain = a$domain, panel = "Denominator-only sensitivity", rate = a$adj_rate,
             lo = a$adj_lo, hi = a$adj_hi))
det <- read.csv(file.path(ME_OUT, "cst_robustness_detail.csv"), fileEncoding = "UTF-8")
f1$label <- DOM[f1$domain]
ord <- a$domain[order(a$raw_rate)]
f1$label <- factor(f1$label, levels = DOM[ord])
f1$panel <- factor(f1$panel, levels = c("Detected marker rate", "Denominator-only sensitivity"))

p1 <- ggplot(f1, aes(label, rate)) +
  geom_col(aes(fill = panel), width = 0.68, colour = "grey20", linewidth = 0.25) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.25, linewidth = 0.35,
                colour = "grey15", na.rm = TRUE) +
  scale_fill_manual(values = c("Detected marker rate" = "grey70",
                               "Denominator-only sensitivity" = "grey35"), guide = "none") +
  facet_wrap(~ panel, scales = "free_x") +
  coord_flip() +
  labs(x = NULL, y = "Pairs carrying an explicit Tier-1 marker (%)")
p1 <- p1 + theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig1_gradient.png"), p1, width = 6.7, height = 3.6, dpi = DPI, bg = "white")
register_fig(1, "gradient", "rsp_fig1_gradient.png",
  "Explicit teaching markers by economic subject.",
  paste(SRC_STEM,
        "A pair is one post counted on one subject. The left panel is a fixed-corpus detected rate.",
        "The right panel divides by model-coded domain precision, 60 fresh pairs per subject,",
        "assuming every detected numerator pair qualifies; whiskers propagate audit sampling only."))

## ---- FIGURE 2: era composition by domain ------------------------------------------------------
era <- read.csv(file.path(ME_OUT, "cst_core_domain_era.csv"), fileEncoding = "UTF-8")
tot <- aggregate(Freq ~ domain, era, sum)
era$share <- 100 * era$Freq / tot$Freq[match(era$domain, tot$domain)]
keep <- c("green_energy", "macro_aggregates", "poverty_social", "business_comp", "wages_income")
e <- era[era$domain %in% keep & era$era %in% c("classical", "conciliar", "francis"), ]
e$label <- factor(DOM[e$domain], levels = DOM[c("green_energy", "macro_aggregates", "poverty_social",
                                                "business_comp", "wages_income")])
e$era <- factor(e$era, levels = c("classical", "conciliar", "francis"),
                labels = c("Non-conciliar classical line", "Conciliar", "Francis era"))
p2 <- ggplot(e, aes(label, share, fill = era)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.68,
           colour = "grey20", linewidth = 0.25) +
  scale_fill_manual(values = c("grey25", "grey60", "grey88")) +
  scale_x_discrete(labels = wrap_labels(16)) +
  labs(x = NULL, y = "Share of the subject's teaching pairs (%)") +
  theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig2_era.png"), p2, width = 6.7, height = 3.5, dpi = DPI, bg = "white")
register_fig(2, "era", "rsp_fig2_era.png",
  "Adjacent document eras by economic subject.",
  paste("Source: authors' calculation. Era is assigned to the Tier-1 term adjacent to each specific",
        "post-subject pair. Marker-only, Benedict XVI and mixed-era pairs are reported in Table 4."))

## ---- FIGURE 3: the confessional / secular boundary --------------------------------------------
v <- det[det$variant %in% c("confessional_only", "secular_min", "secular_max"), ]
v$panel <- factor(v$variant, levels = c("confessional_only", "secular_min", "secular_max"),
                  labels = c("Proposed confessional", "Proposed secular (minimum)",
                             "Proposed secular (maximum)"))
v$label <- DOM[v$domain]
v$label <- factor(v$label, levels = DOM[ord])
p3 <- ggplot(v, aes(label, rate)) +
  geom_col(width = 0.68, fill = "grey60", colour = "grey20", linewidth = 0.25) +
  facet_wrap(~ panel, nrow = 1) + coord_flip() +
  labs(x = NULL, y = "Pairs carrying an explicit Tier-1 marker (%)") +
  theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig3_boundary.png"), p3, width = 6.9, height = 3.8, dpi = DPI, bg = "white")
register_fig(3, "boundary", "rsp_fig3_boundary.png",
  "Subject profiles under proposed outlet classifications.",
  paste("Source: authors' calculation. Outlet labels are automated proposals, unratified, and used",
        "only as a sensitivity. The secular maximum adds unlabelled and other outlets to the",
        "proposed secular group."))

## ---- FIGURE 4: construct sensitivity to the Tier-1 marker repertoire ---------------------------
# This is the decisive construct check: keep the linked-pair denominators fixed, omit one or more
# ecology-specific Tier-1 markers from the numerator, and compare the three leading subjects.
lex <- read.csv(file.path(ME_OUT, "cst_lexicon_sensitivity.csv"), fileEncoding = "UTF-8")
lex <- lex[lex$specification %in% c("baseline", "leave_out_laudato_si",
                                    "leave_out_ecology_markers") &
             lex$domain %in% c("green_energy", "macro_aggregates", "taxes_fiscal"), ]
lex$spec <- factor(lex$specification,
  levels = c("baseline", "leave_out_laudato_si", "leave_out_ecology_markers"),
  labels = c("All Tier-1 markers", "Without Laudato si'", "Without ecology-specific markers"))
lex$subject <- factor(DOM[lex$domain],
  levels = DOM[c("green_energy", "macro_aggregates", "taxes_fiscal")])
p4 <- ggplot(lex, aes(spec, detected_rate, fill = subject)) +
  geom_col(position = position_dodge(width = 0.78), width = 0.7,
           colour = "grey20", linewidth = 0.25) +
  scale_fill_manual(values = c("grey25", "grey58", "grey82")) +
  scale_x_discrete(labels = wrap_labels(22)) +
  labs(x = NULL, y = "Pairs carrying a remaining Tier-1 marker (%)") +
  theme_digikat_print()
ggsave(file.path(FIGDIR, "rsp_fig4_lexicon_sensitivity.png"), p4,
       width = 6.9, height = 3.6, dpi = DPI, bg = "white")
register_fig(4, "lexicon_sensitivity", "rsp_fig4_lexicon_sensitivity.png",
  "The climate lead depends on ecology-specific markers.",
  paste("Source: authors' calculation. Denominators are fixed. A pair remains when at least one",
        "adjacent non-omitted Tier-1 term survives. Removing Laudato si' reverses the first two",
        "subjects."))

write_fig_fragments()
cat("wrote:\n"); print(list.files(FIGDIR, pattern = "^(rsp_)?fig", full.names = FALSE))
cat("\nAll four are greyscale, white-backgrounded, Arial, 300 dpi. Titles and source notes are\n",
    "typeset on the page from the fragments above, never rasterised into the image.\n", sep = "")
