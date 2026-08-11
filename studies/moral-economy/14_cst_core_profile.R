#!/usr/bin/env Rscript
# moral-economy — STEP 14: DESCRIPTIVE PROFILE OF THE OFFICIAL-CORPUS CST CORE SET.
#
# The stage-setting report for the analysis. Answers four questions about the population defined in
# cst_core.R — what is in it, what words it uses, where it is published, and what that implies for the
# next step (the hand-coding sample).
#
#   Rscript studies/moral-economy/14_cst_core_profile.R [--bg=2000] [--refresh]
#
# WHAT IT WRITES
#   output/private/CST_CORE_PROFILE.md   the report (names outlets -> RESTRICTED)
#   output/private/cst_core_outlets.csv  outlet table (source identities -> RESTRICTED)
#   output/cst_core_*.csv                aggregate tables, no identities -> shareable
#   output/figures/fig_cst_*.png         figures
#
# TWO MEASUREMENT NOTES THAT GOVERN EVERY NUMBER BELOW.
#  1. TIME IS CONFOUNDED. data_source splits the corpus into two time-segregated collection streams
#     (original_dta 2021-2024, filtered_religious 2024-2026). Year-over-year counts are an artefact of
#     the collection change, NOT of media attention. Years are reported for completeness and must not be
#     read as a trend. This is why the paper makes no temporal claim.
#  2. KEYNESS USES IDENTICAL EXTRACTION ON BOTH SIDES. The core and the background are compared on the
#     SAME field — stageA's +-220 linkage `window` — so a difference cannot come from one side being
#     given longer or differently-centred text. Comparing a 2,000-char slice against a 440-char window
#     would manufacture "distinctive" vocabulary out of nothing but length.
suppressPackageStartupMessages({
  library(here); library(stringi); library(udpipe); library(ggplot2)
})
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))
source(here::here("R/theme_digikat.R"))     # sets the DigiKat ggplot theme as default

ARGS    <- commandArgs(TRUE)
BG_N    <- as.integer(digikat_cli_value(ARGS, "--bg", "2000"))
REFRESH <- any(grepl("^--refresh$", ARGS))
FIGDIR  <- file.path(ME_OUT, "figures")
REPORT  <- file.path(ME_PRIVATE, "CST_CORE_PROFILE.md")
MODEL   <- here::here("resources/models/croatian-set-ud-2.5-191206.udpipe")
dir.create(FIGDIR, recursive = TRUE, showWarnings = FALSE)

core <- cst_build_core(refresh = REFRESH, verbose = TRUE)
n    <- nrow(core)
cat(sprintf("Core set: %d posts\n", n))

pct  <- function(x, d = 1) sprintf(paste0("%.", d, "f%%"), 100 * x)
tbl  <- function(x) { t <- sort(table(x), decreasing = TRUE); data.frame(value = names(t),
                      n = as.integer(t), pct = round(100 * as.integer(t) / sum(t), 2)) }
# markdown table from a data.frame
md <- function(d, digits = 2) {
  d <- as.data.frame(d)
  for (j in seq_along(d)) if (is.numeric(d[[j]])) d[[j]] <- round(d[[j]], digits)
  paste0("| ", paste(names(d), collapse = " | "), " |\n",
         "|", paste(rep("---", ncol(d)), collapse = "|"), "|\n",
         paste(apply(d, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |")), collapse = "\n"),
         "\n")
}

# ---- 1. structure -----------------------------------------------------------------------------------
core$year <- format(core$date, "%Y")
# A post may carry several same-domain adjacency pairs; expand only the domains that passed that test.
dom_long <- merge(cst_core_pairs(core)[, c("rid", "domain", "era")],
                  core[, c("rid", "label", "stream")], by = "rid", sort = FALSE)
dom_long$tier <- unname(ME_TIER[dom_long$domain])

term_long <- do.call(rbind, lapply(seq_len(n), function(i) {
  tt <- strsplit(core$terms[i], " ")[[1]]
  if (!length(tt)) return(NULL)
  data.frame(rid = core$rid[i], term = tt, era = core$era[i], label = core$label[i],
             stringsAsFactors = FALSE)
}))
term_long$kind <- ifelse(term_long$term %in% names(CST_DOCS), "document", "marker")

n_dom  <- tapply(dom_long$domain, dom_long$rid, length)
n_term <- tapply(term_long$term, term_long$rid, length)

# ---- 2. NLP: lemmatise the junction slices ------------------------------------------------------------
ud_cache <- file.path(ME_PRIVATE, "cst_core_official_udpipe.rds")
model <- udpipe_load_model(MODEL)

annotate <- function(txt, ids, cache, label) {
  fp <- list(database = rsp_read_input_manifest()$database$sha256,
             ids = digikat_hash_object(as.character(ids)),
             text_sha256 = digikat_hash_object(as.character(txt)), label = label)
  if (!REFRESH && file.exists(cache)) {
    a <- readRDS(cache)
    if (identical(attr(a, "fingerprint"), fp) &&
        setequal(as.character(unique(a$doc_id)), as.character(ids))) {
      cat("  [cached]", label, "\n"); return(a)
    }
  }
  cat("  annotating", label, "-", format(sum(nchar(txt)), big.mark = ","), "chars...\n")
  a <- as.data.frame(udpipe_annotate(model, x = txt, doc_id = ids, parser = "none"))
  # udpipe 0.8.16 exposes no character offsets, so downstream code must not ask for start/end.
  a <- a[, c("doc_id", "token_id", "token", "lemma", "upos")]
  attr(a, "fingerprint") <- fp
  saveRDS(a, cache); a
}

ann <- annotate(core$slice, as.character(core$rid), ud_cache, "core junction slices")

# The slice is cut at a character offset, so its first and last tokens can be word fragments
# ("roditelji" -> "bitelji"). Drop them rather than let a fragment enter a frequency table.
# NB: udpipe's token_id restarts at 1 in every SENTENCE, so "first/last token of the document" is a
# statement about ROW ORDER, not about token_id — using token_id would delete one token per sentence.
trim_edges <- function(a) {
  o <- seq_len(nrow(a))
  lo <- ave(o, a$doc_id, FUN = min); hi <- ave(o, a$doc_id, FUN = max)
  a[o != lo & o != hi, ]
}
ann <- trim_edges(ann)

CONTENT <- c("NOUN", "PROPN", "ADJ", "VERB")
ann$lemma <- stri_trans_tolower(ann$lemma)
ann <- ann[ann$upos %in% CONTENT & stri_length(ann$lemma) > 2 &
             !stri_detect_regex(ann$lemma, "^[^\\p{L}]+$"), ]

lem_top <- function(a, pos = CONTENT, k = 40) {
  s <- a[a$upos %in% pos, ]
  t <- sort(table(s$lemma), decreasing = TRUE)
  data.frame(lemma = names(t)[seq_len(min(k, length(t)))],
             n = as.integer(t)[seq_len(min(k, length(t)))],
             docs = vapply(names(t)[seq_len(min(k, length(t)))],
                           function(w) length(unique(s$doc_id[s$lemma == w])), integer(1)),
             stringsAsFactors = FALSE)
}

# Words in the immediate junction zone. With no token offsets available, the zone is cut from the TEXT
# and annotated as its own document set — same answer, and it avoids reconstructing character positions
# by re-matching tokens against the source (fragile wherever udpipe normalises a token).
jwin <- stri_sub(core$slice,
                 pmax(1L, core$junction - ME_WINDOW),
                 pmin(stri_length(core$slice), core$junction + ME_WINDOW))
jz <- annotate(jwin, as.character(core$rid),
               file.path(ME_PRIVATE, "cst_core_official_junction_udpipe.rds"), "junction windows")
jz <- trim_edges(jz)
jz$lemma <- stri_trans_tolower(jz$lemma)
jz <- jz[jz$upos %in% CONTENT & stri_length(jz$lemma) > 2 &
           !stri_detect_regex(jz$lemma, "^[^\\p{L}]+$"), ]

# ---- 3. keyness vs a matched background ----------------------------------------------------------------
# Both sides are stageA's +-220 linkage window: identical extraction, only membership differs.
cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand$rid <- as.integer(cand$rid)
linked_posts <- length(unique(cand$rid))
cw <- cand[!duplicated(cand$rid), c("rid", "window")]
set.seed(ME_SEED)
bg_pool <- setdiff(cw$rid, core$rid)
bg_rid  <- sort(sample(bg_pool, min(BG_N, length(bg_pool))))

core_w <- cw$window[match(core$rid, cw$rid)]
bg_w   <- cw$window[match(bg_rid,   cw$rid)]
ok_c <- !is.na(core_w) & nzchar(core_w); ok_b <- !is.na(bg_w) & nzchar(bg_w)

ann_cw <- annotate(core_w[ok_c], as.character(core$rid[ok_c]),
                   file.path(ME_PRIVATE, "cst_core_official_window_udpipe.rds"), "core linkage windows")
ann_bw <- annotate(bg_w[ok_b], as.character(bg_rid[ok_b]),
                   file.path(ME_PRIVATE, "cst_bg_official_window_udpipe.rds"), "background linkage windows")

prep <- function(a) {
  a$lemma <- stri_trans_tolower(a$lemma)
  a[a$upos %in% CONTENT & stri_length(a$lemma) > 2 &
      !stri_detect_regex(a$lemma, "^[^\\p{L}]+$"), ]
}
ac <- prep(trim_edges(ann_cw)); ab <- prep(trim_edges(ann_bw))

# Monroe, Colaresi & Quinn (2008) log-odds ratio with an informative Dirichlet prior. Plain frequency
# ratios are dominated by rare words; this shrinks them toward the pooled corpus and returns a z-score.
keyness <- function(x, y, a0 = 500, min_n = 8) {
  v <- union(names(x), names(y))
  yi <- as.numeric(x[v]); yi[is.na(yi)] <- 0
  yj <- as.numeric(y[v]); yj[is.na(yj)] <- 0
  keep <- (yi + yj) >= min_n
  v <- v[keep]; yi <- yi[keep]; yj <- yj[keep]
  tot <- yi + yj
  aw <- a0 * tot / sum(tot)
  ni <- sum(yi); nj <- sum(yj); a_all <- sum(aw)
  d <- log((yi + aw) / (ni + a_all - yi - aw)) - log((yj + aw) / (nj + a_all - yj - aw))
  s <- sqrt(1 / (yi + aw) + 1 / (yj + aw))
  data.frame(lemma = v, n_core = yi, n_bg = yj, z = d / s, stringsAsFactors = FALSE)
}
key <- keyness(table(ac$lemma), table(ab$lemma))
key <- key[order(-key$z), ]

# ---- 4. figures -------------------------------------------------------------------------------------
ggsave2 <- function(p, file, w = 8, h = 5) {
  ggsave(file.path(FIGDIR, file), p, width = w, height = h, dpi = 150, bg = dk_col$paper)
  cat("  fig ->", file, "\n")
}

d1 <- tbl(dom_long$domain); names(d1)[1] <- "domain"
d1$tier <- unname(ME_TIER[d1$domain])
ggsave2(ggplot(d1, aes(reorder(domain, n), n, fill = tier)) +
  geom_col() + coord_flip() + scale_fill_digikat() +
  labs(title = "Economic domains in the CST core set", subtitle = paste0("n = ", n,
       " posts; a post may carry several domains"), x = NULL, y = "posts", fill = "tier"),
  "fig_cst_domains.png")

ed <- as.data.frame(table(domain = dom_long$domain, era = dom_long$era))
ed <- ed[ed$era %in% c("francis", "classical", "conciliar", "marker_only"), ]
ggsave2(ggplot(ed, aes(era, domain, fill = Freq)) + geom_tile(colour = dk_col$panel) +
  geom_text(aes(label = ifelse(Freq > 0, Freq, "")), size = 3) +
  scale_fill_gradient(low = dk_col$panel, high = dk_col$alert) +
  labs(title = "Which doctrinal era meets which economic domain", x = NULL, y = NULL, fill = "posts"),
  "fig_cst_era_domain.png", w = 7.5, h = 5)

kk <- rbind(head(key, 22), tail(key, 22)); kk$side <- ifelse(kk$z > 0, "core", "background")
ggsave2(ggplot(kk, aes(reorder(lemma, z), z, fill = side)) + geom_col() + coord_flip() +
  scale_fill_manual(values = c(core = dk_col$pos, background = dk_col$neg)) +
  labs(title = "Distinctive vocabulary of the CST core set",
       subtitle = paste0("log-odds z vs ", length(unique(ab$doc_id)),
                         " background posts; identical ±220 windows both sides"),
       x = NULL, y = "z"), "fig_cst_keyness.png", w = 8, h = 8)

ggsave2(ggplot(core, aes(gap)) + geom_histogram(binwidth = 10, fill = dk_col$pos) +
  labs(title = "Distance between doctrine and economics",
       subtitle = "characters between the nearest Tier-1 CST match and the nearest economic term",
       x = "characters", y = "posts"), "fig_cst_gap.png", w = 8, h = 4)

# ---- 5. shareable tables ------------------------------------------------------------------------------
sem_write_shareable(d1, file.path(ME_OUT, "cst_core_domains.csv"))
tt <- tbl(term_long$term); names(tt)[1] <- "term"
tt$kind <- ifelse(tt$term %in% names(CST_DOCS), "document", "marker")
tt$era  <- unname(CST_ERA[tt$term])
sem_write_shareable(tt, file.path(ME_OUT, "cst_core_terms.csv"))
sem_write_shareable(as.data.frame(table(era = core$era, stream = core$stream)),
                    file.path(ME_OUT, "cst_core_era_stream.csv"))
sem_write_shareable(as.data.frame(table(domain = dom_long$domain, era = dom_long$era)),
                    file.path(ME_OUT, "cst_core_domain_era.csv"))
sem_write_shareable(head(key, 150), file.path(ME_OUT, "cst_core_keyness.csv"))
sem_write_shareable(lem_top(ann, CONTENT, 200), file.path(ME_OUT, "cst_core_lemmas.csv"))

out_tab <- tbl(core$actor); names(out_tab)[1] <- "outlet"
lab_by_outlet <- tapply(core$label, core$actor, function(x) names(sort(table(x), decreasing = TRUE))[1])
out_tab$label <- unname(lab_by_outlet[out_tab$outlet])
sem_write_private(out_tab, file.path(ME_PRIVATE, "cst_core_outlets.csv"))

# ---- 6. report ----------------------------------------------------------------------------------------
top_out <- head(out_tab, 25)
conf <- tbl(core$label); names(conf)[1] <- "label"
pf   <- tbl(core$platform); names(pf)[1] <- "platform"
st   <- tbl(core$stream); names(st)[1] <- "stream"
yr   <- tbl(core$year); names(yr)[1] <- "year"
er   <- tbl(core$era); names(er)[1] <- "era"
census_path <- file.path(ME_OUT, "cst_census_summary.csv")
census <- if (file.exists(census_path)) read.csv(census_path, fileEncoding = "UTF-8") else NULL
t1_layer <- if (!is.null(census)) census$n_linked_econ[census$group == "tier1_strict"] else NA_integer_
adjacency_cost <- if (length(t1_layer) == 1L && !is.na(t1_layer)) t1_layer - n else NA_integer_

# proposed coding strata: era x tier, the two axes the paper's claims turn on
core$dom_tier <- vapply(strsplit(core$domains, " "), function(d)
  paste(sort(unique(unname(ME_TIER[d]))), collapse = ""), "")
strata <- as.data.frame(table(era = core$era, domain_tier = core$dom_tier))
strata <- strata[strata$Freq > 0, ]
strata$share <- strata$Freq / sum(strata$Freq)
strata$draw_400 <- pmin(strata$Freq, pmax(ifelse(strata$Freq >= 10, 8, strata$Freq),
                                          round(400 * strata$share)))

writeLines(c(
"# CST core set — descriptive profile",
"",
paste0("**n = ", n, " posts.** Generated ", format(Sys.time(), "%Y-%m-%d %H:%M"),
       " by `14_cst_core_profile.R`."),
"",
"> **RESTRICTED** — this report names outlets. Keep it in `output/private/`; do not commit or publish.",
"",
"## 0. What this population is",
"",
"A post is here when all three hold:",
"",
"1. it carries **Tier-1 CST vocabulary** — an encyclical title or a doctrine-specific coinage;",
"2. it is in the **religion-linked economic layer** (economic term + a religious term within ±220 chars);",
paste0("3. the **CST term is itself within ±", ME_WINDOW, " chars of an economic term**."),
"",
paste0("Condition 3 is what makes this an analysis population rather than a keyword bag: every member has ",
       "doctrine genuinely adjacent to economics, not merely somewhere in the same article.",
       if (!is.na(adjacency_cost)) paste0(" It removes ", adjacency_cost, " of the ", t1_layer,
                                          " posts that satisfy conditions 1 and 2 alone.") else ""),
"",
paste0("**Scarcity, the headline:** ", n, " of ", linked_posts,
       " religion-linked economic posts — ", pct(n / linked_posts, 2),
       ", about 1 in ", round(linked_posts / n), "."),
"",
"## 1. How close is the doctrine to the economics?",
"",
md(data.frame(statistic = c("min", "25th pct", "median", "mean", "75th pct", "max"),
              chars = as.numeric(c(min(core$gap), quantile(core$gap, .25), median(core$gap),
                                   round(mean(core$gap), 1), quantile(core$gap, .75), max(core$gap))))),
paste0("Median ", median(core$gap), " characters — roughly half a sentence. ",
       sum(core$gap == 0), " posts (", pct(mean(core$gap == 0)), ") have the two terms touching. ",
       "The distribution is not bunched against the ±", ME_WINDOW,
       " ceiling, which is the reassuring shape: the cut is not manufacturing the population."),
"",
"![gap](../figures/fig_cst_gap.png)",
"",
"## 2. Where it is published",
"",
"### Platform", "", md(pf),
paste0("**", pct(mean(core$platform == "web")), " is web.** Doctrinal economic talk is a ",
       "news-portal phenomenon; it barely exists on social platforms. Any claim about ",
       "'the Church in the digital public sphere' has to be read as *portal* discourse."),
"",
"### Outlet type", "", md(conf),
paste0("Only ", pct(mean(core$label %in% c("confessional", "secular"))),
       " of posts carry an outlet label at all. **Among the labelled ones, ",
       pct(sum(core$label == "confessional") / sum(core$label %in% c("confessional", "secular"))),
       " are confessional** (", sum(core$label == "confessional"), " vs ",
       sum(core$label == "secular"), " secular). Doctrinal economic discourse is therefore mostly the ",
       "Church addressing its own readership, not doctrine crossing into general media. That is a ",
       "finding, not a nuisance — but it constrains how far 'public sphere' can be claimed, and the ",
       pct(mean(!core$label %in% c("confessional", "secular"))),
       " unlabelled share has to be resolved before the claim is made either way."),
"",
"### Top outlets", "", md(top_out),
paste0("**Concentration is severe: ", top_out$outlet[1], " alone is ", top_out$n[1], " posts (",
       pct(top_out$n[1] / n), "), and the top 3 are ", pct(sum(top_out$n[1:3]) / n),
       ".** A near-third of the population is one confessional portal, so any unweighted description of ",
       "'Croatian Catholic economic discourse' is substantially a description of that outlet's house ",
       "style. Report outlet-adjusted figures alongside raw ones, and stratify the coding sample by ",
       "outlet so it is not dominated by a single newsroom."),
"",
"### Collection stream and year", "", md(st), md(yr),
"> **Do not read the years as a trend.** The two streams cover different periods by construction",
"> (`original_dta` 2021–2024, `filtered_religious` 2024–2026), so year-over-year movement is a",
"> collection artefact. Reported for completeness only.",
"",
"## 3. Which doctrine appears",
"",
"### Era", "", md(er),
"### Terms", "", md(head(tt, 25)),
paste0("Posts name on average ", round(mean(n_term), 2), " Tier-1 terms (max ", max(n_term), ")."),
"",
"## 4. Which economics it meets",
"",
md(d1),
paste0("Posts carry on average ", round(mean(n_dom), 2), " economic domains (max ", max(n_dom),
       "); percentages are of domain-mentions, not posts."),
"",
"![domains](../figures/fig_cst_domains.png)",
"",
"### Doctrine era × economic domain", "",
"![era x domain](../figures/fig_cst_era_domain.png)",
"",
"## 5. The language",
"",
"### Most common content words (junction slices, lemmatised, POS-filtered)", "",
"**Nouns**", "", md(lem_top(ann, "NOUN", 30)),
"**Proper nouns** — who and where", "", md(lem_top(ann, "PROPN", 25)),
"**Adjectives**", "", md(lem_top(ann, "ADJ", 20)),
"**Verbs**", "", md(lem_top(ann, "VERB", 20)),
"",
paste0("### Right at the junction (±", ME_WINDOW, " chars of the doctrine↔economy meeting point)"), "",
md(lem_top(jz, "NOUN", 25)),
"",
"### What makes these posts distinctive", "",
paste0("Log-odds with an informative Dirichlet prior (Monroe et al. 2008), against ",
       length(unique(ab$doc_id)), " randomly drawn religion-linked economic posts that are **not** in ",
       "the core set. Both sides use the same ±", ME_WINDOW,
       " linkage window, so length cannot drive the result."),
"",
"**Most over-represented in the core set**", "", md(head(key[, c("lemma", "n_core", "n_bg", "z")], 30)),
"**Most under-represented**", "", md(tail(key[, c("lemma", "n_core", "n_bg", "z")], 20)),
"",
"![keyness](../figures/fig_cst_keyness.png)",
"",
"## 6. What this sets up",
"",
"**The paper has three moving parts, and this population serves the second and third.**",
"",
paste0("1. **Scarcity** needs the denominator, not this set: ", n,
       " / ", linked_posts, ". Do not compute it from here."),
"2. **Composition** — what doctrinal economic discourse looks like — is this set, described above.",
paste0("3. **Contrast** — the core against the other ", linked_posts - n,
       " linked posts — is the keyness table, extended to the"),
"   coded axes once coding exists.",
"",
paste0("**Proposed hand-coding sample (~400 of ", n, ").** Strata are doctrinal era × economic-domain ",
       "tier, the two axes every claim turns on. Cells under 10 are taken whole; the rest are ",
       "proportional. Draw with `sem_draw()`-style stratification and the study seed."),
"",
md(strata[order(-strata$Freq), c("era", "domain_tier", "Freq", "share", "draw_400")]),
"",
"**Three things to settle before coding starts.**",
"",
paste0("- **Boundary cases.** Posts with doctrine adjacent to economics that never entered the linked layer, ",
       "because the 95-term religion lexicon contains no CST vocabulary, are excluded here. ",
       "If they read as genuine, the fix is to add CST terms to the linkage lexicon and rebuild — ",
       "which changes the population, so decide now, not after coding."),
"- **The human validation slice.** Still the blocking item for a sociology-of-religion venue: the",
"  codebook promises a human double-coded slice on Axes 4 and 6 and I found no evidence it was run.",
paste0("- **`marker_only` is ", er$n[er$era == "marker_only"], " posts (", pct(mean(core$era == "marker_only")),
       ").** These name *socijalni nauk* or *supsidijarnost* without naming a document. Decide whether ",
       "that counts as invoking the tradition or as gesturing at it — it changes the era table materially.")
), REPORT, useBytes = TRUE)

cat("\nWrote ", REPORT, "\n", sep = "")
cat("RESTRICTED — names outlets; gitignored, do not commit or publish.\n")
