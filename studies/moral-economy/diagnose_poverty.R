#!/usr/bin/env Rscript
# Diagnostic: WHY is poverty_social an outlier (linkage 0.62, confessional 0.60)?
# Pulls the actual ±220-char windows around the poverty match, with the religion term shown,
# for a hand-eyeball sample — so we can categorize the mechanism BEFORE trusting any downstream
# number. READ-ONLY; writes only studies/moral-economy/output/private/poverty_diagnosis_sample.csv.
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr) })

src <- here::here("data/merged_comprehensive.rds")
if (!file.exists(src)) stop("Need the master. See CLAUDE.local.md.")
out_dir <- here::here("studies/moral-economy/output")
private_dir <- file.path(out_dir, "private")
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

# v2 poverty regex + religion probe (kept in sync with probe.R v2)
poverty_rx <- "siroma[sš]|socijaln\\w+\\s+(pomo[cć]|skrb|ugro[zž]en)|be[sz]ku[cć]ni|\\bovrh|ovr[sš]n|du[zž]ni[kc]\\w*"
relig_core <- paste(
  "crkv", "katoli[cč]", "nadbiskup", "biskup", "sve[cć]en", "[zž]upn", "vatikan",
  "\\bpap[aeiu]\\b", "papinsk", "kr[sš][cć]an", "vjernik", "vjersk", "vjerou[cč]",
  "redovni[kc]", "redovnic", "[cč]asn\\w+\\s+sestr",
  "\\bmis(a|e|i|u|om|ama)\\b", "liturgij", "evan[dđ]elj", "hodo[cč]a[sš]", "krunic", "katedral",
  "biskupij", "nuncij", "enciklik", "sinod", "molitv", "blagoslov",
  "\\bisus\\w{0,4}\\b", "\\bkrist(a|u|om|e)?\\b", "\\bgosp(a|e|i|u|om)\\b", "stepinac", "duhovn",
  "teolo[sšg]", "sveti[sš]t", "samostan", "\\bfratr|\\bfra\\b", "\\bdon\\b",
  sep = "|")
caritas_rx <- "caritas|karitas"
relig_rx <- paste(relig_core, caritas_rx, sep = "|")
WINDOW <- 220

cat("Reading master...\n"); t0 <- Sys.time()
corpus <- readRDS(src)
if (inherits(corpus, "data.table")) data.table::setDF(corpus)
lowered <- str_to_lower(corpus$FULL_TEXT, locale = "hr")
cat(sprintf("  %d rows in %.1f min\n", nrow(corpus), as.numeric(difftime(Sys.time(), t0, "mins"))))

pov <- which(str_detect(lowered, regex(poverty_rx)) %in% TRUE)
cat("poverty_social matches:", length(pov), "\n")

# for each matched post, find whether a religion term is in-window, and capture ONE window + which
# religion token fired + whether it was ONLY caritas (religion-as-actor signature)
set.seed(20260707)
smp <- sample(pov, min(60, length(pov)))
rows <- lapply(smp, function(i) {
  txt <- lowered[i]
  locs <- str_locate_all(txt, regex(poverty_rx))[[1]]
  for (r in seq_len(nrow(locs))) {
    win <- str_sub(txt, max(1L, locs[r,1]-WINDOW), min(str_length(txt), locs[r,2]+WINDOW))
    rmatch <- str_extract(win, regex(relig_rx))
    if (!is.na(rmatch)) {
      only_caritas <- !str_detect(win, regex(relig_core))  # religion in-window is ONLY caritas/karitas
      return(data.frame(
        row = i,
        FROM = if ("FROM" %in% names(corpus)) corpus$FROM[i] else NA,
        pov_term = str_extract(win, regex(poverty_rx)),
        relig_term = rmatch, only_caritas = only_caritas,
        window = str_replace_all(win, "\\s+", " "), stringsAsFactors = FALSE))
    }
  }
  data.frame(row=i, FROM=if("FROM"%in%names(corpus)) corpus$FROM[i] else NA,
             pov_term=str_extract(txt, regex(poverty_rx)), relig_term=NA,
             only_caritas=NA, window="(no religion in window)", stringsAsFactors=FALSE)
})
res <- do.call(rbind, rows)
linked <- res[!is.na(res$relig_term), ]
write.csv(res, file.path(private_dir, "poverty_diagnosis_sample.csv"), row.names=FALSE, fileEncoding="UTF-8")

cat("\n== poverty_social linkage diagnosis (n sampled =", nrow(res),
    "; linked =", nrow(linked), ") ==\n")
cat("Religion tokens firing in-window (top):\n"); print(sort(table(linked$relig_term), decreasing=TRUE)[1:12])
cat("\nOnly-Caritas linkage (religion-as-actor):", sum(linked$only_caritas, na.rm=TRUE),
    "of", nrow(linked), "linked\n")
cat("\n-- 20 example windows (pov_term | relig_term | text) --\n")
for (k in seq_len(min(20, nrow(linked)))) {
  cat(sprintf("\n[%s | %s | onlyCaritas=%s]\n  ...%s...\n",
      linked$pov_term[k], linked$relig_term[k], linked$only_caritas[k],
      substr(linked$window[k], 1, 320)))
}
cat("\nRestricted full sample ->", file.path(private_dir, "poverty_diagnosis_sample.csv"), "\n")
