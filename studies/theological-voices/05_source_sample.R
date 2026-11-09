# Stage 5: evidence packets for model coding of the named top 50 sources (channel level).
# Six random posts with text per source (seeded), title + first 700 characters.
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
suppressPackageStartupMessages(library(stringi))
d <- tv_load()
top <- fread(file.path(TV_PRIV, "top50_katolicki_akteri.csv"), encoding = "UTF-8")
set.seed(20261014)
clean <- function(x) stri_replace_all_regex(stri_trim_both(fifelse(is.na(x), "", x)), "\\s+", " ")
lines <- vapply(seq_len(nrow(top)), function(i) {
  z <- d[source_id == top$source_id[i] & nchar(text) >= 150]
  if (!nrow(z)) z <- d[source_id == top$source_id[i]]
  z <- z[sample.int(.N, min(6L, .N))]
  toJSON(list(rank = top$rank[i], izvor = top$source[i], platforma = top$platform[i],
    skupina = top$group_label[i], objava = top$posts[i],
    primjeri = lapply(seq_len(nrow(z)), function(j) list(datum = as.character(z$date[j]),
      naslov = clean(z$TITLE[j]), tekst = clean(stri_sub(z$text[j], 1, 700))))), auto_unbox = TRUE)
}, "")
writeLines(enc2utf8(lines), file.path(TV_PRIV, "coding", "sources_top50.jsonl"), useBytes = TRUE)
say("Wrote", length(lines), "source packets")
