#!/usr/bin/env Rscript
# 14_v2_sheets.R — build the blind coding sheets for the v2 recoding (W1 and W2).
#
# PROPOSAL_EMIP_v2.md section 4. W1 splits the institution-register material by the object
# of its economic content (the institution's own costs and revenues against other people's
# hardship) and by whether a sector actor speaks. W2 tags the institutional unit on every
# post of the measured core. Nothing here selects new posts: both sheets are drawn from the
# 520 already coded in June 2026, so the fixed 1,450 pool is untouched.
#
# The annotator sees the same evidence as the June coding: date, outlet type, headline and
# an excerpt centred on the cost-of-living phrase. The excerpt here is ±500 characters
# rather than ±400, because the unit that acts is often named just outside the price
# sentence; the decision protocol is CODEBOOK.md's August 2026 addendum.
#
# Writes
#   output/private/v2_object_sheet.csv    179 institution-register items (object+voice+unit)
#   output/private/v2_unit_sheet.csv      the other 341 core items (unit only)
#   output/private/v2_key.csv             item -> rid map with the withheld June context
#   output/private/batches/v2/*.txt       annotator batch files
#
# Fixture check: 179 + 341 = 520, matching PAPER_EMIP_v1 Table 4.

source("studies/inflation-salience/_lib.R")

rule("14_v2_sheets.R")

coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
core  <- coded[domestic == 1L][order(rid)]
core[, item := sprintf("V%03d", seq_len(.N))]

m <- readRDS(MASTER)

## ------------------------------------------------------ join-key assertion -----

url_ok <- sum(!is.na(m$URL[core$rid]))
if (nrow(core) != 520L) stop("measured core is not 520 rows — do not proceed")

## --------------------------------------------------------- the excerpt -----

txt <- dk_text(m$TITLE[core$rid], m$FULL_TEXT[core$rid])
raw <- paste0(ifelse(is.na(m$TITLE[core$rid]), "", as.character(m$TITLE[core$rid])), " ",
              ifelse(is.na(m$FULL_TEXT[core$rid]), "", as.character(m$FULL_TEXT[core$rid])))
raw <- stri_replace_all_regex(raw, "[\\p{Zs}\\t\\r\\n]+", " ")

loc <- stri_locate_first_regex(txt, INFL_ANY)
ctr <- ifelse(is.na(loc[, 1]), 1L, as.integer((loc[, 1] + loc[, 2]) / 2))
excerpt <- stri_sub(raw, pmax(1L, ctr - 500L), pmin(nchar(raw), ctr + 500L))

sheet <- data.table(
  item        = core$item,
  register    = core$register,
  date        = format(core$date),
  outlet_type = core$otype,
  title       = m$TITLE[core$rid],
  excerpt     = excerpt
)

obj_sheet  <- sheet[register == "institution"][, register := NULL]
unit_sheet <- sheet[register != "institution"][, register := NULL]

rule("Fixture check — sheet sizes against PAPER_EMIP_v1 Table 4")
fixture_report("object sheet (institution register)", nrow(obj_sheet), 179L)
fixture_report("unit sheet (all other core posts)",   nrow(unit_sheet), 341L)
fixture_report("total, the measured core",            nrow(obj_sheet) + nrow(unit_sheet), 520L)

fwrite(obj_sheet,  file.path(PRIVATE, "v2_object_sheet.csv"))
fwrite(unit_sheet, file.path(PRIVATE, "v2_unit_sheet.csv"))
key <- core[, .(item, rid, register, response, date, year, month, stream, otype)]
fwrite(key, file.path(PRIVATE, "v2_key.csv"))
msg("\nwrote both sheets and ", file.path(PRIVATE, "v2_key.csv"))

## ------------------------------------------------------------- batches -----

BD <- file.path(PRIVATE, "batches", "v2")
if (!dir.exists(BD)) dir.create(BD, recursive = TRUE)

write_batches <- function(s, prefix, n_batches) {
  cuts <- sort(rep_len(seq_len(n_batches), nrow(s)))
  for (b in seq_len(n_batches)) {
    part <- s[cuts == b]
    lines <- unlist(lapply(seq_len(nrow(part)), function(i) c(
      paste0("### ", part$item[i]),
      paste0("DATE: ", part$date[i]),
      paste0("OUTLET TYPE: ", part$outlet_type[i]),
      paste0("TITLE: ", part$title[i]),
      paste0("EXCERPT: ", part$excerpt[i]),
      ""
    )))
    f <- file.path(BD, sprintf("%s%d.txt", prefix, b))
    con <- file(f, open = "wt", encoding = "UTF-8"); writeLines(lines, con); close(con)
    msg("  wrote ", f, "  (", nrow(part), " items)")
  }
}

write_batches(obj_sheet,  "obj",  2L)
write_batches(unit_sheet, "unit", 3L)

msg("\nAnnotator label files go to ", BD, "/a{1,2,3}/labels_<batch>.csv")
msg("(three independent runs; majority adjudication in 15_v2_ingest.R)")
msg("\ndone.")
