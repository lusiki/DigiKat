#!/usr/bin/env Rscript
# 13_core_viewer.R — the 520 measured posts as one filterable local page.
#
# Every number in the paper rests on these 520 posts. A coding claim can only be believed
# if someone has looked at what was coded, so this renders each post as a card with its
# date, outlet, coded category, the passage that put it in the set, and a link to the
# original. The cost-of-living term is highlighted in blue and the religious term in
# green, which is the pair the selection filter required to be within 220 characters.
#
#   Rscript studies/inflation-salience/13_core_viewer.R [--full-chars=4000] [--pad=420]
#
# OUTPUT IS RESTRICTED. It carries row-level text, URLs and outlet identities, so it is
# written to gitignored output/private/ and must never be committed, published, rendered
# into docs/, or included in the replication package. Open it from disk in a browser.
#
# The HTML shell is the project's shared viewer library, which lives with the
# moral-economy study and is sourced read-only. It is not modified here.

source("studies/inflation-salience/_lib.R")
source("studies/moral-economy/viewer_lib.R")

ARGS <- commandArgs(trailingOnly = TRUE)
argv <- function(flag, default) {
  hit <- grep(paste0("^", flag, "="), ARGS, value = TRUE)
  if (length(hit)) sub(paste0("^", flag, "="), "", hit[1]) else default
}
FULL_CHARS <- as.integer(argv("--full-chars", "4000"))
PAD        <- as.integer(argv("--pad", "420"))
OUT_HTML   <- file.path(PRIVATE, "core_viewer.html")

rule("13_core_viewer.R")

coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
core  <- coded[domestic == 1L][order(date)]
msg("measured posts: ", nrow(core))

m <- readRDS(MASTER)
title <- ifelse(is.na(m$TITLE[core$rid]), "", as.character(m$TITLE[core$rid]))
body  <- ifelse(is.na(m$FULL_TEXT[core$rid]), "", as.character(m$FULL_TEXT[core$rid]))
url   <- ifelse(is.na(m$URL[core$rid]), "", as.character(m$URL[core$rid]))
rm(m); invisible(gc())

# One whitespace-collapsed text per post, used for display and for locating matches, so the
# offsets the highlighter uses are the offsets of the string the reader sees.
disp <- stri_trim_both(stri_replace_all_regex(paste0(title, " ", body), "[\\p{Zs}\\t\\r\\n]+", " "))
low  <- stri_trans_tolower(disp)
low_masked <- mask_homonyms(low)
RELIG <- religious_regex()

## ------------------------------------------------------------ highlighting -----

# Marks cost-of-living and religious matches in one pass. Spans are merged before insertion
# because the two vocabularies can overlap and nested <mark> tags would render badly.
mark_spans <- function(txt_disp, txt_low, from, to) {
  a <- stri_locate_all_regex(txt_low, INFL_ANY, omit_no_match = TRUE)[[1]]
  b <- stri_locate_all_regex(txt_low, RELIG,    omit_no_match = TRUE)[[1]]
  sp <- rbind(
    if (nrow(a)) cbind(a, 1L) else NULL,
    if (nrow(b)) cbind(b, 2L) else NULL
  )
  if (is.null(sp) || !nrow(sp)) return(vw_esc(substr(txt_disp, from, to)))
  sp <- sp[sp[, 1] >= from & sp[, 2] <= to, , drop = FALSE]
  if (!nrow(sp)) return(vw_esc(substr(txt_disp, from, to)))
  sp <- sp[order(sp[, 1]), , drop = FALSE]

  out <- character(0); cur <- from
  keep_to <- 0L
  for (i in seq_len(nrow(sp))) {
    s <- sp[i, 1]; e <- sp[i, 2]; k <- sp[i, 3]
    if (s <= keep_to) next                      # already inside a marked span
    out <- c(out, vw_esc(substr(txt_disp, cur, s - 1L)),
             "<mark class=\"m", k, "\">", vw_esc(substr(txt_disp, s, e)), "</mark>")
    cur <- e + 1L; keep_to <- e
  }
  paste0(c(out, vw_esc(substr(txt_disp, cur, to))), collapse = "")
}

## ------------------------------------------------------------------ cards -----

RESP_OF <- c(institution = "Public voice", crl = "Repricing", charity = "Charitable response",
             justice = "Normative response", devotional = "Devotional", other = "Other",
             disputed = "Unresolved")
SUBJECT <- c(crl = "the price of religious services", institution = "the sector as an economic actor",
             charity = "charitable relief", justice = "who bears the burden",
             devotional = "devotional", other = "other", disputed = "unresolved")
METHOD <- c(monitoring = "A", backfill = "B")

msg("building cards ...")
cards <- character(nrow(core))
for (i in seq_len(nrow(core))) {
  loc <- stri_locate_first_regex(low[i], INFL_ANY)
  ctr <- if (is.na(loc[1, 1])) 1L else as.integer((loc[1, 1] + loc[1, 2]) / 2)
  from <- max(1L, ctr - PAD); to <- min(nchar(disp[i]), ctr + PAD)

  ex <- mark_spans(disp[i], low_masked[i], from, to)
  full <- if (nchar(disp[i]) > (to - from + 1L))
    paste0("<details><summary>full text (", format(nchar(disp[i]), big.mark = " "),
           " characters)</summary><div class=\"full\">",
           mark_spans(disp[i], low_masked[i], 1L, min(nchar(disp[i]), FULL_CHARS)),
           if (nchar(disp[i]) > FULL_CHARS) " …" else "", "</div></details>") else ""

  reg <- core$register[i]
  head_html <- if (nzchar(url[i]))
    paste0("<a href=\"", vw_esc(url[i]), "\" target=\"_blank\" rel=\"noopener\">",
           vw_esc(vw_nz(title[i], "(no headline)")), "</a>")
  else paste0(vw_esc(vw_nz(title[i], "(no headline)")), " <span class=\"nolink\">no link</span>")

  cards[i] <- paste0(
    "<article class=\"c\"",
    " data-response=\"", vw_esc(RESP_OF[[reg]]), "\"",
    " data-subject=\"", vw_esc(reg), "\"",
    " data-year=\"", core$year[i], "\"",
    " data-method=\"", vw_esc(METHOD[[core$stream[i]]]), "\"",
    " data-outlet=\"", vw_esc(core$otype[i]), "\"",
    " data-tone=\"", vw_esc(vw_nz(core$sentiment[i], "none")), "\">",
    "<div class=\"bar\"><span class=\"n\">", format(core$date[i]), "</span>",
    # One badge, not two: the response name and the Table 4 subject label are the same
    # coded category under two names, and showing both reads as extra information.
    "<span class=\"b dom\">", vw_esc(RESP_OF[[reg]]), "</span>",
    "<span class=\"b\">method ", METHOD[[core$stream[i]]], "</span>",
    "<span class=\"b\">", vw_esc(core$otype[i]), "</span>",
    if (!is.na(core$sentiment[i]) && nzchar(core$sentiment[i]))
      paste0("<span class=\"b\">", vw_esc(core$sentiment[i]), "</span>") else "",
    "<span class=\"rid\">row ", core$rid[i], "</span></div>",
    "<h2>", head_html, "</h2>",
    "<div class=\"meta\">", vw_esc(vw_nz(core$outlet[i])), "</div>",
    "<div class=\"win\"><b>the passage that put this post in the set</b>",
    if (from > 1) "… " else "", ex, if (to < nchar(disp[i])) " …" else "", "</div>",
    full, "</article>")
  if (i %% 100L == 0L) msg("  ", i, " / ", nrow(core))
}

## ---------------------------------------------------------------- presets -----

pre <- function(label, tone = NULL, ...) {
  v <- c(...)
  # The "all" chip carries no filters, and c() with no arguments is NULL, which cannot hold
  # an attribute. viewer_lib emits `name:{}` for a zero-length vector, which is what it needs.
  if (is.null(v)) v <- character(0)
  attr(v, "label") <- label
  if (!is.null(tone)) attr(v, "tone") <- tone
  v
}
n_of <- function(reg) sum(core$register == reg)

presets <- list(
  all       = pre(paste0("all ", nrow(core), " posts")),
  voice     = pre(paste0("public voice (", n_of("institution"), ")"), response = "Public voice"),
  repricing = pre(paste0("repricing (", n_of("crl"), ")"), response = "Repricing"),
  charity   = pre(paste0("charitable response (", n_of("charity"), ")"), response = "Charitable response"),
  justice   = pre(paste0("who bears the burden (", n_of("justice"), ")"), tone = "bad",
                  response = "Normative response"),
  unresolved = pre(paste0("unresolved (", n_of("disputed"), ")"), tone = "bad", subject = "disputed"),
  peak2022  = pre("the 2022 shock", year = "2022"),
  late      = pre("2024 onward", method = "B"),
  catholic  = pre(paste0("Catholic outlets (", sum(core$otype == "Catholic"), ")"), outlet = "Catholic")
)

tools <- paste0(
  vw_select("response", "response", vapply(core$register, function(r) RESP_OF[[r]], "")),
  vw_select("year", "year", as.character(core$year)),
  vw_select("method", "method", vapply(core$stream, function(s) METHOD[[s]], "")),
  vw_select("outlet", "outlet", core$otype),
  vw_select("tone", "tone", vw_nz(core$sentiment, "none")))

subtitle <- paste0(
  "The ", nrow(core), " posts the paper measures, ", format(min(core$date)), " to ",
  format(max(core$date)), ". These are the posts coded as genuinely about Croatian inflation ",
  "<i>and</i> genuinely connected to religion, out of ", format(nrow(coded), big.mark = " "),
  " candidates read. <mark class=\"m1\">Blue</mark> marks the cost-of-living term, ",
  "<mark class=\"m2\">green</mark> the religious term. Headlines link to the original post.")

EXTRA_CSS <- paste0(VW_CSS, "
mark{padding:0 2px;border-radius:3px;color:inherit}
mark.m1{background:rgba(43,95,142,.28);box-shadow:inset 0 -2px 0 var(--acc)}
mark.m2{background:rgba(46,107,69,.26);box-shadow:inset 0 -2px 0 var(--ok)}
")
assign("VW_CSS", EXTRA_CSS, envir = globalenv())

vw_page(OUT_HTML,
        "inflation-salience — the 520 measured posts",
        subtitle, presets, tools, paste0(cards, collapse = ""),
        keys = c("response", "subject", "year", "method", "outlet", "tone"))

rule("Reconciliation with the paper")
msg("  posts in this page                : ", nrow(core), "   (Table 1, measured set)")
for (r in c("crl", "institution", "charity", "devotional", "justice", "disputed", "other"))
  msg(sprintf("  %-34s %3d   (Table 4)", SUBJECT[[r]], n_of(r)))
msg("\n  by year: ", paste(sprintf("%d:%d", sort(unique(core$year)),
                                   core[, .N, by = year][order(year)]$N), collapse = "  "))
msg("\nopen it with:  start ", normalizePath(OUT_HTML, winslash = "\\"))
