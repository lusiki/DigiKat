# Stage 2: closed list of theological voices -> mentions (spomen) vs attributed statements (izjava).
# Unit: one post x one person. A mention is the full name (optionally one middle name) or, where the
# list allows it, a role cue + surname. A statement is a mention with a speech verb or a preaching /
# message marker within WIN characters on the same paragraph. Recognition is deliberately simple and
# NOT validated against hand coding (PI decision 2026-10-13); the report says so.
source("studies/theological-voices/00_common.R", encoding = "UTF-8")
suppressPackageStartupMessages(library(stringi))
d <- tv_load()
v <- fread("studies/theological-voices/voices.csv", encoding = "UTF-8")
stopifnot(!anyDuplicated(v$id))
WIN <- 110L

ROLE_CUES <- c(
  biskup    = "(?:kardinal|nadbiskup|biskup|nuncij)\\p{L}{0,3}|mons\\.|msgr\\.",
  svecenik  = "don|fra|vlč\\.|p\\.|pater|mons\\.|msgr\\.|velečasn\\p{L}{0,3}|svećenik\\p{L}{0,3}|župnik\\p{L}{0,3}|provincijal\\p{L}{0,3}",
  akademski = "prof\\.|profesor\\p{L}{0,4}|dr\\.|teolog\\p{L}{0,4}|teologinj\\p{L}{0,2}|dekan\\p{L}{0,3}|rektor\\p{L}{0,3}|don|fra|p\\.|mons\\.|s\\.",
  laik      = "teolog\\p{L}{0,4}|teologinj\\p{L}{0,2}|aktivist\\p{L}{0,4}|publicist\\p{L}{0,4}|novinar\\p{L}{0,3}|kolumnist\\p{L}{0,4}",
  redovnica = "s\\.|sestr\\p{L}{1,2}|časn\\p{L}{1,2}\\s+sestr\\p{L}{1,2}")

inflect <- function(w) {
  # Croatian names inflect on the end; a final vowel is replaced, a consonant is extended.
  if (grepl("[aeiou]$", w)) {
    stem <- sub(".$", "", w)
    if (nchar(stem) <= 3) paste0(stem, "(?:a|e|i|o|u|om|em|ja|ju|jem)") else paste0(stem, "\\p{L}{1,3}")
  } else paste0(w, "\\p{L}{0,3}")
}
NB <- "(?<![\\p{L}])"; NE <- "(?![\\p{L}])"
person_pattern <- function(r) {
  full <- paste0(NB, inflect(r$first), "\\s+(?:\\p{Lu}\\p{L}+\\s+)?", inflect(r$surname), NE)
  cue <- switch(r$cue, auto = ROLE_CUES[[r$role]], none = NA_character_, special = NA_character_, r$cue)
  if (!is.na(cue)) full <- paste0(full, "|", NB, "(?:", cue, ")\\s+", inflect(r$surname), NE)
  full
}
v[, pattern := vapply(seq_len(.N), function(i) if (cue[i] == "special") NA_character_ else person_pattern(v[i]), "")]

# Popes. "Sveti Otac" is dated to the pontificate; Lav before 8 May 2025 is almost always Leo XIII.
pope_rules <- list(
  franjo = list(p = "(?<![\\p{L}])pap\\p{L}{0,3}\\s+Franj\\p{L}{0,2}(?![\\p{L}])|Bergoglio\\p{L}{0,2}",
                ot = c("2021-01-01", "2025-04-21")),
  lav14 = list(p = "(?<![\\p{L}])pap\\p{L}{0,3}\\s+Lav\\p{L}{0,2}(?!\\s+XIII)(?![\\p{L}])|Prevost\\p{L}{0,2}|Leon\\p{L}{0,2}\\s+XIV",
                ot = c("2025-05-08", "2026-12-31"), from = "2025-05-08"),
  benedikt16 = list(p = "(?<![\\p{L}])pap\\p{L}{0,3}\\s+Benedikt\\p{L}{0,2}|Ratzinger\\p{L}{0,2}|Benedikt\\p{L}{0,2}\\s+XVI", ot = NULL))
OTAC <- "(?<![\\p{L}])Svet\\p{L}{0,2}\\s+Ot(?:ac|ca|cu|cem)(?![\\p{L}])"

SPEECH <- paste0("(?<![\\p{L}])(?:",
  "rekao|rekla|kazao|kazala|kaže|izjavio|izjavila|istaknuo|istaknula|ističe|naglasio|naglasila|naglašava|",
  "poručio|poručila|poručuje|objasnio|objasnila|objašnjava|pojasnio|pojasnila|upozorio|upozorila|upozorava|",
  "smatra|zaključio|zaključila|dodao|dodala|napisao|napisala|piše|odgovorio|odgovorila|pozvao|pozvala|poziva|",
  "podsjetio|podsjetila|podsjeća|propovijedao|propovijedala|govorio|govorila|govori|tumači|protumačio|",
  "homilij\\p{L}{1,2}|propovijed\\p{L}{0,2}|nagovor\\p{L}{0,2}|poruk\\p{L}{1,2}|pismo|pismu|intervju\\p{L}{0,2}|",
  "katehez\\p{L}{1,2}|riječima|kako je (?:rekao|rekla|istaknuo|istaknula)|prema riječima)(?![\\p{L}])")

hay <- paste(d$TITLE, d$text, sep = "\n")
hay[is.na(hay)] <- ""

find_person <- function(pattern, idx = seq_along(hay)) {
  if (!length(idx)) return(data.table(row = integer(), statement = logical()))
  loc <- stri_locate_all_regex(hay[idx], pattern, omit_no_match = TRUE)
  has <- lengths(loc) > 0 & vapply(loc, function(m) nrow(m) > 0, logical(1))
  rows <- idx[has]; loc <- loc[has]
  stmt <- vapply(seq_along(rows), function(j) {
    h <- hay[rows[j]]; m <- loc[[j]]; n <- nchar(h)
    any(vapply(seq_len(nrow(m)), function(k) {
      w <- stri_sub(h, max(1L, m[k, 1] - WIN), min(n, m[k, 2] + WIN))
      # Restrict the window to the paragraph holding the name.
      rel <- m[k, 1] - max(1L, m[k, 1] - WIN) + 1L
      parts <- stri_locate_all_fixed(w, "\n")[[1]]
      if (!is.na(parts[1, 1])) {
        before <- parts[parts[, 1] < rel, 1]; after <- parts[parts[, 1] > rel, 1]
        w <- stri_sub(w, if (length(before)) max(before) + 1L else 1L, if (length(after)) min(after) - 1L else -1L)
      }
      stri_detect_regex(w, SPEECH)
    }, logical(1)))
  }, logical(1))
  data.table(row = rows, statement = stmt)
}

say("Matching", nrow(v), "voices")
res <- list()
for (i in seq_len(nrow(v))) {
  r <- v[i]
  if (r$cue == "special") {
    pr <- pope_rules[[r$id]]
    idx <- seq_along(hay)
    if (!is.null(pr$from)) idx <- idx[d$date[idx] >= as.IDate(pr$from)]
    hit <- find_person(pr$p, idx)
    if (!is.null(pr$ot)) {
      idx2 <- which(d$date >= as.IDate(pr$ot[1]) & d$date <= as.IDate(pr$ot[2]))
      idx2 <- setdiff(idx2, hit$row)
      hit <- rbind(hit, find_person(OTAC, idx2))
    }
  } else {
    pre <- stri_detect_fixed(hay, substr(r$surname, 1, max(4, nchar(r$surname) - 1)))
    hit <- find_person(r$pattern, which(pre))
  }
  if (nrow(hit)) res[[r$id]] <- hit[, id := r$id]
  if (i %% 10 == 0) say(i, "/", nrow(v))
}
pv <- rbindlist(res)
pv[, `:=`(date = d$date[row], year = d$year[row], platform = d$SOURCE_TYPE[row], group = d$group[row],
          core = d$core[row], secular = d$secular[row], source_id = d$source_id[row], url = d$URL[row])]
pv <- merge(pv, v[, .(id, name, role, zena)], by = "id")
saveRDS(pv, file.path(TV_PRIV, "person_posts.rds"))

ROLE_LABELS <- c(papa = "Pape", biskup = "Biskupi", svecenik = "Svećenici i redovnici",
  akademski = "Akademski teolozi", laik = "Laici, publicisti i aktivisti", redovnica = "Redovnice", vidjelac = "Vidioci")
per <- pv[, .(mentions = .N, statements = sum(statement), secular_mentions = sum(!core),
              secular_statements = sum(statement & !core), web_statements = sum(statement & platform == "web")),
          by = .(id, name, role, zena)][order(-statements)]
per[, ratio := mentions / pmax(statements, 1)]
per[, role_label := ROLE_LABELS[role]]
fwrite(per, file.path(TV_PRIV, "voices_summary.csv"), bom = TRUE)
by_role <- pv[, .(persons = uniqueN(id), mentions = .N, statements = sum(statement)), by = role]
by_role_src <- pv[statement == TRUE, .(statements = .N), by = .(role, catholic_source = core)]
by_role_year <- pv[statement == TRUE, .(statements = .N), by = .(role, year)]
by_person_year <- pv[statement == TRUE, .(statements = .N), by = .(id, name, role, year)]
fwrite(by_role, file.path(TV_OUT, "voices_by_role.csv"), bom = TRUE)
fwrite(by_role_src, file.path(TV_OUT, "voices_by_role_source.csv"), bom = TRUE)
fwrite(by_role_year, file.path(TV_OUT, "voices_by_role_year.csv"), bom = TRUE)
fwrite(by_person_year, file.path(TV_PRIV, "voices_by_person_year.csv"), bom = TRUE)

# Who is CALLED a theologian? Every name introduced by "teolog/teologinja" in the text.
say("Theologian label")
lab_pat <- "(?<![\\p{L}])(teolog|teologa|teologu|teologom|teologinj\\p{L}{1,2})\\s+(?:i\\s+\\p{L}+\\s+)?(\\p{Lu}\\p{Ll}+(?:[- ]\\p{Lu}\\p{Ll}+){1,2})"
lm <- stri_match_all_regex(hay, lab_pat)
lab <- rbindlist(lapply(seq_along(lm), function(i) {x <- lm[[i]]; if (is.na(x[1, 1])) NULL else
  data.table(row = i, cue = tolower(x[, 2]), name = x[, 3])}))
lab <- unique(lab, by = c("row", "name"))
lab[, `:=`(core = d$core[row], platform = d$SOURCE_TYPE[row], year = d$year[row], secular = d$secular[row])]
saveRDS(lab, file.path(TV_PRIV, "theologian_label_posts.rds"))
say("Theologian-label posts:", uniqueN(lab$row), "names:", uniqueN(lab$name))
print(per[1:40, .(name, role, mentions, statements, secular_statements)])
print(by_role)
