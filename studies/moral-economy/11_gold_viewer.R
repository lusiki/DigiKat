#!/usr/bin/env Rscript
# moral-economy — GOLD SAMPLE VIEWER (local, private, read-only).
#
# Renders the 555 hand-coded gold posts as ONE self-contained HTML page for eyeball inspection:
# title (linked to its URL), outlet/date/stream, the +-220-char keyword window, the 800-char excerpt
# the coders actually saw, the full article text, and all three coding passes side by side with the
# majority verdict and the machine labels.
#
#   Rscript studies/moral-economy/11_gold_viewer.R [--refresh-meta] [--full-chars=20000]
#
# OUTPUT IS RESTRICTED. It carries row-level text, URLs and outlet identities, so it is written to
# gitignored output/private/ and must never be committed, published, or rendered into docs/.
#
# The master is opened READ-ONLY and only once: TITLE/URL/FULL_TEXT for the 555 rids are cached to
# output/private/gold_meta_cache.rds, so re-runs never touch it again. Pause Dropbox for the first
# run (cold 1.2 GB read; CLAUDE.local.md).
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/viewer_lib.R"))

ARGS       <- commandArgs(TRUE)
REFRESH    <- any(grepl("^--refresh-meta$", ARGS))
FULL_CHARS <- as.integer(digikat_cli_value(ARGS, "--full-chars", "20000"))
OUT_HTML  <- file.path(ME_PRIVATE, "gold_viewer.html")
CACHE     <- file.path(ME_PRIVATE, "gold_meta_cache.rds")
MASTER    <- here::here("data/merged_comprehensive.rds")

# ---- 1. the coded material ---------------------------------------------------------------------
rd <- function(p) read.csv(p, encoding = "UTF-8", stringsAsFactors = FALSE)
sheet <- rd(file.path(ME_PRIVATE, "gold_sheet.csv"))     # blind: rid, domain, window, text_800
key   <- rd(file.path(ME_PRIVATE, "gold_key.csv"))       # withheld meta + machine labels
core  <- rd(file.path(ME_PRIVATE, "gold_core.csv"))      # majority-adjudicated axes

if (anyDuplicated(sheet$rid)) stop("gold_sheet.csv has duplicate rids; the annotator join is by rid alone.")
if (!setequal(sheet$rid, key$rid) || !setequal(sheet$rid, core$rid))
  stop("gold_sheet / gold_key / gold_core do not cover the same rids.")

ann <- lapply(1:3, function(i) {
  fs <- list.files(file.path(ME_PRIVATE, paste0("ann", i)), pattern = "\\.tsv$", full.names = TRUE)
  if (!length(fs)) stop("No annotator files under private/ann", i)
  a <- do.call(rbind, lapply(fs, function(f)
    read.delim(f, encoding = "UTF-8", stringsAsFactors = FALSE, colClasses = "character")))
  if (!setequal(a$rid, as.character(sheet$rid)))
    stop("ann", i, " does not cover exactly the 555 gold rids (", nrow(a), " rows).")
  a[match(as.character(sheet$rid), a$rid), ]
})
cat(sprintf("Loaded %d gold posts x 3 coding passes.\n", nrow(sheet)))

key  <- key[match(sheet$rid, key$rid), ]
core <- core[match(sheet$rid, core$rid), ]

# ---- 2. title / URL / full text (cached; master read once) --------------------------------------
cand <- readRDS(file.path(ME_OUT, "stageA_candidates.rds"))
cand <- cand[!duplicated(cand$rid), c("rid", "TITLE", "URL")]

if (REFRESH || !file.exists(CACHE)) {
  if (!file.exists(MASTER)) stop("Master not on this machine; cannot build the meta cache.")
  fi0 <- file.info(MASTER)
  cat("Reading master READ-ONLY (pause Dropbox) ...\n"); t0 <- Sys.time()
  corpus <- readRDS(MASTER)
  if (inherits(corpus, "data.table")) data.table::setDF(corpus) else corpus <- as.data.frame(corpus)
  cat(sprintf("  %s rows in %.1f min\n", format(nrow(corpus), big.mark = ","),
              as.numeric(difftime(Sys.time(), t0, units = "mins"))))
  gc0 <- function(nm) if (nm %in% names(corpus)) corpus[[nm]] else rep(NA_character_, nrow(corpus))
  i <- sheet$rid
  if (max(i) > nrow(corpus)) stop("rid exceeds master row count — rid is not a master row index here.")
  meta <- data.frame(rid = i, TITLE = gc0("TITLE")[i], URL = gc0("URL")[i],
                     FROM = gc0("FROM")[i], SOURCE_TYPE = gc0("SOURCE_TYPE")[i],
                     DATE = as.character(gc0("DATE")[i]),
                     full_text = substr(corpus$FULL_TEXT[i], 1, FULL_CHARS),
                     full_len = nchar(corpus$FULL_TEXT[i]), stringsAsFactors = FALSE)
  rm(corpus); gc(verbose = FALSE)

  # INTEGRITY: rid must be the master row index. Stage A recorded TITLE/URL for 490 of these rids
  # independently; if the master row we just pulled disagrees, the whole join is wrong.
  chk <- merge(meta[, c("rid", "TITLE", "URL")], cand, by = "rid", suffixes = c("_master", "_stageA"))
  bad <- sum(!is.na(chk$URL_stageA) & nzchar(chk$URL_stageA) & chk$URL_master != chk$URL_stageA)
  if (bad > 0) stop("rid<->master mismatch on ", bad, " of ", nrow(chk), " Stage-A-known rows.")
  cat(sprintf("  rid integrity: %d/%d Stage-A rows match the master on URL exactly.\n",
              nrow(chk) - bad, nrow(chk)))

  fi1 <- file.info(MASTER)
  if (!identical(fi0$size, fi1$size) || !identical(fi0$mtime, fi1$mtime))
    stop("Master size/mtime changed during a read-only pass — investigate before trusting anything.")
  saveRDS(meta, CACHE); cat("  cached ->", CACHE, "\n")
} else {
  cat("Using cached meta (", CACHE, "); --refresh-meta to rebuild.\n")
}
meta <- readRDS(CACHE)
meta <- meta[match(sheet$rid, meta$rid), ]

# ---- 3. HTML -----------------------------------------------------------------------------------
esc <- vw_esc; nz <- vw_nz

AX_LAB <- c(ax1_link_genuine = "1 · genuine link", ax2_geography = "2 · geography",
            ax3_actor_commentator = "3 · actor / commentator", ax4_register = "4 · register",
            ax5_poverty_split = "5 · poverty split", ax6_ksn_principle = "6 · CST principle",
            ax7_encyclical = "7 · encyclical")

card <- function(k) {
  agree <- vapply(ME_AXES, function(a)
    length(unique(c(ann[[1]][[a]][k], ann[[2]][[a]][k], ann[[3]][[a]][k]))) == 1L, logical(1))
  rows <- paste0(
    "<tr class=\"", ifelse(agree, "", "dis"), "\"><th>", AX_LAB[ME_AXES], "</th><td>",
    esc(vapply(ME_AXES, function(a) nz(ann[[1]][[a]][k]), "")), "</td><td>",
    esc(vapply(ME_AXES, function(a) nz(ann[[2]][[a]][k]), "")), "</td><td>",
    esc(vapply(ME_AXES, function(a) nz(ann[[3]][[a]][k]), "")), "</td><td class=\"maj\">",
    esc(vapply(ME_AXES, function(a) nz(core[[a]][k]), "")), "</td></tr>", collapse = "")

  gen   <- nz(core$ax1_link_genuine[k])
  title <- nz(meta$TITLE[k], "(bez naslova)")
  url   <- nz(meta$URL[k], "")
  head  <- if (nzchar(url)) paste0("<a href=\"", esc(url), "\" target=\"_blank\" rel=\"noreferrer\">",
                                   esc(title), "</a>") else paste0(esc(title), " <span class=\"nolink\">(no URL)</span>")
  ftxt  <- nz(meta$full_text[k], "")
  more  <- if (nzchar(ftxt)) paste0(
    "<details><summary>Full text (", format(nz(meta$full_len[k], 0)), " chars",
    if (!is.na(meta$full_len[k]) && meta$full_len[k] > FULL_CHARS)
      paste0("; showing first ", format(FULL_CHARS)) else "", ")</summary><div class=\"full\">",
    esc(ftxt), "</div></details>") else ""

  paste0(
    "<article class=\"c\" data-domain=\"", esc(sheet$domain[k]), "\" data-stratum=\"", esc(key$stratum[k]),
    "\" data-split=\"", esc(key$split[k]), "\" data-gen=\"", esc(gen), "\" data-reg=\"",
    esc(nz(core$ax4_register[k])), "\" data-agree=\"", if (all(agree)) "all" else "split",
    "\" data-label=\"", esc(nz(key$label[k])), "\" data-pov=\"",
    if (identical(sheet$domain[k], "poverty_social")) "poverty" else "other", "\">",
    "<div class=\"bar\"><span class=\"n\">#", k, "</span>",
    "<span class=\"b dom\">", esc(sheet$domain[k]), "</span>",
    "<span class=\"b str\">", esc(key$stratum[k]), "</span>",
    "<span class=\"b spl\">", esc(key$split[k]), "</span>",
    "<span class=\"b g-", esc(gen), "\">", esc(gen), "</span>",
    "<span class=\"b reg\">", esc(nz(core$ax4_register[k])), "</span>",
    if (!all(agree)) "<span class=\"b warn\">coders split</span>" else "",
    "<span class=\"rid\">rid ", sheet$rid[k], "</span></div>",
    "<h2>", head, "</h2>",
    "<div class=\"meta\">", esc(nz(meta$FROM[k], nz(key$FROM[k]))), " · ", esc(nz(key$DATE[k])),
    " · ", esc(nz(key$stream[k])), " · ", esc(nz(key$label[k])),
    " · sem: ", esc(nz(key$sem_register[k])), " (z ", esc(nz(key$z_econ_minus_doct[k])),
    ", score ", esc(nz(key$sem_domain_score[k])), ")</div>",
    "<div class=\"win\"><b>±220 window</b>", esc(sheet$window[k]), "</div>",
    "<div class=\"exc\"><b>800-char excerpt shown to coders</b>", esc(sheet$text_800[k]), "</div>",
    more,
    "<table class=\"codes\"><thead><tr><th>axis</th><th>pass 1</th><th>pass 2</th><th>pass 3</th>",
    "<th class=\"maj\">majority</th></tr></thead><tbody>", rows, "</tbody></table></article>")
}

cards <- paste0(vapply(seq_len(nrow(sheet)), card, ""), collapse = "\n")

is_gen  <- core$ax1_link_genuine == "genuine"
is_pov  <- sheet$domain == "poverty_social"
n_gen   <- sum(is_gen, na.rm = TRUE)
n_url   <- sum(!is.na(meta$URL) & nzchar(meta$URL))
n_split <- sum(vapply(seq_len(nrow(sheet)), function(k) any(vapply(ME_AXES, function(a)
  length(unique(c(ann[[1]][[a]][k], ann[[2]][[a]][k], ann[[3]][[a]][k]))) > 1L, logical(1))), logical(1)))

lab <- function(x, text, tone = NULL) {
  attr(x, "label") <- text; if (!is.null(tone)) attr(x, "tone") <- tone; x
}
presets <- list(
  all     = lab(character(0),                          paste("All", nrow(sheet))),
  real    = lab(c(gen = "genuine"),                    paste("Real links", n_gen), "hot"),
  realpov = lab(c(gen = "genuine", pov = "poverty"),   paste("Real · poverty", sum(is_gen & is_pov))),
  realoth = lab(c(gen = "genuine", pov = "other"),     paste("Real · other domains", sum(is_gen & !is_pov))),
  split   = lab(c(agree = "split"),                    paste("Coders split", n_split)),
  gap     = lab(c(stratum = "recall_gap"),             paste("Recall gap", sum(key$stratum == "recall_gap"))))

tools <- paste0(
  vw_select("domain",  "domain",  sheet$domain),
  vw_select("stratum", "stratum", key$stratum),
  vw_select("split",   "split",   key$split),
  vw_select("gen",     "link",    core$ax1_link_genuine),
  vw_select("reg",     "register", core$ax4_register),
  "<select data-f=\"agree\"><option value=\"\">agreement: all</option>",
  "<option value=\"all\">all three agree</option><option value=\"split\">coders split</option></select>")

vw_page(OUT_HTML, "moral-economy — the 555 hand-coded gold posts",
        paste0(n_gen, " genuine links (", sprintf("%.1f%%", 100 * n_gen / nrow(core)), ") · ",
               n_url, " of ", nrow(sheet), " have a URL · three blind LLM passes, ",
               "majority-adjudicated · generated ", format(Sys.time(), "%Y-%m-%d %H:%M")),
        presets, tools, cards,
        keys = c("domain", "stratum", "split", "gen", "reg", "agree", "pov"))
