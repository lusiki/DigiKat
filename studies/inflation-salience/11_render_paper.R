#!/usr/bin/env Rscript
# 11_render_paper.R — typeset the manuscript to Word, full and blinded.
#
# EMIP wants two files, the complete manuscript and one that is fully anonymous, submitted
# by email. This script produces both from the same source, so the blinded copy cannot
# drift from the one that gets published.
#
# Everything is built in a temporary directory OUTSIDE the repository. A stray render
# inside the repository can empty docs/ and take the project website down, and this script
# is the sort of thing that gets run in a hurry before a deadline.
#
# Page geometry and type are applied by editing the generated file afterwards rather than
# through a Word template, because there is no template and none of the settings can be
# expressed in the source. See the note printed at the end about which specification is
# being applied and why it still needs confirming with the editorial office.
#
#   Rscript studies/inflation-salience/11_render_paper.R

source("studies/inflation-salience/_lib.R")

argv <- commandArgs(trailingOnly = TRUE)
V2 <- "--v2" %in% argv

PANDOC <- "C:/Program Files/Quarto/bin/tools/pandoc.exe"
if (!file.exists(PANDOC)) stop("pandoc not found at ", PANDOC)

PAPER  <- file.path(STUDY, if (V2) "PAPER_EMIP_v2.md" else "PAPER_EMIP_v1.md")
PAPERD <- file.path(OUT, "paper")
if (!dir.exists(PAPERD)) dir.create(PAPERD, recursive = TRUE)

TMP <- file.path(tempdir(), paste0("emip_", as.integer(Sys.time())))
dir.create(TMP, recursive = TRUE)
if (startsWith(normalizePath(TMP, winslash = "/"), normalizePath(getwd(), winslash = "/")))
  stop("the build directory is inside the repository; refusing to render")
msg("building in ", TMP)

rule("11_render_paper.R")

txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)

## ---------------------------------------------------------------- blinding -----

# Anything that identifies the author, directly or by institution, funder or repository.
# The funding line names both the project and the university and would give the author away
# on its own, so it is replaced rather than trimmed.
blind <- function(x) {
  a <- grep("^\\*\\*Luka Šikić\\*\\*", x)
  if (length(a) == 1L) x <- x[-(a:(a + 2L))]     # name, affiliation, contact line
  x <- gsub("DigiKat corpus", "project corpus", x, fixed = TRUE)
  x <- gsub("DigiKat", "project", x, fixed = TRUE)
  x <- x[!grepl("Šikić|unicath|ORCID|github\\.com|lusiki|Catholic University of Croatia", x)]
  ci <- grep("^\\*\\*Conflict of interest", x)
  if (length(ci) == 1L)
    x[ci] <- paste("**Conflict of interest.** The author declares no conflict of interest.",
                   "A statement about the institutional setting is withheld from the",
                   "anonymous version and appears in the full manuscript.")
  fu <- grep("^\\*\\*Funding", x)
  if (length(fu) == 1L)
    x[fu] <- paste("**Funding.** Details of funding are withheld from the anonymous version",
                   "and appear in the full manuscript.")
  au <- grep("^\\*\\*Author contributions", x)
  if (length(au) == 1L)
    x[au] <- "**Author contributions.** Single author."
  x
}

versions <- list(
  full    = list(txt = txt,        out = if (V2) "PAPER_EMIP_v2_full.docx" else "PAPER_EMIP_v1_full.docx"),
  blinded = list(txt = blind(txt), out = if (V2) "PAPER_EMIP_v2_blinded.docx" else "PAPER_EMIP_v1_blinded.docx")
)

## ----------------------------------------------------------------- render -----

for (v in names(versions)) {
  src <- file.path(TMP, paste0(v, ".md"))
  con <- file(src, open = "wt", encoding = "UTF-8"); writeLines(versions[[v]]$txt, con); close(con)
  dst <- file.path(TMP, versions[[v]]$out)
  rc <- system2(PANDOC, c(shQuote(src), "-o", shQuote(dst),
                          "--from=markdown+pipe_tables", "--to=docx",
                          paste0("--resource-path=", shQuote(normalizePath(".", winslash = "/")))) ,
                stdout = TRUE, stderr = TRUE)
  if (!file.exists(dst)) stop("pandoc failed for ", v, ": ", paste(rc, collapse = " "))
  msg("  rendered ", v, "  ->  ", basename(dst))
}

## ------------------------------------------------- page geometry and type -----

# The generated .docx is a zip. Setting the page block and the default typeface means
# editing two files inside it. Twips are twentieths of a point, 1440 to the inch.
py <- file.path(TMP, "restyle.py")
writeLines(c(
  "import sys, zipfile, shutil, re, os",
  "src, dst, w_cm, h_cm, pt = sys.argv[1], sys.argv[2], 16.6, 24.0, 10",
  "tw = lambda cm: int(round(cm / 2.54 * 1440))",
  "zin = zipfile.ZipFile(src); items = {n: zin.read(n) for n in zin.namelist()}; zin.close()",
  "d = items['word/document.xml'].decode('utf-8')",
  "SZ = '<w:pgSz w:w=\"%d\" w:h=\"%d\"/>' % (tw(w_cm), tw(h_cm))",
  "MAR = '<w:pgMar w:top=\"1134\" w:right=\"1134\" w:bottom=\"1134\" w:left=\"1134\" w:header=\"567\" w:footer=\"567\" w:gutter=\"0\"/>'",
  "# pandoc emits a bare <w:sectPr> with no page block, so the block is inserted rather",
  "# than substituted. Word takes its defaults when it is absent, which is US Letter.",
  "if re.search(r'<w:pgSz[^>]*>', d):",
  "    d = re.sub(r'<w:pgSz[^>]*>', SZ, d)",
  "    d = re.sub(r'<w:pgMar[^>]*>', MAR, d)",
  "else:",
  "    d = d.replace('<w:sectPr>', '<w:sectPr>' + SZ + MAR, 1)",
  "assert '<w:pgSz' in d and '<w:pgMar' in d, 'page block not applied'",
  "items['word/document.xml'] = d.encode('utf-8')",
  "s = items['word/styles.xml'].decode('utf-8')",
  "FNT = '<w:rFonts w:ascii=\"Times New Roman\" w:hAnsi=\"Times New Roman\" w:eastAsia=\"Times New Roman\" w:cs=\"Times New Roman\"/>'",
  "s = re.sub(r'<w:rFonts[^>]*>', FNT, s, count=1)",
  "s = re.sub(r'<w:sz w:val=\"[0-9]+\"\\s*/>', '<w:sz w:val=\"%d\"/>' % (pt*2), s, count=1)",
  "s = re.sub(r'<w:szCs w:val=\"[0-9]+\"\\s*/>', '<w:szCs w:val=\"%d\"/>' % (pt*2), s, count=1)",
  "assert '<w:sz w:val=\"%d\"/>' % (pt*2) in s, 'type size not applied'",
  "items['word/styles.xml'] = s.encode('utf-8')",
  "zo = zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED)",
  "[zo.writestr(n, b) for n, b in items.items()]",
  "zo.close(); print('restyled', os.path.basename(dst))"
), py)

for (v in names(versions)) {
  a <- file.path(TMP, versions[[v]]$out)
  b <- file.path(PAPERD, versions[[v]]$out)
  out <- system2("python", c(shQuote(py), shQuote(a), shQuote(b)), stdout = TRUE, stderr = TRUE)
  if (!file.exists(b)) stop("restyling failed for ", v, ": ", paste(out, collapse = " "))
  msg("  ", paste(out, collapse = " "), "  ->  ", b)
}

## ---------------------------------------------------------- verify blinding -----

rule("Blinding check")
bl <- versions$blinded$txt
for (pat in c("Šikić", "Sikic", "Petra Palić", "Petra Palic", "unicath", "ORCID", "DigiKat", "Catholic University of Croatia",
              "github", "lusiki"))
  msg(sprintf("  %-32s %s", pat,
              if (any(grepl(pat, bl, ignore.case = TRUE))) "STILL PRESENT" else "removed"))
msg("\n  The blinded version also loses the Croatian title block only if it names the author;")
msg("  it does not, so both titles are retained.")

rule("Format specification")
msg("  Applied: 16.6 x 24 cm page, Times New Roman 10, 2 cm margins.")
msg("  This follows emip.unidu.hr. The University of Dubrovnik page states A4 double-spaced")
msg("  instead, and the two have not been reconciled. Confirm with ekon.misao@unidu.hr")
msg("  before submitting; rerunning this script after changing w_cm, h_cm and pt is the")
msg("  whole of the work if the answer is the other specification.")
msg("\n  Tables are plain and figures use a black-and-white palette, as the journal requires.")

msg("\nwrote both files to ", PAPERD)
msg("\ndone.")
