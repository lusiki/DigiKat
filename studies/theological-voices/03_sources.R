# Stage 3: sources. Actor-type breakdown, named top 50 by recorded interactions, concentration,
# corpus-tier keyword signals (doctrine, invoked authority) and story grouping (echo).
# Engagement is the vendor's INTERACTIONS field; it is defined differently per platform, so every
# comparison of engagement is made WITHIN a platform. Missing is not zero.
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
suppressPackageStartupMessages(library(stringi))
d <- tv_load()
s <- attr(d, "sources")
n_posts <- nrow(d)

# ---- keyword signals on the first 3 000 characters (same window as the inclusion rule) ----------
low <- stri_trans_tolower(stri_sub(paste(d$TITLE, d$text, sep = " "), 1, 3000))
rx <- function(stems) paste0("(?<![\\p{L}])(?:", paste(stems, collapse = "|"), ")")
SIGNALS <- list(
  # Study-local doctrine list. The canonical TEOLOGIJA_I_DOKTRINA stems include "moral", which also
  # matches the verb "morati" (moralo, morala, morali), so it is replaced by "moraln".
  nauk       = c("teologij", "teološk", "dogm", "eshatolog", "kristolog", "trojstv", "grijeh", "grijes",
                 "spasenj", "otkupljenj", "moraln", "katekizm", "nauk", "sakrament", "evanđelj",
                 "sveto pismo", "svetog pisma", "biblij", "uskrsnuć", "vječn\\p{L}* život", "milost\\p{L}* božj"),
  pismo      = c("sveto pismo", "svetog pisma", "biblij", "evanđelj", "psalm", "poslanic", "prorok", "starog zavjeta", "novog zavjeta"),
  uciteljstvo= c("katekizm", "enciklik", "koncil", "učiteljstv", "apostolsk\\p{L}* pobudnic", "dikasterij", "kanonsk\\p{L}* prav", "nauk crkve", "crkveni nauk", "socijalni nauk"),
  predaja    = c("crkven\\p{L}* ot", "svet\\p{L}* augustin", "tom\\p{L}* akvinsk", "predaj\\p{L}", "tradicij", "svetac", "svetic", "blaženik"),
  objava_priv= c("ukazanj", "gospin\\p{L}* poruk", "poruk\\p{L}* gospe", "međugorj", "vidjelic", "vidioc", "fatim", "lurd"),
  iskustvo   = c("svjedočanstv", "svjedoči", "obraćenj", "moje iskustvo", "osobno iskustvo", "moj život"),
  znanost    = c("znanstven", "znanost", "istraživanj", "studij\\p{L}* pokazuj"))
for (k in names(SIGNALS)) set(d, j = paste0("sig_", k), value = stri_detect_regex(low, rx(SIGNALS[[k]])))
rm(low); gc(verbose = FALSE)
d[, has_text := nchar(text) >= 200]

# ---- actor groups -----------------------------------------------------------------------------------
summ <- function(z) z[, .(posts = .N, sources = uniqueN(source_id), observed = sum(observed),
  interactions = sum(interactions, na.rm = TRUE),
  median = if (any(observed)) median(interactions, na.rm = TRUE) else NA_real_,
  mean = if (any(observed)) mean(interactions, na.rm = TRUE) else NA_real_,
  doctrine = mean(sig_nauk[has_text]))]
groups <- d[, summ(.SD), by = group][, label := GROUP_LABELS[group]]
group_platform <- d[, summ(.SD), by = .(group, platform = SOURCE_TYPE)]
group_platform[, `:=`(post_share = posts / sum(posts), int_share = interactions / sum(interactions)), by = platform]
signals <- d[has_text == TRUE, lapply(.SD, mean), by = group, .SDcols = patterns("^sig_")]
signals_secular <- d[has_text == TRUE & SOURCE_TYPE == "web", lapply(.SD, mean),
                     by = .(catholic = core), .SDcols = patterns("^sig_")]
fwrite(groups, file.path(TV_OUT, "groups.csv"), bom = TRUE)
fwrite(group_platform, file.path(TV_OUT, "group_platform.csv"), bom = TRUE)
fwrite(signals, file.path(TV_OUT, "signals_by_group.csv"), bom = TRUE)
fwrite(signals_secular, file.path(TV_OUT, "signals_web_catholic_vs_other.csv"), bom = TRUE)
cov <- d[core == TRUE, .(posts = .N, sources = uniqueN(source_id)), by = rule]
fwrite(cov, file.path(TV_OUT, "classification_rules.csv"), bom = TRUE)

# ---- per-source table and the named top 50 -------------------------------------------------------
pp <- if (file.exists(file.path(TV_PRIV, "person_posts.rds"))) readRDS(file.path(TV_PRIV, "person_posts.rds")) else NULL
by_source <- d[, .(posts = .N, observed = sum(observed), interactions = sum(interactions, na.rm = TRUE),
  median = if (any(observed)) median(interactions, na.rm = TRUE) else NA_real_,
  reach = sum(REACH, na.rm = TRUE), first = min(date), last = max(date),
  months = uniqueN(format(date, "%Y-%m")), posts_2025 = sum(year == 2025),
  doctrine = mean(sig_nauk[has_text]), pismo = mean(sig_pismo[has_text]),
  uciteljstvo = mean(sig_uciteljstvo[has_text]), predaja = mean(sig_predaja[has_text]),
  objava_priv = mean(sig_objava_priv[has_text]), iskustvo = mean(sig_iskustvo[has_text]),
  negative = mean(AUTO_SENTIMENT == "negative", na.rm = TRUE),
  positive = mean(AUTO_SENTIMENT == "positive", na.rm = TRUE),
  text_share = mean(has_text)), by = source_id]
by_source <- merge(by_source, s[, .(source_id, platform = SOURCE_TYPE, source, group, group_label, core, rule)], by = "source_id")
if (!is.null(pp)) {
  sp <- pp[statement == TRUE, .N, by = .(source_id, name)][order(-N)]
  top_voice <- sp[, .(top_voice = name[1], top_voice_posts = N[1], voices = .N), by = source_id]
  role_mix <- dcast(pp[statement == TRUE, .N, by = .(source_id, role)], source_id ~ role, value.var = "N", fill = 0)
  by_source <- merge(by_source, top_voice, by = "source_id", all.x = TRUE)
  by_source <- merge(by_source, role_mix, by = "source_id", all.x = TRUE)
}
setorder(by_source, -interactions, source_id)
by_source[, platform_rank := seq_len(.N), by = platform]
core <- by_source[core == TRUE & observed > 0 & interactions > 0]
core[, rank := seq_len(.N)]
core[, core_share := interactions / sum(interactions), by = platform]
top50 <- head(core, 50)
# Empty columns for the coding the requesting researcher proposed; filled later by model coding.
for (c in c("mandat", "teolosko_obrazovanje", "izvori_autoriteta", "teme", "ton", "napomena")) top50[, (c) := NA_character_]
fwrite(top50, file.path(TV_PRIV, "top50_katolicki_akteri.csv"), bom = TRUE)
fwrite(core[platform_rank <= 50 | rank <= 50], file.path(TV_PRIV, "top50_po_platformama.csv"), bom = TRUE)
all_top <- by_source[observed > 0][, rank_all := seq_len(.N)]
fwrite(head(all_top, 50), file.path(TV_PRIV, "top50_svi_izvori.csv"), bom = TRUE)
fwrite(by_source, file.path(TV_PRIV, "all_sources.csv"), bom = TRUE)

conc <- function(x) {x <- sort(x, decreasing = TRUE); tot <- sum(x)
  data.table(sources = length(x), interactions = tot, top1 = x[1] / tot, top5 = sum(head(x, 5)) / tot,
             top10 = sum(head(x, 10)) / tot, top50 = sum(head(x, 50)) / tot)}
concentration <- core[, conc(interactions), by = platform]
fwrite(concentration, file.path(TV_OUT, "concentration.csv"), bom = TRUE)
top50_platform_mix <- top50[, .(sources = .N, interactions = sum(interactions)), by = .(platform, group)]
fwrite(top50_platform_mix, file.path(TV_OUT, "top50_mix.csv"), bom = TRUE)

# ---- echo: the same story on several web sources --------------------------------------------------
w <- d[SOURCE_TYPE == "web", .(row = .I, date, key, core, sig_nauk, title = TITLE)]
w[, tkey := tv_title_key(title)]
w <- w[nchar(tkey) >= 30]
st <- w[, .(posts = .N, sources = uniqueN(key), catholic_sources = uniqueN(key[core]),
            other_sources = uniqueN(key[!core]), span_days = as.integer(max(date) - min(date)),
            first_key = key[which.min(date)]), by = tkey]
st <- st[span_days <= 14]
echo <- data.table(web_posts_titled = nrow(w), stories = nrow(st),
  posts_in_multi = st[sources >= 2, sum(posts)], stories_multi = st[sources >= 2, .N],
  largest = st[, max(sources)])
fwrite(echo, file.path(TV_OUT, "echo_summary.csv"), bom = TRUE)
fwrite(st[sources >= 3][order(-sources)][1:200], file.path(TV_PRIV, "echo_top_stories.csv"), bom = TRUE)
origin <- st[sources >= 3, .N, by = first_key][order(-N)][1:25]
fwrite(origin, file.path(TV_PRIV, "echo_origin_sources.csv"), bom = TRUE)

meta <- list(corpus = attr(d, "corpus"), posts_after_dedup = n_posts,
  duplicates_removed = attr(d, "duplicates_removed"), core_posts = d[core == TRUE, .N],
  core_sources = d[core == TRUE, uniqueN(source_id)], all_sources = uniqueN(d$source_id),
  date_range = as.character(range(d$date)), generated = format(Sys.time(), tz = "UTC", usetz = TRUE))
write_json(meta, file.path(TV_OUT, "meta_sources.json"), auto_unbox = TRUE, pretty = TRUE)
saveRDS(d[, .(input_order, date, year, SOURCE_TYPE, source_id, key, group, core, secular, observed,
              interactions, has_text, sig_nauk, sig_pismo, sig_uciteljstvo, sig_predaja,
              sig_objava_priv, sig_iskustvo, sig_znanost)], file.path(TV_PRIV, "posts_signals.rds"))
print(groups); print(concentration); print(echo)
print(top50[, .(rank, platform, source, group, posts, interactions, median, top_voice)])
