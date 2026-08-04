#!/usr/bin/env Rscript
# moral-economy — WINNER-TAKE-ALL VIEWER (local, private, read-only).
#
# PAPER_v1 §6.5 reports that winner-take-all assignment calls 55.5% of a religion-filtered corpus
# "economic" and flags the number as not credible. This script makes that claim inspectable: it
# re-derives the WTA assignment from scores_full.rds, draws a stratified sample of the posts it
# labelled economic, and renders them with the decisive diagnostic attached — whether the post
# contains ANY economic keyword for the domain the embedding assigned it to.
#
#   Rscript studies/moral-economy/13_wta_viewer.R [--per-band=8] [--refresh-meta] [--full-chars=20000]
#
# Sampling is stratified by assigned domain x assignment margin (how far the winning domain beat the
# best non-economic decoy), so the page shows the confident assignments and the marginal ones side by
# side rather than only the flattering top of the list.
#
# OUTPUT IS RESTRICTED (row-level text, URLs, outlet identities) -> gitignored output/private/.
# The master is opened READ-ONLY once and cached; pause Dropbox for that first run (CLAUDE.local.md).
suppressPackageStartupMessages({ library(here); library(stringr) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/viewer_lib.R"))
source(here::here("studies/moral-economy/lexicon.R"))

ARGS       <- commandArgs(TRUE)
REFRESH    <- any(grepl("^--refresh-meta$", ARGS))
PER_BAND   <- as.integer(digikat_cli_value(ARGS, "--per-band", "8"))
FULL_CHARS <- as.integer(digikat_cli_value(ARGS, "--full-chars", "20000"))
OUT_HTML   <- file.path(ME_PRIVATE, "wta_viewer.html")
CACHE      <- file.path(ME_PRIVATE, "wta_sample_cache.rds")
MASTER     <- here::here("data/merged_comprehensive.rds")
DECOYS     <- c("liturgy", "devotion", "church_org", "news_generic")

# ---- 1. re-derive the winner-take-all assignment (06_s2_corpus_scoring.R lines 96-101) -----------
S <- readRDS(file.path(ME_SEM, "scores_full.rds"))
dm <- as.matrix(S[, paste0("s_", ME_DOMAINS)])
# ties.method = "first" for determinism. 06 used max.col()'s default ("random"), so a handful of posts
# whose top two domain scores are exactly equal land differently there; the tolerance below absorbs it.
best   <- max.col(dm, ties.method = "first")
bestv  <- dm[cbind(seq_len(nrow(S)), best)]
decoyv <- do.call(pmax, lapply(paste0("s_", DECOYS), function(cc) S[[cc]]))
wta    <- ifelse(bestv > decoyv, ME_DOMAINS[best], NA_character_)
margin <- bestv - decoyv
n_econ <- sum(!is.na(wta))
cat(sprintf("WTA labels %s of %s posts economic (%.1f%%).\n",
            format(n_econ, big.mark = ","), format(nrow(S), big.mark = ","), 100 * n_econ / nrow(S)))

# cross-check against the tracked coverage table so a silently changed rule cannot pass unnoticed
cov <- read.csv(file.path(ME_SEM, "coverage_ranking_v2.csv"), stringsAsFactors = FALSE)
got <- as.integer(table(factor(wta, levels = cov$domain)))
if (sum(got) != sum(cov$wta_n))
  stop("Re-derived WTA total disagrees with coverage_ranking_v2.csv — the rule has drifted.")
if (max(abs(got - cov$wta_n)) > 10L)
  stop("Re-derived per-domain WTA counts differ by more than exact-score ties can explain.")
cat(sprintf("  matches coverage_ranking_v2.csv: total exact, per-domain max deviation %d (score ties).\n",
            max(abs(got - cov$wta_n))))

# ---- 2. stratified sample: assigned domain x margin band ----------------------------------------
# Bands are quantiles of the margin WITHIN each domain: the embedding's most and least confident
# calls, plus the middle, where most of the 394k actually sit.
set.seed(ME_SEED)
BANDS <- list(strong = c(0.90, 1.00), typical = c(0.45, 0.55), weak = c(0.00, 0.10))
pick <- do.call(rbind, lapply(ME_DOMAINS, function(d) {
  i <- which(wta == d); m <- margin[i]
  do.call(rbind, lapply(names(BANDS), function(b) {
    q <- quantile(m, BANDS[[b]], names = FALSE)
    cand <- i[m >= q[1] & m <= q[2]]
    if (!length(cand)) return(NULL)
    data.frame(row = sample(cand, min(PER_BAND, length(cand))), domain = d, band = b,
               stringsAsFactors = FALSE)
  }))
}))
pick$rid    <- S$chunk_id[pick$row]
pick$score  <- round(bestv[pick$row], 4)
pick$decoy  <- round(decoyv[pick$row], 4)
pick$margin <- round(margin[pick$row], 4)
pick$platform <- S$platform[pick$row]
pick$stream   <- S$data_source[pick$row]
pick$date     <- as.character(S$date[pick$row])
# runner-up domain — shows how little separates the winner from the next label
pick$second <- vapply(seq_len(nrow(pick)), function(k) {
  v <- dm[pick$row[k], ]; ME_DOMAINS[order(v, decreasing = TRUE)[2]] }, "")
cat(sprintf("Sampled %d posts (%d domains x %d bands x up to %d).\n",
            nrow(pick), length(ME_DOMAINS), length(BANDS), PER_BAND))

# ---- 3. title / URL / text + the keyword diagnostic (master read once, cached) --------------------
if (REFRESH || !file.exists(CACHE)) {
  if (!file.exists(MASTER)) stop("Master not on this machine; cannot build the sample cache.")
  fi0 <- file.info(MASTER)
  cat("Reading master READ-ONLY (pause Dropbox) ...\n"); t0 <- Sys.time()
  corpus <- readRDS(MASTER)
  if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)
  cat(sprintf("  %s rows in %.1f min\n", format(nrow(corpus), big.mark = ","),
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  gc0 <- function(nm) if (nm %in% names(corpus)) corpus[[nm]] else rep(NA_character_, nrow(corpus))
  i <- pick$rid
  if (max(i) > nrow(corpus)) stop("rid exceeds master row count — rid is not a master row index here.")
  txt <- corpus$FULL_TEXT[i]

  # THE DIAGNOSTIC: does the post contain any economic keyword for its ASSIGNED domain, and for any
  # domain at all? Matched on the original text with ignore_case, exactly as 01_stageA_tag_linkage.R.
  IC <- function(p) stringr::regex(p, ignore_case = TRUE)
  kw_assigned <- vapply(seq_along(i), function(k)
    isTRUE(str_detect(txt[k], IC(ME_ECON[[pick$domain[k]]]))), logical(1))
  kw_any <- Reduce(`|`, lapply(ME_ECON, function(rx) str_detect(txt, IC(rx))))

  meta <- data.frame(rid = i, TITLE = gc0("TITLE")[i], URL = gc0("URL")[i], FROM = gc0("FROM")[i],
                     full_text = substr(txt, 1, FULL_CHARS), full_len = nchar(txt),
                     kw_assigned = kw_assigned, kw_any = kw_any, stringsAsFactors = FALSE)
  rm(corpus); gc(verbose = FALSE)

  fi1 <- file.info(MASTER)
  if (!identical(fi0$size, fi1$size) || !identical(fi0$mtime, fi1$mtime))
    stop("Master size/mtime changed during a read-only pass — investigate before trusting anything.")
  saveRDS(meta, CACHE); cat("  cached ->", CACHE, "\n")
} else {
  cat("Using cached sample meta (", CACHE, "); --refresh-meta to rebuild.\n")
}
meta <- readRDS(CACHE)
if (!identical(meta$rid, pick$rid))
  stop("Cache was built for a different sample. Re-run with --refresh-meta.")

pct <- function(x) sprintf("%.1f%%", 100 * mean(x))
cat(sprintf("\n  no economic keyword for the ASSIGNED domain: %d of %d (%s)\n",
            sum(!meta$kw_assigned), nrow(meta), pct(!meta$kw_assigned)))
cat(sprintf("  no economic keyword for ANY of the 11 domains: %d (%s)\n",
            sum(!meta$kw_any), pct(!meta$kw_any)))
for (b in names(BANDS)) {
  j <- pick$band == b
  cat(sprintf("    %-8s band: %s lack the assigned-domain keyword\n", b, pct(!meta$kw_assigned[j])))
}

# ---- 4. render -----------------------------------------------------------------------------------
card <- function(k) {
  url   <- vw_nz(meta$URL[k], "")
  title <- vw_nz(meta$TITLE[k], "(bez naslova)")
  head  <- if (nzchar(url)) paste0("<a href=\"", vw_esc(url), "\" target=\"_blank\" rel=\"noreferrer\">",
                                   vw_esc(title), "</a>")
           else paste0(vw_esc(title), " <span class=\"nolink\">(no URL)</span>")
  ftxt  <- vw_nz(meta$full_text[k], "")
  kw    <- if (meta$kw_assigned[k]) "has keyword" else if (meta$kw_any[k]) "other domain's keyword only"
           else "NO economic keyword"
  kwcls <- if (meta$kw_assigned[k]) "good" else "warn"
  paste0(
    "<article class=\"c\" data-domain=\"", vw_esc(pick$domain[k]), "\" data-band=\"",
    vw_esc(pick$band[k]), "\" data-kw=\"", if (meta$kw_assigned[k]) "yes" else "no",
    "\" data-kwany=\"", if (meta$kw_any[k]) "yes" else "no",
    "\" data-platform=\"", vw_esc(vw_nz(pick$platform[k])), "\">",
    "<div class=\"bar\"><span class=\"n\">#", k, "</span>",
    "<span class=\"b dom\">", vw_esc(pick$domain[k]), "</span>",
    "<span class=\"b\">", vw_esc(pick$band[k]), " margin</span>",
    "<span class=\"b ", kwcls, "\">", kw, "</span>",
    "<span class=\"rid\">rid ", pick$rid[k], "</span></div>",
    "<h2>", head, "</h2>",
    "<div class=\"meta\">", vw_esc(vw_nz(meta$FROM[k])), " · ", vw_esc(vw_nz(pick$date[k])),
    " · ", vw_esc(vw_nz(pick$platform[k])), " · ", vw_esc(vw_nz(pick$stream[k])), "</div>",
    "<div class=\"scores\">assigned <b>", vw_esc(pick$domain[k]), "</b> at ", pick$score[k],
    " · best non-economic decoy ", pick$decoy[k], " · margin <b>", pick$margin[k], "</b>",
    " · runner-up domain ", vw_esc(pick$second[k]), "</div>",
    "<div class=\"exc\"><b>article text</b>", vw_esc(substr(ftxt, 1, 900)),
    if (nchar(ftxt) > 900) " …" else "", "</div>",
    if (nchar(ftxt) > 900) paste0(
      "<details><summary>Full text (", format(vw_nz(meta$full_len[k], 0)), " chars)</summary>",
      "<div class=\"full\">", vw_esc(ftxt), "</div></details>") else "",
    "</article>")
}
cards <- paste0(vapply(seq_len(nrow(pick)), card, ""), collapse = "\n")

lab <- function(x, text, tone = NULL) {
  attr(x, "label") <- text; if (!is.null(tone)) attr(x, "tone") <- tone; x
}
presets <- list(
  all    = lab(character(0),        paste("All", nrow(pick))),
  nokw   = lab(c(kw = "no"),        paste("No keyword for assigned domain", sum(!meta$kw_assigned)), "bad"),
  nokwa  = lab(c(kwany = "no"),     paste("No economic keyword at all", sum(!meta$kw_any)), "bad"),
  strong = lab(c(band = "strong"),  paste("Strong margin", sum(pick$band == "strong"))),
  weak   = lab(c(band = "weak"),    paste("Weak margin", sum(pick$band == "weak"))),
  okkw   = lab(c(kw = "yes"),       paste("Keyword confirms", sum(meta$kw_assigned)), "hot"))

tools <- paste0(
  vw_select("domain",   "domain",   pick$domain),
  vw_select("band",     "margin",   pick$band),
  vw_select("platform", "platform", vw_nz(pick$platform)),
  "<select data-f=\"kw\"><option value=\"\">assigned-domain keyword: all</option>",
  "<option value=\"yes\">present</option><option value=\"no\">absent</option></select>")

vw_page(OUT_HTML, "moral-economy — what winner-take-all called \"economic\"",
        paste0("WTA labels ", format(n_econ, big.mark = ","), " of ",
               format(nrow(S), big.mark = ","), " posts economic (",
               sprintf("%.1f%%", 100 * n_econ / nrow(S)), ") — PAPER_v1 §6.5 calls this not credible. ",
               "This is a stratified sample of ", nrow(pick), ", ",
               sprintf("%.0f%%", 100 * mean(!meta$kw_assigned)),
               " of which contain no economic keyword for the domain they were assigned. ",
               "Generated ", format(Sys.time(), "%Y-%m-%d %H:%M")),
        presets, tools, cards,
        keys = c("domain", "band", "kw", "kwany", "platform"))
