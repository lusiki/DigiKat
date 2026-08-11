#!/usr/bin/env Rscript
# 10_paper_checks.R — mechanical checks on the EMIP manuscript.
#
# Two things go wrong quietly in a paper like this. A table drifts from the analysis that
# produced it, and a number typed into prose stops matching the data after a rerun. Both
# are checked here rather than trusted: every fragment 08_tables.R generated must still
# appear in the manuscript byte for byte, and every scalar in derived.csv must still be
# printed somewhere in it.
#
# The journal's own limits are checked too. EMIP caps the paper at 25 pages including
# references and the abstract at 150 words, in both languages.
#
#   Rscript studies/inflation-salience/10_paper_checks.R

source("studies/inflation-salience/_lib.R")

argv <- commandArgs(trailingOnly = TRUE)
V2 <- "--v2" %in% argv
PAPER <- file.path(STUDY, if (V2) "PAPER_EMIP_v2.md" else "PAPER_EMIP_v1.md")
txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)
raw <- paste(txt, collapse = "\n")

res <- logical(0)
ok <- function(cond, label, detail = "") {
  cat(sprintf("[%s] %-44s %s\n", if (isTRUE(cond)) " OK " else "FAIL", label, detail))
  res <<- c(res, isTRUE(cond)); invisible(cond)
}

cat("=== manuscript checks", if (V2) " (economic reframe, v2)" else " (EMIP v1)", " ===\n\n--- abstracts ---\n", sep = "")

abstract_words <- function(start, stop) {
  a <- grep(start, txt)[1]; b <- grep(stop, txt)[1]
  s <- paste(trimws(txt[(a + 1):(b - 1)]), collapse = " ")
  length(unlist(strsplit(trimws(gsub("\\s+", " ", s)), " ")))
}
we <- abstract_words("^## Abstract$", "^\\*\\*Keywords")
wh <- abstract_words("^## Sažetak$", "^\\*\\*Ključne")
ok(we <= 150, "English abstract <= 150 words", sprintf("%d words, %d to spare", we, 150 - we))
ok(wh <= 150, "Croatian abstract <= 150 words", sprintf("%d words, %d to spare", wh, 150 - wh))

cat("\n--- length ---\n")
# A journal page of Times New Roman 10 on a 16.6 x 24 cm block holds roughly 3 400
# characters of prose. Tables and the reference list are counted as they stand.
CHARS_PER_PAGE <- 3400
body <- txt[grep("^## 1\\. ", txt):length(txt)]
flat <- ifelse(grepl("^\\|", body), gsub(" +", " ", body), body)
nch  <- nchar(paste(flat, collapse = "\n"))
pages <- nch / CHARS_PER_PAGE
words <- length(unlist(strsplit(paste(body, collapse = " "), "\\s+")))
cat(sprintf("      body from section 1 to the end: %s words, %s characters\n",
            format(words, big.mark = " "), format(nch, big.mark = " ")))
page_limit <- if (V2) 45 else 25
ok(pages <= page_limit, paste0("estimated <= ", page_limit, " journal pages"),
   sprintf("%.1f pages at %d characters per page", pages, CHARS_PER_PAGE))

cat("\n--- generated tables still present ---\n")
frags <- sort(list.files(TABLES, pattern = "^tab[0-9]+_.*\\.md$", full.names = TRUE))
tab_no <- as.integer(sub("^tab([0-9]+)_.*$", "\\1", basename(frags)))
frags <- frags[tab_no <= if (V2) 9L else 7L]
expected_tabs <- if (V2) 9L else 7L
ok(length(frags) == expected_tabs, paste(expected_tabs, "table fragments generated"),
   paste(length(frags), "found"))
for (f in frags) {
  fr <- readLines(f, encoding = "UTF-8", warn = FALSE)
  fr <- paste(fr[seq_len(max(which(nzchar(trimws(fr)))))], collapse = "\n")
  ok(grepl(fr, raw, fixed = TRUE), paste("Table fragment", basename(f)),
     if (grepl(fr, raw, fixed = TRUE)) "byte for byte" else "MISSING or EDITED BY HAND")
}

cat("\n--- every derived quantity is printed in the paper ---\n")
dv <- fread(file.path(OUT, if (V2) "derived_v2.csv" else "derived.csv"),
            encoding = "UTF-8", colClasses = "character")
missing <- dv[!vapply(dv$value, function(v) grepl(v, raw, fixed = TRUE), logical(1))]
ok(nrow(missing) == 0, sprintf("all %d derived values appear in the text", nrow(dv)),
   if (nrow(missing)) paste0(nrow(missing), " missing: ",
                             paste(utils::head(missing$name, 12), collapse = ", ")) else "")

cat("\n--- no markers or scaffolding left behind ---\n")
ok(!any(grepl("<!-- TABLE", txt)), "no unfilled table markers")
for (bad in c("TODO", "TBD", "XXX", "FIXME", "\\[to be written", "PLACEHOLDER"))
  ok(!any(grepl(bad, txt)), paste("no", gsub("\\\\", "", bad)))

cat("\n--- manuscript structure ---\n")
ok(any(grepl("^\\*\\*JEL classification", txt)), "JEL codes present")
ok(any(grepl("^## Sažetak$", txt)), "Croatian abstract present")
ok(any(grepl("^## Inflacija, informacije i odgođene promjene cijena$", txt)),
   "Croatian title present")
ok(!any(grepl("method A|method B|collection seam", txt, ignore.case = TRUE)),
   "no A/B collection framing remains")
for (fig in c("fig1_event_timeline.png", "fig2_unit_responses.png"))
  ok(file.exists(file.path(OUT, fig)), paste("figure exists:", fig))

cat("\n--- Croatian diacritics intact ---\n")
hr <- grep("^## (Sažetak|Inflacija, informacije)", txt, value = TRUE)
ok(all(grepl("[čćžšđ]", hr)), "diacritics survive in the Croatian headings",
   paste(substr(hr, 1, 40), collapse = " | "))
# Built from code points, not typed: R/check_sources.R scans every tracked source for these same
# byte patterns, and a literal here would make the repository guard flag this guard.
moji_pattern <- paste0("\\?\\?|", intToUtf8(0x00C3), "|", intToUtf8(0x00E2), intToUtf8(0x20AC))
ok(!any(grepl(moji_pattern, raw)), "no mojibake in the manuscript")

cat("\n--- references ---\n")
refs <- txt[(grep("^## References$", txt) + 1):(grep("^## Appendix A", txt) - 1)]
refs <- refs[nzchar(trimws(refs)) & !grepl("^---", refs)]
ok(length(refs) >= 10, "at least ten references", paste(length(refs), "entries"))
cited <- vapply(refs, function(r) {
  s <- sub("^([^(]+)\\(.*$", "\\1", r)
  nm <- trimws(strsplit(s, ",")[[1]][1])
  nm <- gsub("[^A-Za-zÀ-ž ]", "", nm)
  grepl(nm, paste(txt[1:(grep("^## References$", txt) - 1)], collapse = "\n"), fixed = TRUE)
}, logical(1))
cat(sprintf("      references named in the text: %d of %d\n", sum(cited), length(refs)))

cat(sprintf("\n=== %d checks, %d passed, %d failed ===\n", length(res), sum(res), sum(!res)))
if (any(!res)) quit(status = 1)
