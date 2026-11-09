# Stage 4: draw the reviewed sample (pregledani uzorak) and write coding batches.
# Frame: posts on web / Facebook / YouTube with >= 400 characters of text and a doctrine keyword in
# the first 3 000 characters. Two strata of 150: Catholic sources (core groups) and all other
# sources. Strata are reported separately and never pooled without weights.
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
suppressPackageStartupMessages(library(stringi))
d <- tv_load()
sig <- readRDS(file.path(TV_PRIV, "posts_signals.rds"))
stopifnot(identical(sig$input_order, d$input_order))
d[, sig_nauk := sig$sig_nauk]
d[, tkey := tv_title_key(TITLE)]
story_size <- d[SOURCE_TYPE == "web" & nchar(tkey) >= 30, .(story_posts = .N, story_sources = uniqueN(key)), by = tkey]
frame <- d[SOURCE_TYPE %in% c("web", "facebook", "youtube") & nchar(text) >= 400 & sig_nauk == TRUE]
frame[, stratum := fifelse(core, "katolicki", "ostali")]
set.seed(20261013)
smp <- frame[, .SD[sample.int(.N, 150)], by = stratum]
smp <- merge(smp, story_size, by = "tkey", all.x = TRUE, sort = FALSE)
smp[is.na(story_posts), `:=`(story_posts = 1L, story_sources = 1L)]
smp[, sid := sprintf("U%03d", seq_len(.N))]
frame_n <- frame[, .N, by = stratum]
fwrite(frame_n, file.path(TV_OUT, "sample_frame.csv"), bom = TRUE)
keep <- smp[, .(sid, stratum, input_order, date, platform = SOURCE_TYPE, source = FROM, group, core,
                URL, title = TITLE, story_posts, story_sources, tkey)]
saveRDS(keep, file.path(TV_PRIV, "sample.rds"))
fwrite(keep[, !"URL"], file.path(TV_PRIV, "sample_index.csv"), bom = TRUE)

clean <- function(x) stri_replace_all_regex(stri_trim_both(x), "\\s+", " ")
batches <- split(smp, ceiling(seq_len(nrow(smp)) / 50))
dir.create(file.path(TV_PRIV, "coding"), showWarnings = FALSE)
for (b in seq_along(batches)) {
  z <- batches[[b]]
  lines <- vapply(seq_len(nrow(z)), function(i) toJSON(list(
    sid = z$sid[i], datum = as.character(z$date[i]), platforma = z$SOURCE_TYPE[i], izvor = z$FROM[i],
    naslov = clean(z$TITLE[i]), tekst = clean(stri_sub(z$text[i], 1, 2600))), auto_unbox = TRUE), "")
  writeLines(enc2utf8(lines), file.path(TV_PRIV, "coding", sprintf("batch_%d.jsonl", b)), useBytes = TRUE)
}
say("Sample:", nrow(smp), "posts in", length(batches), "batches; frame", paste(frame_n$stratum, frame_n$N, collapse = ", "))
