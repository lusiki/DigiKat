#!/usr/bin/env Rscript
# moral-economy — CST CENSUS VIEWER (local, private, read-only).
#
# Renders every post the CST census matched as ONE filterable HTML page, so the census can be checked by
# eye rather than trusted. Three vocabularies are highlighted in each card:
#
#   ORANGE = CST doctrine  (cst_lexicon.R)   — the encyclical / principle that made this a census hit
#   BLUE   = economy       (lexicon.R ME_ECON) — the economic word that put the post in the econ layer
#   GREEN  = religion      (lexicon.R, tightened 95-term) — the religious word that linked the two
#
#   Rscript studies/moral-economy/16_cst_viewer.R [--tier2=400] [--full-chars=3000]
#
# WHY IT EXISTS. The census claim is a PRECISION claim: 2.6% of religion-linked economic posts invoke
# doctrine. A regex census can only be believed if someone has looked at what it caught.
#
# THE ADJACENCY QUESTION. Stage A required religion within +-220 chars of the economic term, but the
# census only required the CST term to appear ANYWHERE in the post. So a long article could discuss
# inflation early and cite Laudato si' in an unrelated closing paragraph, and still count. This page
# therefore measures, per post, the CHARACTER GAP between the nearest CST match and the nearest economic
# match, and exposes it as a badge, a filter and a preset. The "CST within +-220" preset IS the tightened
# population — you can read its size off the chip before deciding whether to adopt the stricter rule.
#
# OUTPUT IS RESTRICTED. It carries row-level text, URLs and outlet identities, so it is written to
# gitignored output/private/ and must never be committed, published, or rendered into docs/.
# Reads only data/semantic/corpus_prepared.rds and stageA_candidates.rds — the master is never opened.
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_lexicon.R"))
source(here::here("studies/moral-economy/lexicon.R"))      # ME_ECON, ME_WINDOW, religion regex
source(here::here("studies/moral-economy/viewer_lib.R"))

ARGS       <- commandArgs(TRUE)
TIER2_N    <- as.integer(digikat_cli_value(ARGS, "--tier2", "400"))
FULL_CHARS <- as.integer(digikat_cli_value(ARGS, "--full-chars", "3000"))
PAD        <- 320L     # excerpt padding when only one vocabulary is present
PAIR_PAD   <- 160L     # padding either side of a CST<->economy pair shown together
PAIR_MAX   <- 1400L    # beyond this gap, showing both in one excerpt is not useful
SPAN_CAP   <- 250L     # max highlight spans rendered per text (pathological-length guard)
OUT_HTML   <- file.path(ME_PRIVATE, "cst_viewer.html")
CHUNK      <- 50000L

# ---- 1. scan the corpus with the census lexicon ---------------------------------------------------
cat("Reading corpus...\n")
corpus <- readRDS(here::here("data/semantic/corpus_prepared.rds"))
N <- nrow(corpus)
cat(sprintf("  %s rows\n", digikat_format_integer(N)))

hits <- matrix(FALSE, N, length(CST_TERMS), dimnames = list(NULL, names(CST_TERMS)))
starts <- seq(1L, N, by = CHUNK)
cat(sprintf("Scanning %d chunks...\n", length(starts)))
for (k in seq_along(starts)) {
  a <- starts[k]; b <- min(a + CHUNK - 1L, N)
  hits[a:b, ] <- cst_detect(stri_trans_tolower(corpus$text[a:b]))
  if (k %% 5 == 0 || k == length(starts)) cat(sprintf("  %d/%d\n", k, length(starts)))
}

t1_cols <- names(CST_TERMS)[CST_TIER %in% c("1_document", "1_marker")]
t2_cols <- names(CST_TERMS)[CST_TIER == "2_ambiguous"]
is_t1 <- rowSums(hits[, t1_cols, drop = FALSE]) > 0
is_t2 <- rowSums(hits[, t2_cols, drop = FALSE]) > 0

# Every Tier-1 hit is shown. Tier 2 is 25k+ and mostly secular noise by construction, so it is SAMPLED —
# enough to judge the false-positive rate, not enough to drown the page. The cap is stated on the page
# itself, because a silent cap would read as "this is all of them".
set.seed(ME_SEED)
t2_only <- which(is_t2 & !is_t1)
t2_show <- if (length(t2_only) > TIER2_N) sort(sample(t2_only, TIER2_N)) else t2_only
idx <- sort(c(which(is_t1), t2_show))
cat(sprintf("Cards: %s Tier-1 + %s of %s Tier-2-only (sampled)\n",
            digikat_format_integer(sum(is_t1)), digikat_format_integer(length(t2_show)),
            digikat_format_integer(length(t2_only))))

sel_text <- corpus$text[idx]
sel_low  <- stri_trans_tolower(sel_text)
M <- length(idx)

# ---- 2. linked-economic layer + domains ------------------------------------------------------------
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
cand$rid <- as.integer(cand$rid)
dom_by_rid <- tapply(cand$domain, cand$rid, function(d) paste(sort(unique(d)), collapse = " "))
rid_sel <- as.integer(sub("^dk_", "", corpus$doc_id[idx]))
doms    <- unname(dom_by_rid[as.character(rid_sel)])
in_econ <- !is.na(doms)
doms[!in_econ] <- ""
cat(sprintf("  %s of %s cards are in the religion-linked economic layer\n",
            digikat_format_integer(sum(in_econ)), digikat_format_integer(M)))

# ---- 3. locate all three vocabularies ---------------------------------------------------------------
# One vectorized locate per pattern over all selected texts, then regrouped per post. Doing it the other
# way (loop posts, loop patterns) is ~40x more regex invocations for the same answer.
rel <- me_build_religion_regex(verbose = FALSE)
cat(sprintf("Locating spans (%d CST + %d economy + 1 religion patterns over %s posts)...\n",
            length(CST_TERMS), length(ME_ECON), digikat_format_integer(M)))

locate_group <- function(patterns, fixed) {
  acc <- vector("list", M)
  for (j in seq_along(patterns)) {
    # fixed[[j]] not fixed[j]: isTRUE() is identical(TRUE, x), so a NAMED logical never passes it and
    # every document title would silently fall through to the regex branch.
    L <- if (isTRUE(fixed[[j]])) stri_locate_all_fixed(sel_low, patterns[[j]])
         else stri_locate_all_regex(sel_low, patterns[[j]])
    for (k in seq_len(M)) {
      m <- L[[k]]
      if (!is.na(m[1, 1])) acc[[k]] <- rbind(acc[[k]], m)
    }
  }
  lapply(acc, function(m) if (is.null(m)) matrix(integer(0), 0, 2) else m[order(m[, 1]), , drop = FALSE])
}

sp_cst  <- locate_group(as.list(CST_TERMS), CST_FIXED)                       # ALL terms — for highlighting
sp_econ <- locate_group(as.list(unlist(ME_ECON)), rep(FALSE, length(ME_ECON)))
sp_rel  <- locate_group(list(rel$with_caritas), FALSE)
# DISTANCE USES TIER-1 SPANS ONLY. Measuring against all 28 terms let a post qualify as "near" because a
# Tier-2 word ("solidarnost", "opće dobro") sat beside the economy while its actual doctrine term was far
# away — 354 posts, inflating the adjacent population from 1,198 to 1,552. Tier 2 bounds the count; it
# never defines membership, so it must not define adjacency either. Highlighting still shows every term.
sp_cst_t1 <- locate_group(as.list(CST_TERMS[t1_cols]), CST_FIXED[t1_cols])
cat("  done\n")

# Character gap between the CLOSEST CST match and the closest economic match. 0 = overlapping/adjacent.
# NA = the post has no economic match at all (possible for Tier-1 posts outside the econ layer).
gap_of <- function(A, B) {
  if (!nrow(A) || !nrow(B)) return(NA_integer_)
  g <- Inf
  for (i in seq_len(nrow(A))) {
    d <- pmax(0L, pmax(A[i, 1], B[, 1]) - pmin(A[i, 2], B[, 2]) - 1L)
    g <- min(g, min(d))
  }
  as.integer(g)
}
gap <- vapply(seq_len(M), function(k) gap_of(sp_cst_t1[[k]], sp_econ[[k]]), integer(1))

adj <- ifelse(is.na(gap), "none",
       ifelse(gap <= ME_WINDOW, "near",
       ifelse(gap <= 1000L, "mid", "far")))
card_t1 <- is_t1[idx]
cat(sprintf("  CST<->economy adjacency (Tier 1): near(<=%d) %s | mid %s | far %s | no econ match %s\n",
            ME_WINDOW,
            digikat_format_integer(sum(card_t1 & adj == "near")),
            digikat_format_integer(sum(card_t1 & adj == "mid")),
            digikat_format_integer(sum(card_t1 & adj == "far")),
            digikat_format_integer(sum(card_t1 & adj == "none"))))

# ---- 4. highlighting --------------------------------------------------------------------------------
# Spans are computed on the ORIGINAL text and the output is assembled by walking them, escaping the plain
# segments as we go. The earlier approach — escape, then re-run the patterns to insert <mark> — risked a
# later pattern matching inside markup already inserted by an earlier one.
esc <- vw_esc; nz <- vw_nz

merge_spans <- function(k, from, to) {
  cl <- rbind(
    if (nrow(sp_cst[[k]]))  cbind(sp_cst[[k]],  1L) else NULL,
    if (nrow(sp_econ[[k]])) cbind(sp_econ[[k]], 2L) else NULL,
    if (nrow(sp_rel[[k]]))  cbind(sp_rel[[k]],  3L) else NULL)
  if (is.null(cl) || !nrow(cl)) return(cl)
  cl <- cl[cl[, 1] >= from & cl[, 2] <= to, , drop = FALSE]
  if (!nrow(cl)) return(cl)
  cl <- cl[order(cl[, 1], cl[, 3]), , drop = FALSE]     # priority on ties: CST > economy > religion
  keep <- rep(TRUE, nrow(cl)); last_end <- -1L
  for (i in seq_len(nrow(cl))) {
    if (cl[i, 1] <= last_end) keep[i] <- FALSE else last_end <- cl[i, 2]
  }
  cl <- cl[keep, , drop = FALSE]
  if (nrow(cl) > SPAN_CAP) cl <- cl[seq_len(SPAN_CAP), , drop = FALSE]
  cl
}

CLS <- c("c", "e", "r")
render <- function(txt, spans, off = 0L) {
  if (is.null(spans) || !nrow(spans)) return(esc(txt))
  out <- character(0); prev <- 1L
  for (i in seq_len(nrow(spans))) {
    s <- spans[i, 1] - off; e <- spans[i, 2] - off
    if (s > prev) out <- c(out, esc(stri_sub(txt, prev, s - 1L)))
    out <- c(out, "<mark class=\"", CLS[spans[i, 3]], "\">", esc(stri_sub(txt, s, e)), "</mark>")
    prev <- e + 1L
  }
  if (prev <= stri_length(txt)) out <- c(out, esc(stri_sub(txt, prev)))
  paste0(out, collapse = "")
}

# Excerpt window: when a CST match and an economic match are close enough to show together, frame BOTH —
# that is the whole point of the page. Otherwise fall back to a window around the first CST match.
window_of <- function(k) {
  n <- stri_length(sel_text[k])
  A <- sp_cst_t1[[k]]; if (!nrow(A)) A <- sp_cst[[k]]
  B <- sp_econ[[k]]
  if (nrow(A) && nrow(B) && !is.na(gap[k]) && gap[k] <= PAIR_MAX) {
    best <- NULL; bd <- Inf
    for (i in seq_len(nrow(A))) {
      d <- pmax(0L, pmax(A[i, 1], B[, 1]) - pmin(A[i, 2], B[, 2]) - 1L)
      j <- which.min(d)
      if (d[j] < bd) { bd <- d[j]; best <- c(min(A[i, 1], B[j, 1]), max(A[i, 2], B[j, 2])) }
    }
    return(c(max(1L, best[1] - PAIR_PAD), min(n, best[2] + PAIR_PAD)))
  }
  s <- if (nrow(A)) A[1, 1] else 1L
  c(max(1L, s - PAD), min(n, s + PAD))
}

# ---- 5. cards ----------------------------------------------------------------------------------------
cat("Building cards...\n")
card <- function(k) {
  i     <- idx[k]
  terms <- names(CST_TERMS)[hits[i, ]]
  t1    <- intersect(terms, t1_cols)
  tier  <- if (length(t1)) "tier1" else "tier2"
  eras  <- unique(unname(CST_ERA[t1])); eras <- eras[eras != "—"]
  era   <- if (!length(eras)) "—" else if (length(eras) == 1L) eras else "mixed"

  w  <- window_of(k)
  ex <- stri_sub(sel_text[k], w[1], w[2])
  ex_html <- paste0(if (w[1] > 1) "… " else "",
                    render(ex, merge_spans(k, w[1], w[2]), off = w[1] - 1L),
                    if (w[2] < stri_length(sel_text[k])) " …" else "")

  ftxt <- stri_sub(sel_text[k], 1L, FULL_CHARS)
  more <- paste0(
    "<details><summary>Full text (", format(stri_length(sel_text[k])), " chars",
    if (stri_length(sel_text[k]) > FULL_CHARS) paste0("; first ", format(FULL_CHARS)) else "",
    ")</summary><div class=\"full\">",
    render(ftxt, merge_spans(k, 1L, min(FULL_CHARS, stri_length(sel_text[k])))), "</div></details>")

  url  <- nz(corpus$url[i], "")
  head <- if (nzchar(url))
    paste0("<a href=\"", esc(url), "\" target=\"_blank\" rel=\"noreferrer\">",
           esc(nz(corpus$actor[i], "(bez izvora)")), " — ", esc(nz(corpus$date[i])), "</a>")
  else paste0(esc(nz(corpus$actor[i], "(bez izvora)")), " <span class=\"nolink\">(no URL)</span>")

  gtxt <- if (is.na(gap[k])) "no economy match"
          else if (gap[k] == 0L) "CST touches economy"
          else paste0("CST ↔ economy: ", format(gap[k]), " chars")

  badges <- paste0("<span class=\"b ", ifelse(terms %in% t1_cols, "dom", ""), "\">",
                   esc(terms), "</span>", collapse = "")

  paste0(
    "<article class=\"c\" data-tier=\"", tier, "\" data-era=\"", era,
    "\" data-term=\"", esc(paste(terms, collapse = " ")),
    "\" data-econ=\"", if (in_econ[k]) "yes" else "no",
    "\" data-adj=\"", adj[k],
    "\" data-domain=\"", esc(doms[k]),
    "\" data-platform=\"", esc(nz(corpus$platform[i])),
    "\" data-stream=\"", esc(nz(corpus$data_source[i])), "\">",
    "<div class=\"bar\"><span class=\"n\">#", k, "</span>",
    "<span class=\"b ", if (tier == "tier1") "good" else "warn", "\">", tier, "</span>",
    if (era != "—") paste0("<span class=\"b dom\">", esc(era), "</span>") else "",
    if (in_econ[k]) "<span class=\"b good\">econ-linked</span>" else "",
    "<span class=\"b ", if (identical(adj[k], "near")) "good" else "warn", "\">", gtxt, "</span>",
    badges, "<span class=\"rid\">dk_", rid_sel[k], "</span></div>",
    "<h2>", head, "</h2>",
    "<div class=\"meta\">", esc(nz(corpus$platform[i])), " · ", esc(nz(corpus$data_source[i])),
    if (nzchar(doms[k])) paste0(" · domains: ", esc(doms[k])) else "", "</div>",
    "<div class=\"win\"><b>match in context</b>", ex_html, "</div>", more, "</article>")
}

cards <- paste0(vapply(seq_len(M), card, ""), collapse = "\n")
cards <- paste0(
  "<style>mark{padding:0 2px;border-radius:3px;font-weight:600;color:inherit}",
  "mark.c{background:rgba(224,138,78,.42)}",     # CST doctrine  — orange
  "mark.e{background:rgba(43,95,142,.30)}",      # economy       — blue
  "mark.r{background:rgba(46,107,69,.28)}",      # religion      — green
  ".key{padding:0 26px 6px;font-size:12.5px;color:var(--mut)}",
  ".key mark{font-weight:600}</style>", cards)

# ---- 6. page -------------------------------------------------------------------------------------------
term_of  <- unlist(lapply(seq_len(M), function(k) names(CST_TERMS)[hits[idx[k], ]]))
n_t1     <- sum(is_t1)
n_t1econ <- sum(card_t1 & in_econ)
n_near   <- sum(card_t1 & adj == "near")
# THE ANALYSIS POPULATION. All three conditions at once: Tier-1 doctrine, inside the religion-linked
# economic layer, AND the doctrine within +-220 chars of the economic term. Note this is NOT the same as
# `near` alone — 82 posts have CST adjacent to economics yet never entered the linked layer, because the
# 95-term religion lexicon does not contain CST vocabulary like "socijalni nauk" and so did not fire near
# the economic match. Those are kept visible under their own preset rather than quietly folded in.
n_core   <- sum(card_t1 & in_econ & adj == "near")
n_orphan <- sum(card_t1 & !in_econ & adj == "near")
n_drop   <- sum(card_t1 & in_econ & adj %in% c("mid", "far"))
n_fr <- sum(rowSums(hits[, CST_FRANCIS, drop = FALSE]) > 0)
n_cl <- sum(rowSums(hits[, CST_CLASSICAL, drop = FALSE]) > 0)

lab <- function(x, text, tone = NULL) {
  attr(x, "label") <- text; if (!is.null(tone)) attr(x, "tone") <- tone; x
}
presets <- list(
  core    = lab(c(tier = "tier1", econ = "yes", adj = "near"), paste("★ Analysis population", n_core), "hot"),
  loose   = lab(c(tier = "tier1", econ = "yes"),               paste("Econ-linked, any distance", n_t1econ)),
  dropped = lab(c(tier = "tier1", econ = "yes", adj = "far"),  paste("Dropped by the ±220 rule", sum(card_t1 & in_econ & adj == "far")), "bad"),
  orphan  = lab(c(tier = "tier1", econ = "no", adj = "near"),  paste("Adjacent but not linked", n_orphan), "bad"),
  tier1   = lab(c(tier = "tier1"),                             paste("All Tier 1", n_t1)),
  francis = lab(c(era = "francis"),                            paste("Francis-era", n_fr)),
  classic = lab(c(era = "classical"),                          paste("Classical labour-capital", n_cl)),
  poor    = lab(c(term = "opcija_za_siromasne"),               "Option for the poor"),
  tier2   = lab(c(tier = "tier2"),                             paste("Tier 2 sample", length(t2_show)), "bad"),
  all     = lab(character(0),                                  paste("All", M)))

tools <- paste0(
  vw_select("term",     "term",     sort(unique(term_of))),
  vw_select("era",      "era",      c("francis", "benedict", "classical", "conciliar", "mixed", "marker_only", "—")),
  vw_select("domain",   "domain",   names(ME_ECON)),
  vw_select("platform", "platform", corpus$platform[idx]),
  vw_select("stream",   "stream",   corpus$data_source[idx]),
  "<select data-f=\"adj\"><option value=\"\">CST↔economy: all</option>",
  "<option value=\"near\">near (≤", ME_WINDOW, ")</option><option value=\"mid\">mid (≤1000)</option>",
  "<option value=\"far\">far (&gt;1000)</option><option value=\"none\">no economy match</option></select>",
  "<select data-f=\"econ\"><option value=\"\">econ layer: all</option>",
  "<option value=\"yes\">econ-linked only</option><option value=\"no\">not econ-linked</option></select>",
  "<select data-f=\"tier\"><option value=\"\">tier: all</option>",
  "<option value=\"tier1\">Tier 1 only</option><option value=\"tier2\">Tier 2 only</option></select>")

subtitle <- paste0(
  digikat_format_integer(n_t1), " Tier-1 posts (all shown) · ",
  digikat_format_integer(length(t2_show)), " of ", digikat_format_integer(length(t2_only)),
  " Tier-2-only posts (RANDOM SAMPLE, seed ", ME_SEED, ") · corpus ", digikat_format_integer(N),
  " · generated ", format(Sys.time(), "%Y-%m-%d %H:%M"),
  "<br><b>Highlighting:</b> <mark class=\"c\">CST doctrine</mark> ",
  "<mark class=\"e\">economy</mark> <mark class=\"r\">religion</mark>. ",
  "Each card's badge gives the character gap between the nearest CST match and the nearest economic match.",
  "<br><b>★ Analysis population = ", n_core, "</b> — Tier-1 doctrine, inside the religion-linked economic ",
  "layer, doctrine within ±", ME_WINDOW, " chars of the economic term (", n_core, " of ", n_t1econ,
  " econ-linked Tier-1 posts survive the distance rule; ", n_drop, " are dropped). A further ", n_orphan,
  " posts are adjacent but never entered the linked layer — see the 'Adjacent but not linked' preset.",
  "<br>Tier 2 bounds the count, it does not measure it — read those cards as expected false positives.")

vw_page(OUT_HTML, "moral-economy — what the CST census matched",
        subtitle, presets, tools, cards,
        keys = c("tier", "era", "term", "econ", "adj", "domain", "platform", "stream"))
