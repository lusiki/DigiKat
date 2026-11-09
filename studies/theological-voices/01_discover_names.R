# Stage 1: discover candidate theological voices from role cues in the text.
# Output (private): candidates.csv, one row per cue class + inflected name form with post counts.
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
suppressPackageStartupMessages(library(stringi))
d <- tv_load()
say("Posts after duplicate handling:", nrow(d))
saveRDS(d[, !"text"], file.path(TV_PRIV, "posts_meta.rds"))

cue <- paste0("(?<![\\p{L}])(",
  "pap[aeiu]|papom|kardinal\\p{L}{0,3}|nadbiskup\\p{L}{0,3}|biskup\\p{L}{0,3}|mons\\.|msgr\\.|",
  "don|fra|vlč\\.|velečasn\\p{L}{0,3}|svećenik\\p{L}{0,3}|župnik\\p{L}{0,3}|",
  "teolog\\p{L}{0,4}|teologinj\\p{L}{0,2}|profesor\\p{L}{0,4}|prof\\.(?: dr\\.(?: ?sc\\.)?)?|dr\\. ?sc\\.|",
  "p\\.|otac|oca|ocem|pater|s\\.|sestr[aeiu]|sestrom|provincijal\\p{L}{0,3}|",
  "vidjelic\\p{L}{0,2}|vidioc\\p{L}{0,2}|vidjelac|propovjednik\\p{L}{0,3}|egzorcist\\p{L}{0,3}|",
  "katehet\\p{L}{0,4}|filozof\\p{L}{0,3}|aktivist\\p{L}{0,4}|predsjednic\\p{L}{0,2}|predsjednik\\p{L}{0,3}|ministr?\\p{L}{0,3}|premijer\\p{L}{0,3}",
  ")\\s+(\\p{Lu}\\p{Ll}+(?:[- ]\\p{Lu}\\p{Ll}+){0,2})")

say("Extracting cue + name pairs")
txt <- stri_sub(paste(d$TITLE, d$text, sep = " \n "), 1, 8000)
m <- stri_match_all_regex(txt, cue, opts_regex = stri_opts_regex(case_insensitive = FALSE))
hits <- rbindlist(lapply(seq_along(m), function(i) {
  x <- m[[i]]
  if (is.na(x[1, 1])) return(NULL)
  data.table(post = i, cue = tolower(x[, 2]), name = x[, 3])
}))
say("Pairs:", nrow(hits))
hits <- unique(hits)
hits[, cue_class := fcase(
  grepl("^pap", cue), "papa", grepl("^kardinal", cue), "kardinal", grepl("^nadbiskup", cue), "nadbiskup",
  grepl("^biskup", cue), "biskup", cue %in% c("mons.", "msgr."), "mons",
  cue %in% c("don", "fra", "vlč.", "p.", "otac", "oca", "ocem", "pater") | grepl("^velečasn|^svećenik|^župnik|^propovjednik|^egzorcist|^provincijal", cue), "svecenik_redovnik",
  cue == "s." | grepl("^sestr", cue), "sestra",
  grepl("^teolog", cue), "teolog", grepl("^prof|^dr\\.", cue), "akademski_naslov",
  grepl("^filozof", cue), "filozof", grepl("^katehet", cue), "katehet",
  grepl("^vid", cue), "vidjelac", grepl("^aktivist", cue), "aktivist",
  default = "politika")]
# Drop name tokens that are obviously not personal names (months, places in common cues, etc.).
stop_first <- c("Isus", "Krist", "Bog", "Gospa", "Duh", "Sveti", "Sveta", "Ivana", "Petra", "Pavla",
  "Hrvatske", "Republike", "Vlade", "Sabora", "Hrvatska", "Crkve", "Katoličke", "Zagreba", "Splita")
hits <- hits[!stri_extract_first_regex(name, "^\\p{L}+") %in% stop_first]
agg <- hits[, .(posts = uniqueN(post)), by = .(cue_class, name)][order(-posts)]
fwrite(agg[posts >= 5], file.path(TV_PRIV, "candidates.csv"), bom = TRUE)
say("Candidate forms with >=5 posts:", nrow(agg[posts >= 5]))
print(agg[, .SD[1:40], by = cue_class][!is.na(name)], nrows = 800)
