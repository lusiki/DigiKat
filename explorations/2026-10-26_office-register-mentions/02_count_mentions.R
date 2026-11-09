# Count corpus documents that mention each person in the Wikidata office register.
# A mention = the person's FULL name (Croatian case endings allowed, one optional middle name);
# surname-only and title-only references ("nadbiskup", "Sveti Otac") are NOT counted, so counts
# are lower bounds. Popes use dated patterns from studies/theological-voices/02_voices.R.
# Read-only on the corpus; writes only to this exploration's output/.
# Regexes are R raw strings r"---(...)---" so each backslash is written once.
# Run from the repo root:
#   Rscript --vanilla explorations/2026-10-26_office-register-mentions/02_count_mentions.R
suppressPackageStartupMessages({ library(data.table); library(stringi) })
t0 <- Sys.time(); say <- function(...) cat(format(Sys.time(), "%H:%M:%S"), ..., "\n")
ex <- "explorations/2026-10-26_office-register-mentions"
man <- jsonlite::fromJSON("data/digikat_corpus_manifest.json")
x <- readRDS(man$corpus$path); setDT(x)
stopifnot(nrow(x) == man$corpus$rows)
say("corpus rows", nrow(x))
x <- x[, .(DATE = as.Date(DATE), FROM, SOURCE_TYPE, year,
           txt = paste(fifelse(is.na(TITLE), "", TITLE), fifelse(is.na(FULL_TEXT), "", FULL_TEXT), sep = "\n"))]
x[, txt := stri_replace_all_regex(txt, r"---([\x{FFFE}\x{FFFF}])---", "")]
invisible(gc())

say("indexing capitalised words")
cap <- stri_extract_all_regex(x$txt, r"---(\p{Lu}\p{L}+)---", omit_no_match = TRUE)
tok <- unique(data.table(doc = rep.int(seq_along(cap), lengths(cap)), w = unlist(cap, use.names = FALSE)))
rm(cap); invisible(gc())
setkey(tok, w); uw <- unique(tok$w)
say("index rows", nrow(tok), "distinct words", length(uw))

reg <- fread(file.path(ex, "output/register_people.tsv"), sep = "\t", quote = "", encoding = "UTF-8")
esc <- function(s) paste0(r"---(\Q)---", s, r"---(\E)---")
ROMAN <- r"---(^[IVXLC]+\.?$)---"
L03 <- r"---(\p{L}{0,3})---"; L13 <- r"---(\p{L}{1,3})---"
# Same inflection rule as the first theological-voices study (02_voices.R).
inflect <- function(w) {
  if (stri_detect_regex(w, ROMAN)) return(paste0(esc(stri_replace_last_fixed(w, ".", "")), r"---(\.?)---"))
  if (!stri_detect_regex(w, r"---(^\p{Lu})---")) return(esc(w))
  if (stri_detect_regex(w, "[aeiou]$")) {
    stem <- stri_sub(w, 1, -2)
    if (stri_length(stem) <= 3) paste0(esc(stem), "(?:a|e|i|o|u|om|em|ja|ju|jem)") else paste0(esc(stem), L13)
  } else paste0(esc(w), L03)
}
stem_of <- function(w) if (stri_detect_regex(w, "[aeiou]$") && stri_length(w) > 4) stri_sub(w, 1, -2) else w
NB <- r"---((?<![\p{L}]))---"; NE <- r"---((?![\p{L}]))---"
SP <- r"---(\s+)---"; MID <- r"---(\s+(?:\p{Lu}\p{L}+\s+)?)---"

pope <- list(
  Q450675 = list(p = r"---((?i:pap\p{L}{0,3})\s+Franj\p{L}{0,2}(?![\p{L}])|Bergoglio\p{L}{0,2})---",
                 keys = c("Franj", "Bergoglio", "Pap"), from = as.Date(NA)),
  Q6109517 = list(p = r"---((?i:pap\p{L}{0,3})\s+Lav\p{L}{0,2}(?!\s+XIII)(?![\p{L}])|Prevost\p{L}{0,2}|Le(?:o|on|av)\p{L}{0,2}\s+XIV)---",
                  keys = c("Lav", "Prevost", "Leo", "Pap"), from = as.Date("2025-05-08")))

docs_with_prefix <- function(keys) {
  words <- uw[Reduce(`|`, lapply(keys, function(k) stri_startswith_fixed(uw, k)))]
  if (!length(words)) integer() else unique(tok[.(words), doc, nomatch = 0L])
}

PLATFORMS <- sort(unique(x$SOURCE_TYPE))
x[, plat := fifelse(SOURCE_TYPE %in% c("web", "facebook", "youtube"), SOURCE_TYPE, "ostalo")]
out <- vector("list", nrow(reg))
say("matching", nrow(reg), "people")
for (i in seq_len(nrow(reg))) {
  r <- reg[i]; note <- ""
  clean <- stri_trim_both(stri_replace_all_regex(r$name, r"---(\s*\(.*\))---", ""))
  toks <- stri_split_regex(clean, SP)[[1]]
  if (r$qid %in% names(pope)) {
    pp <- pope[[r$qid]]; cand <- docs_with_prefix(pp$keys); pat <- pp$p; note <- "papa: datirani uzorak"
  } else if (length(toks) < 2) {
    out[[i]] <- data.table(qid = r$qid, n_docs = NA_integer_, note = "jednočlano ime, nije brojano"); next
  } else {
    named <- toks[!stri_detect_regex(toks, ROMAN)]
    cand <- intersect(docs_with_prefix(stem_of(tail(named, 1))), docs_with_prefix(stem_of(toks[1])))
    parts <- vapply(toks, inflect, "")
    pat <- if (length(toks) == 2) paste0(NB, parts[1], MID, parts[2], NE)
           else paste0(NB, paste(parts, collapse = SP), NE)
  }
  hit <- if (length(cand)) cand[stri_detect_regex(x$txt[cand], pat)] else integer()
  if (r$qid %in% names(pope) && !is.na(pope[[r$qid]]$from)) hit <- hit[x$DATE[hit] >= pope[[r$qid]]$from]
  h <- x[hit]
  row <- data.table(qid = r$qid, n_docs = length(hit),
    web = sum(h$plat == "web"), facebook = sum(h$plat == "facebook"), youtube = sum(h$plat == "youtube"),
    ostalo = sum(h$plat == "ostalo"), izvora = uniqueN(h$FROM),
    prvi = if (length(hit)) as.character(min(h$DATE)) else NA_character_,
    zadnji = if (length(hit)) as.character(max(h$DATE)) else NA_character_, note = note)
  for (y in 2021:2026) set(row, j = paste0("g", y), value = sum(h$year == y))
  for (p in PLATFORMS) set(row, j = paste0("p_", p), value = sum(h$SOURCE_TYPE == p))
  out[[i]] <- row
  if (i %% 200 == 0) say(i, "done")
}
res <- merge(reg, rbindlist(out, fill = TRUE), by = "qid", sort = FALSE)
dup <- res[, .N, by = name][N > 1, name]
res[name %in% dup, note := stri_trim_both(paste(note, "isto ime ima više osoba u registru"))]
setorder(res, -n_docs, name, na.last = TRUE)
res[, rang := fifelse(is.na(n_docs), NA_integer_, seq_len(.N))]
setcolorder(res, c("rang", "name", "n_docs", "izvora", "web", "facebook", "youtube", "ostalo",
  paste0("g", 2021:2026), "prvi", "zadnji", "alive", "catholic_office", "description", "offices", "qid", "note"))
fwrite(res, file.path(ex, "output/register_mentions.csv"), bom = TRUE)
say("written", nrow(res), "rows; people with >=1 document:", sum(res$n_docs > 0, na.rm = TRUE),
    "; elapsed", round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), "min")
