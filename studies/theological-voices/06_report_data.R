# Stage 6: assemble every number the report prints into one JSON (private, it carries names).
# Nothing in the report is typed by hand; build_report.py formats what this file holds.
invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
suppressPackageStartupMessages({library(data.table); library(jsonlite)})
O <- "studies/theological-voices/output"; P <- file.path(O, "private")
meta <- fromJSON(file.path(O, "meta_sources.json"))
man <- fromJSON("data/digikat_corpus_manifest.json")
gp <- fread(file.path(O, "group_platform.csv")); groups <- fread(file.path(O, "groups.csv"))
sig <- readRDS(file.path(P, "posts_signals.rds"))
pv <- readRDS(file.path(P, "person_posts.rds")); lab <- readRDS(file.path(P, "theologian_label_posts.rds"))
v <- fread("studies/theological-voices/voices.csv", encoding = "UTF-8")
top <- fread(file.path(P, "top50_katolicki_akteri.csv"), encoding = "UTF-8")
allsrc <- fread(file.path(P, "all_sources.csv"), encoding = "UTF-8")
echo <- fread(file.path(O, "echo_summary.csv")); stories <- fread(file.path(P, "echo_top_stories.csv"), encoding = "UTF-8")
origin <- fread(file.path(P, "echo_origin_sources.csv"), encoding = "UTF-8")
pct <- function(a, b) 100 * a / b
`%||%` <- function(a, b) if (is.null(a)) b else a
R <- list()

# ---- scope ---------------------------------------------------------------------------------------
R$scope <- list(rows = man$corpus$rows, posts = meta$posts_after_dedup, dupes = meta$duplicates_removed,
  date_min = man$corpus$date_min, date_max = man$corpus$date_max, sources = meta$all_sources,
  core_posts = meta$core_posts, core_sources = meta$core_sources, sha = substr(man$corpus$sha256, 1, 12),
  platforms = man$corpus$platform_counts, precision = 84.5)

# ---- act I: attention ------------------------------------------------------------------------------
gp[, catholic := !group %in% c("public", "other_christian")]
plat <- function(p) {z <- gp[platform == p]
  list(groups = z[, .(group, posts, sources, interactions, median, post_share = 100 * post_share, int_share = 100 * int_share)],
       catholic_post_share = z[catholic == TRUE, sum(100 * post_share)], catholic_int_share = z[catholic == TRUE, sum(100 * int_share)])}
R$platform <- list(youtube = plat("youtube"), facebook = plat("facebook"), web = plat("web"))
R$groups <- groups[, .(group, label, posts, sources, interactions, median, doctrine = 100 * doctrine)]

pul <- allsrc[source == "pulherissimus" & platform == "youtube"]
clergy_posts <- groups[group == "clergy", posts]
yt_cath_int <- gp[platform == "youtube" & catholic == TRUE, sum(interactions)]
R$pulherissimus <- list(posts = pul$posts, interactions = pul$interactions, median = pul$median,
  share_of_clergy_posts = pct(pul$posts, clergy_posts), rank = top[source == "pulherissimus", rank],
  share_of_yt_catholic_int = pct(pul$interactions, yt_cath_int),
  months = pul$months, first = as.character(pul$first))
R$hkm <- as.list(allsrc[source == "hkm.hr" & platform == "web", .(posts, interactions, median)])

# keyword signals, with the one-channel clergy group shown with and without that channel
s <- sig[has_text == TRUE]
sg <- s[, .(n = .N, nauk = 100 * mean(sig_nauk), pismo = 100 * mean(sig_pismo), uciteljstvo = 100 * mean(sig_uciteljstvo),
            predaja = 100 * mean(sig_predaja), privatna = 100 * mean(sig_objava_priv), iskustvo = 100 * mean(sig_iskustvo),
            znanost = 100 * mean(sig_znanost)), by = group]
sg_loo <- s[group == "clergy" & source_id != "youtube::pulherissimus", .(n = .N, nauk = 100 * mean(sig_nauk),
            uciteljstvo = 100 * mean(sig_uciteljstvo), iskustvo = 100 * mean(sig_iskustvo))]
R$signals <- sg; R$signals_clergy_without_pul <- sg_loo

# ---- act II: voices (closed list) ------------------------------------------------------------------
R$list <- list(persons = nrow(v), women = sum(v$zena), roles = v[, .N, by = role])
roles <- pv[, .(persons = uniqueN(id), mentions = .N, statements = sum(statement)), by = role]
roles[, `:=`(stmt_share = pct(statements, sum(statements)), stmt_rate = pct(statements, mentions))]
R$roles <- roles
R$stmt_total <- sum(pv$statement); R$stmt_posts <- uniqueN(pv[statement == TRUE]$row)
per <- pv[, .(mentions = .N, statements = sum(statement), other_stmt = sum(statement & !core),
              catholic_stmt = sum(statement & core)), by = .(id, name, role, zena)][order(-statements)]
per[, ratio := mentions / pmax(statements, 1)]
R$persons <- per
R$women_stmt <- pv[statement == TRUE, .(statements = .N), by = zena][, share := pct(statements, sum(statements))]
yr <- pv[statement == TRUE, .N, by = .(role, year)][, share := pct(N, sum(N)), by = year]
R$roles_year <- yr
src <- pv[statement == TRUE, .N, by = .(role, catholic = core)][, share := pct(N, sum(N)), by = catholic]
R$roles_source <- src
R$other_stmt_share <- pct(pv[statement == TRUE & !core, .N], pv[statement == TRUE, .N])
R$bishop_other_share <- pct(pv[statement == TRUE & !core & role == "biskup", .N], pv[statement == TRUE & role == "biskup", .N])

# who is CALLED a theologian
ac <- v[role == "akademski"]
lab[, academic := grepl(paste(substr(ac$surname, 1, nchar(ac$surname) - 1), collapse = "|"), name)]
# Inflected forms of one name ("Karl Rahner", "Karla Rahnera") share a key of 4-letter token stems;
# posts are counted once per key, and the most frequent form is kept for display.
lab[, nkey := vapply(strsplit(name, "[- ]"), function(t) paste(substr(t, 1, 4), collapse = " "), "")]
lab[, display := names(which.max(table(name))), by = nkey]
L <- unique(lab, by = c("row", "nkey"))[, .(posts = .N, catholic = sum(core), other = sum(!core),
  academic = any(academic)), by = .(nkey, name = display)][order(-posts)]
R$label <- list(posts = uniqueN(lab$row), other_posts = uniqueN(lab[core == FALSE]$row),
  names = uniqueN(lab$name), other_names = uniqueN(lab[core == FALSE]$name),
  academic_posts = uniqueN(lab[academic == TRUE]$row), top = L[1:30])

# ---- act III: echo -----------------------------------------------------------------------------------
R$echo <- as.list(echo)
R$echo_top <- stories[1:12]
R$echo_origin <- origin[1:10]
R$echo_hkm_first <- origin[first_key == "hkm.hr", N]
# Dated portal sequence for the most-echoed domestic stories (cold open + echo page).
pm <- readRDS(file.path(P, "posts_meta.rds"))
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
pm[, tkey := tv_title_key(TITLE)]
seq_for <- function(k) {z <- pm[SOURCE_TYPE == "web" & tkey == k][order(date, input_order)]
  list(title = z$TITLE[1], first = as.character(min(z$date)), last = as.character(max(z$date)),
       sources = unique(z$key), catholic = unique(z$key[z$core]))}
R$echo_sequences <- lapply(stories$tkey[1:12], seq_for)
R$monthly <- pm[, .N, by = .(month = format(date, "%Y-%m"))][order(month)]
rm(pm)

# ---- act IV: the reviewed sample -----------------------------------------------------------------------
smp <- readRDS(file.path(P, "sample.rds"))
files <- sort(list.files(file.path(P, "coding"), "^coded_[0-9]+\\.jsonl$", full.names = TRUE))
coded <- rbindlist(lapply(files, function(f) {
  rbindlist(lapply(readLines(f, encoding = "UTF-8", warn = FALSE), function(l) {
    x <- fromJSON(l, simplifyVector = FALSE)
    data.table(sid = x$sid, tumacenje = isTRUE(x$tumacenje), glavni_tumac = x$glavni_tumac %||% "nema",
      mandat = x$mandat %||% "nema", tema = x$tema %||% "drugo", ton = x$ton %||% "neutralan",
      vjernici_opisani = isTRUE(x$vjernici_opisani), vjernici_govore = isTRUE(x$vjernici_govore),
      kanal_tumaci = isTRUE(x$kanal_tumaci), autoritet = list(as.character(unlist(x$autoritet))),
      glasovi = list(rbindlist(lapply(x$glasovi, function(g) data.table(ime = g$ime %||% "", uloga = g$uloga %||% "drugo",
        govori = isTRUE(g$govori), tumaci = isTRUE(g$tumaci))), fill = TRUE)))
  }))
}))
stopifnot(nrow(coded) == nrow(smp), setequal(coded$sid, smp$sid), !anyDuplicated(coded$sid))
coded <- merge(coded, smp[, .(sid, stratum, platform, story_sources, group)], by = "sid")
saveRDS(coded, file.path(P, "coded_sample.rds"))
tab <- function(z, col) z[, .N, by = c("stratum", col)][, share := pct(N, sum(N)), by = stratum][order(stratum, -N)]
ci <- coded[tumacenje == TRUE]
aut <- ci[, .(a = as.character(c(unlist(autoritet), character()))), by = .(sid, stratum)]
voices <- coded[, rbindlist(glasovi, fill = TRUE), by = .(sid, stratum)]
R$sample <- list(n = nrow(coded), per_stratum = coded[, .N, by = stratum],
  frame = fread(file.path(O, "sample_frame.csv")),
  interpreting = coded[, .(n = .N, interp = sum(tumacenje), share = pct(sum(tumacenje), .N)), by = stratum],
  main = tab(ci, "glavni_tumac"), mandat = tab(ci, "mandat"),
  autoritet = aut[, .N, by = .(stratum, a)][, share := pct(N, ci[, .N, by = stratum][match(stratum, ci[, .N, by = stratum]$stratum), N])][order(stratum, -N)],
  interp_n = ci[, .N, by = stratum],
  tema = tab(coded, "tema"), ton = tab(coded, "ton"),
  believers = coded[, .(n = .N, opisani = sum(vjernici_opisani), govore = sum(vjernici_govore)), by = stratum],
  voices = if (nrow(voices)) voices[govori == TRUE, .N, by = .(stratum, uloga)][, share := pct(N, sum(N)), by = stratum][order(stratum, -N)] else NULL,
  voices_interpreting = if (nrow(voices)) voices[tumaci == TRUE, .N, by = .(stratum, uloga)][, share := pct(N, sum(N)), by = stratum][order(stratum, -N)] else NULL,
  kanal = ci[, .(kanal = sum(kanal_tumaci), n = .N), by = stratum],
  echoed = coded[, .(multi = sum(story_sources >= 2), n = .N), by = stratum])

# ---- top 50 with channel-level coding ----------------------------------------------------------------
sc_file <- file.path(P, "coding", "sources_coded.jsonl")
if (file.exists(sc_file)) {
  sc <- rbindlist(lapply(readLines(sc_file, encoding = "UTF-8", warn = FALSE), function(l) {
    x <- fromJSON(l, simplifyVector = FALSE)
    data.table(rank = x$rank, tip = x$tip, mandat = x$mandat, teolosko_obrazovanje = x$teolosko_obrazovanje,
      autoritet = paste(unlist(x$autoritet), collapse = ", "), teme = paste(unlist(x$teme), collapse = ", "),
      ton = x$ton, tumaci_nauk = x$tumaci_nauk, napomena = x$napomena)}))
  stopifnot(nrow(sc) == 50, setequal(sc$rank, top$rank))
  top <- merge(top[, !c("mandat", "teolosko_obrazovanje", "ton", "napomena")], sc, by = "rank")
  setorder(top, rank)
  fwrite(top, file.path(P, "top50_katolicki_akteri_kodirano.csv"), bom = TRUE)
  R$top50_tip <- top[, .(n = .N, interactions = sum(interactions)), by = tip][order(-interactions)]
  R$top50_mandat <- top[, .N, by = mandat][order(-N)]
  R$top50_obrazovanje <- top[, .N, by = teolosko_obrazovanje]
  R$top50_tumaci <- top[, .N, by = tumaci_nauk]
}
R$top50 <- top[, intersect(c("rank", "platform", "source", "group_label", "posts", "interactions", "median",
  "platform_rank", "top_voice", "tip", "mandat", "teolosko_obrazovanje", "autoritet", "teme", "ton", "tumaci_nauk", "napomena"), names(top)), with = FALSE]
R$top50_platform <- top[, .(n = .N, interactions = sum(interactions)), by = platform]
write_json(R, file.path(P, "report_data.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA, dataframe = "rows", na = "null")
cat("report_data.json written\n")
print(R$sample$interpreting); print(R$sample$main); print(R$sample$believers)
