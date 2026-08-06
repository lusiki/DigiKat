#!/usr/bin/env Rscript
# 08_tables.R — generate every table in the manuscript, and every number quoted in prose.
#
# Ports the discipline the moral-economy study uses. Each table is written to
# output/tables/ as a markdown fragment; 09_sync_tables.R installs the fragments into the
# manuscript and 10_paper_checks.R fails the build unless each one still appears
# byte-for-byte and every scalar in derived.csv is still printed somewhere in the text.
# A number typed by hand into the paper therefore breaks the build instead of surviving.
#
# Reads only generated study outputs — never the master. With --v2, it also reads the
# outputs of 15 and 16 and adds Tables 8–9 plus derived_v2.csv.

source("studies/inflation-salience/_lib.R")

argv <- commandArgs(trailingOnly = TRUE)
V2 <- "--v2" %in% argv

rule("08_tables.R")

# header = TRUE is not redundant: sector_responses.csv has year numbers as column names and
# fread otherwise reads the header row as data and calls the columns V1 to V7.
R <- function(f) fread(file.path(OUT, f), encoding = "UTF-8", header = TRUE)
core   <- readRDS(file.path(PRIVATE, "coded_core.rds"))
resp   <- R("sector_responses.csv")
shares <- R("sector_shares.csv")
anchor <- R("sector_seam_free.csv")
bridge <- R("sector_bridge_2024.csv")
outl   <- R("sector_outlets.csv")
cors   <- R("instrument_correlations.csv")
thr    <- R("instrument_threshold.csv")
rob    <- R("instrument_robustness.csv")
ser    <- R("instrument_series.csv")
hicp   <- R("hicp_hr.csv")

have_reann <- file.exists(file.path(OUT, "reannotation_agreement.csv"))
if (have_reann) {
  agree <- R("reannotation_agreement.csv")
  disp  <- R("reannotation_disputed.csv")
}

if (V2) {
  need_v2 <- c("v2_agreement.csv", "v2_analysis_core.csv", "attention_object_monthly.csv",
               "unit_response.csv", "unit_matched_summary.csv",
               "unit_matched_by_type.csv", "event_summary.csv")
  miss_v2 <- need_v2[!file.exists(file.path(OUT, need_v2))]
  if (length(miss_v2)) stop("--v2 requires: ", paste(miss_v2, collapse = ", "))
  v2agree <- R("v2_agreement.csv")
  objmo   <- R("attention_object_monthly.csv")
  unitr   <- R("unit_response.csv")
  matchs  <- R("unit_matched_summary.csv")
  matcht  <- R("unit_matched_by_type.csv")
  event   <- R("event_summary.csv")
  v2full  <- R("v2_analysis_core.csv")
}

## ------------------------------------------------------------- helpers -----

DERIVED <- list()
D <- function(name, value, note = "") {
  DERIVED[[length(DERIVED) + 1L]] <<- data.table(name = name, value = as.character(value), note = note)
  invisible(value)
}
n_fmt <- function(x) formatC(x, big.mark = " ", format = "d")
p_fmt <- function(x, d = 1) formatC(round(x, d), format = "f", digits = d)

md_table <- function(file, caption, header, align, rows, source_note) {
  lines <- c(paste0("**", caption, "**"), "",
             paste0("| ", paste(header, collapse = " | "), " |"),
             paste0("|", paste0(align, collapse = "|"), "|"),
             rows, "",
             paste0("*Source: ", source_note, "*"))
  con <- file(file.path(TABLES, file), open = "wt", encoding = "UTF-8")
  writeLines(lines, con); close(con)
  msg("  wrote ", file.path(TABLES, file))
}

SRC_CORPUS <- paste0("author's calculations on the DigiKat corpus of ", n_fmt(710307),
                     " Croatian digital media posts, January 2021 to June 2026")

## --------------------------------------------- Table 1 — corpus to core -----

# Values are stored in the form the prose prints them, spaces and all, because that is what
# 10_paper_checks.R searches the manuscript for.
n_corpus <- 710307L;                                          D("n_corpus", n_fmt(n_corpus))
n_tag    <- nrow(readRDS(file.path(PRIVATE, "tagged_inflation.rds"))); D("n_tagged", n_fmt(n_tag))
n_cand   <- nrow(core);                                       D("n_candidates", n_fmt(n_cand))
n_link   <- D("n_linked", sum(core$linked))
n_for    <- D("n_foreign", sum(core$linked == 1L & core$c_foreign == 1L))
n_core   <- D("n_core", sum(core$domestic))
D("pct_tagged", p_fmt(100 * n_tag / n_corpus, 2))
D("pct_core_of_corpus", p_fmt(100 * n_core / n_corpus, 2))
D("pct_core_of_tagged", p_fmt(100 * n_core / n_tag, 1))
D("pct_candidates_surviving", p_fmt(100 * n_link / n_cand, 0))

f1 <- c(
  sprintf("| All posts in the corpus | %s | %s |", n_fmt(n_corpus), "100.00"),
  sprintf("| Mention the cost of living | %s | %s |", n_fmt(n_tag), p_fmt(100 * n_tag / n_corpus, 2)),
  sprintf("| Selected for coding, religion near the mention | %s | %s |", n_fmt(n_cand), p_fmt(100 * n_cand / n_corpus, 2)),
  sprintf("| Coded as a genuine connection | %s | %s |", n_fmt(n_link), p_fmt(100 * n_link / n_corpus, 2)),
  sprintf("| ... about another country's inflation | %s | %s |", n_fmt(n_for), p_fmt(100 * n_for / n_corpus, 2)),
  sprintf("| **... about Croatian inflation (the measured set)** | **%s** | **%s** |", n_fmt(n_core), p_fmt(100 * n_core / n_corpus, 2))
)
md_table("tab1_funnel.md",
         "Table 1. From the whole corpus to the set of posts actually measured.",
         c("Stage", "Posts", "% of corpus"), c(" --- ", " ---: ", " ---: "), f1,
         paste0(SRC_CORPUS, ". Posts are selected by a keyword filter and then read and coded ",
                "one by one; only ", p_fmt(100 * n_link / n_cand, 0),
                "% of the posts the filter selects turn out to connect religion to prices at all. ",
                "The first two rows are produced by the current code. The set of ", n_fmt(n_cand),
                " posts sent for coding was fixed when the coding was done and is carried forward ",
                "unchanged, so the third row is that fixed set rather than a fresh selection; ",
                "the appendix reports how closely a fresh selection reproduces it."))

## ------------------------------------------- Table 2 — three responses -----

ORD <- c("Public voice", "Repricing", "Charitable response", "Normative response")
yrs <- as.character(2021:2026)
setkey(resp, response)
rmat <- as.matrix(resp[ORD, yrs, with = FALSE])
rownames(rmat) <- ORD
f2 <- vapply(ORD, function(r) sprintf("| %s | %s |", r, paste(rmat[r, ], collapse = " | ")),
             character(1))
md_table("tab2_responses.md",
         "Table 2. How the religious sector responded, by year.",
         c("Response", yrs), rep(" ---: ", 7) |> (\(x) {x[1] <- " --- "; x})(),
         f2,
         paste0(SRC_CORPUS, ". The 2026 column covers January to June."))

for (r in ORD) {
  slug <- gsub("[^a-z]", "", tolower(r))
  for (y in yrs) D(paste0("resp_", slug, "_", y), rmat[r, y])
  D(paste0("peak_year_", slug), yrs[which.max(rmat[r, ])])
  D(paste0("peak_n_",    slug), max(rmat[r, ]))
}

## --------------------------------------- Table 3 — the seam-free anchor -----

f3 <- sprintf("| %d | %d | %d | %s |", anchor$year, anchor$voice, anchor$repricing,
              p_fmt(anchor$repricing_share, 1))
md_table("tab3_anchor.md",
         "Table 3. Public voice and repricing during the main inflation shock.",
         c("Year", "Speaking out", "Repricing", "Repricing as % of the two"),
         c(" --- ", " ---: ", " ---: ", " ---: "), f3,
         paste0(SRC_CORPUS, ", restricted to 2021–2023."))
D("anchor_2022_share", p_fmt(anchor[year == 2022]$repricing_share, 1))
D("anchor_2023_share", p_fmt(anchor[year == 2023]$repricing_share, 1))
D("anchor_2022_voice", anchor[year == 2022]$voice)
D("anchor_2022_repricing", anchor[year == 2022]$repricing)
D("anchor_2023_voice", anchor[year == 2023]$voice)
D("anchor_2023_repricing", anchor[year == 2023]$repricing)

## ------------------------------- Table 4 — what the sector's economics is about -----

reg_lab <- c(crl = "The price of religious services", institution = "The sector as an economic actor",
             charity = "Charitable relief", devotional = "Devotional", justice = "Who bears the burden",
             disputed = "Unresolved", other = "Other")
cc <- core[domestic == 1L]
f4 <- vapply(names(reg_lab), function(r) {
  n <- sum(cc$register == r)
  o <- outl[register == r]
  sec <- if (nrow(o)) o[["Secular/other"]] else 0L
  cat_ <- if (nrow(o)) o[["Catholic"]] else 0L
  bus <- if (nrow(o)) o[["Business"]] else 0L
  D(paste0("reg_n_", r), n); D(paste0("reg_pct_", r), p_fmt(100 * n / nrow(cc), 1))
  sprintf("| %s | %d | %s | %d | %d | %d |", reg_lab[[r]], n, p_fmt(100 * n / nrow(cc), 1), sec, cat_, bus)
}, character(1))
md_table("tab4_register.md",
         "Table 4. What the posts are about, and who published them.",
         c("Subject of the post", "Posts", "%", "Secular outlet", "Catholic outlet", "Business press"),
         c(" --- ", " ---: ", " ---: ", " ---: ", " ---: ", " ---: "), f4,
         paste0(SRC_CORPUS, ", the ", n_fmt(nrow(cc)), " posts about Croatian inflation in which ",
                "religion is genuinely involved. Deciding which of these a post is about was the ",
                "least reliable of the four coding judgements, so the two largest categories ",
                "should be read together rather than ranked against each other."))
D("n_secular", sum(cc$otype == "Secular/other"))
D("n_catholic", sum(cc$otype == "Catholic"))
D("pct_secular", p_fmt(100 * sum(cc$otype == "Secular/other") / nrow(cc), 0))
D("pct_catholic", p_fmt(100 * sum(cc$otype == "Catholic") / nrow(cc), 0))
D("macro_economic_object", sum(cc$register %in% c("crl", "institution")))
D("macro_economic_object_pct", p_fmt(100 * sum(cc$register %in% c("crl", "institution")) / nrow(cc), 0))

## --------------------------------------- Table 5 — the instrument check -----

wins <- ser[, .(months = .N, first = min(month), last = max(month),
                hicp_min = min(hicp_headline), hicp_max = max(hicp_headline),
                hicp_sd = sd(hicp_headline)), by = stream]
f5 <- vapply(c("monitoring", "backfill"), function(s) {
  w <- wins[stream == s]; cc2 <- cors[stream == s]; th <- thr[stream == s][1]
  sprintf("| %s | %s to %s | %d | %s to %s | %s | %s | %s | %s |",
          if (s == "monitoring") "2021-01 to 2024-06" else "2024-07 to 2026-06",
          w$first, w$last, w$months, p_fmt(w$hicp_min, 1), p_fmt(w$hicp_max, 1),
          p_fmt(cc2[component == "headline"]$pearson, 2),
          p_fmt(cc2[component == "food"]$pearson, 2),
          p_fmt(cc2[component == "energy"]$pearson, 2),
          p_fmt(th$ratio, 2))
}, character(1))
md_table("tab5_instrument.md",
         "Table 5. Does coverage of the cost of living track actual prices?",
         c("Period", "Months covered", "N", "Inflation ranged from", "All items",
           "Food", "Energy", "Above vs below 4%"),
         c(" --- ", " --- ", " ---: ", " ---: ", " ---: ", " ---: ", " ---: ", " ---: "), f5,
         paste0("author's calculations; Croatian HICP annual rate of change from Eurostat ",
                "(prc_hicp_minr, all items, food and non-alcoholic beverages, energy), retrieved ",
                "5 August 2026. Figures are correlations between the monthly share of corpus posts ",
                "mentioning the cost of living and each price series. The last column is mean ",
                "coverage in months when inflation was at or above 4% divided by mean coverage ",
                "below it."))
for (s in c("monitoring", "backfill")) for (cn in c("headline", "food", "energy"))
  D(paste0("r_", s, "_", cn), p_fmt(cors[stream == s & component == cn]$pearson, 2))
for (s in c("monitoring", "backfill")) {
  D(paste0("months_", s), wins[stream == s]$months)
  D(paste0("hicpmin_", s), p_fmt(wins[stream == s]$hicp_min, 1))
  D(paste0("hicpmax_", s), p_fmt(wins[stream == s]$hicp_max, 1))
  D(paste0("hicpsd_", s), p_fmt(wins[stream == s]$hicp_sd, 2))
  D(paste0("thr_below_", s), p_fmt(thr[stream == s][1]$below_4, 2))
  D(paste0("thr_above_", s), p_fmt(thr[stream == s][1]$at_or_above_4, 2))
  D(paste0("thr_ratio_", s), p_fmt(thr[stream == s][1]$ratio, 2))
}

## ------------------------------------------- Table 6 — robustness -----

spec_lab <- c("levels, Newey-West" = "Levels, with standard errors robust to trend and persistence",
              "first differences" = "Month-on-month changes only",
              "negative binomial, volume offset" = "Post counts, allowing for how much was collected")
f6 <- apply(rob, 1, function(r) sprintf("| %s | %s | %s | %s | %s | %s |",
       if (r[["stream"]] == "monitoring") "2021-01 to 2024-06" else "2024-07 to 2026-06",
       spec_lab[[r[["spec"]]]], r[["n"]], r[["estimate"]], r[["se"]], r[["t"]]))
md_table("tab6_robustness.md",
         "Table 6. The same relationship under three different specifications.",
         c("Period", "Specification", "N", "Estimate", "Standard error", "t"),
         c(" --- ", " --- ", " ---: ", " ---: ", " ---: ", " ---: "), unname(f6),
         paste0("author's calculations. The dependent variable is the monthly share of corpus posts ",
                "mentioning the cost of living, except in the third specification, where it is the ",
                "monthly count with the log of total posts entered as an offset. ",
                "Month-on-month changes use consecutive observed months only."))
for (i in seq_len(nrow(rob)))
  D(paste0("rob_", substr(rob$stream[i], 1, 3), "_", gsub("[^a-z]", "", tolower(rob$spec[i])), "_t"),
    p_fmt(rob$t[i], 2))

## --------------------------------------- Table 7 — coding reliability -----

if (have_reann) {
  f7 <- sprintf("| %s | %d | %s | %s |", agree$axis, agree$n,
                p_fmt(agree$agreement, 3), ifelse(is.na(agree$kappa), "n/a", p_fmt(agree$kappa, 3)))
  md_table("tab7_reliability.md",
           "Table 7. Agreement between the original coding and an independent recoding.",
           c("Judgement", "Items", "Agreement", "Kappa"),
           c(" --- ", " ---: ", " ---: ", " ---: "), f7,
           paste0("author's calculations on a stratified sample of ", sum(agree$n[1]),
                  " posts independently recoded from the same written protocol with the original ",
                  "labels withheld."))
  for (i in seq_len(nrow(agree))) {
    slug <- gsub("[^a-z]", "", tolower(agree$axis[i]))
    D(paste0("agree_", slug), p_fmt(agree$agreement[i], 3))
    D(paste0("kappa_", slug), if (is.na(agree$kappa[i])) "n/a" else p_fmt(agree$kappa[i], 3))
  }
  D("n_reannotated", sum(agree$n[1]))
  D("n_disputed", nrow(disp))
  D("n_disputed_resolved", sum(disp$reannotation != "disputed"))
} else {
  msg("  (re-annotation results not present yet — Table 7 skipped)")
}

## -------------------------- Tables 8–9 — v2 attention object and units -----

if (V2) {
  obj <- v2full[register == "institution"]
  obj_levels <- c("own", "household", "both", "other")
  obj_labels <- c(own = "The sector's own costs or revenue",
                  household = "Household hardship",
                  both = "Both own position and household hardship",
                  other = "Other economic subject")
  f8 <- vapply(obj_levels, function(o) {
    sec <- obj[object == o & voice == "sector", .N]
    out <- obj[object == o & voice == "outside", .N]
    n <- sec + out
    sprintf("| %s | %d | %d | %d | %s |", obj_labels[[o]], sec, out, n,
            p_fmt(100 * n / nrow(obj), 1))
  }, character(1))
  md_table("tab8_attention_object.md",
           "Table 8. What the institution-register material attends to, and who speaks.",
           c("Object of economic content", "Sector voice", "Outside report", "Posts", "% of 179"),
           c(" --- ", " ---: ", " ---: ", " ---: ", " ---: "), f8,
           paste0("author's recoding of the 179 posts previously classified as the sector acting ",
                  "or speaking in economic coverage. Labels are three-model majorities. A sector ",
                  "voice is a quotation, interview, homily, official statement or press release; ",
                  "an outside report contains no sector actor speaking."))

  direct_own <- obj[voice == "sector" & object %chin% c("own", "both")]
  direct_hh  <- obj[voice == "sector" & object %chin% c("household", "both")]
  own_peak <- direct_own[, .N, by = month][order(-N, month)][1]
  hh_peak  <- direct_hh[, .N, by = month][order(-N, month)][1]
  D("v2_object_own_n", obj[object == "own", .N])
  D("v2_object_household_n", obj[object == "household", .N])
  D("v2_object_both_n", obj[object == "both", .N])
  D("v2_object_other_n", obj[object == "other", .N])
  D("v2_direct_own_n", nrow(direct_own))
  D("v2_direct_household_n", nrow(direct_hh))
  D("v2_direct_own_pct", p_fmt(100 * nrow(direct_own) / nrow(obj), 1))
  D("v2_own_peak_month", own_peak$month); D("v2_own_peak_n", own_peak$N)
  D("v2_household_peak_month", hh_peak$month); D("v2_household_peak_n", hh_peak$N)
  mid <- function(x) 12L * as.integer(substr(x, 1L, 4L)) + as.integer(substr(x, 6L, 7L))
  D("v2_household_own_lag_months", mid(own_peak$month) - mid(hh_peak$month))
  D("v2_own_repricing_lag_months", mid(event$repricing_peak_month) - mid(own_peak$month))
  D("v2_direct_own_before_repricing_n", direct_own[month < event$repricing_peak_month, .N])

  unit_levels <- c("parish", "diocese", "order", "caritas", "conference",
                   "vatican", "church", "none")
  unit_labels <- c(parish = "Parish", diocese = "Diocese or archdiocese",
                   order = "Religious order or monastery", caritas = "Caritas or relief body",
                   conference = "Bishops' conference", vatican = "Vatican or Pope",
                   church = "Church, no specific unit", none = "No church unit acts")
  ur <- dcast(unitr[!is.na(response)], unit ~ response, value.var = "N", fun.aggregate = sum, fill = 0L)
  for (nm in ORD) if (!nm %in% names(ur)) ur[, (nm) := 0L]
  own_unit <- obj[voice == "sector" & object %chin% c("own", "both"), .N, by = unit]
  ur <- merge(data.table(unit = unit_levels), ur, by = "unit", all.x = TRUE)
  ur <- merge(ur, own_unit, by = "unit", all.x = TRUE)
  setnames(ur, "N", "own_speech")
  ur <- merge(ur, matcht, by = "unit", all.x = TRUE)
  for (j in setdiff(names(ur), "unit")) set(ur, which(is.na(ur[[j]])), j, 0L)
  f9 <- vapply(unit_levels, function(u) {
    z <- ur[unit == u]
    sprintf("| %s | %d | %d | %d | %d | %d |",
            unit_labels[[u]], z$own_speech, z[["Public voice"]], z[["Repricing"]],
            z[["Charitable response"]], z$matched_named_units)
  }, character(1))
  md_table("tab9_units.md",
           "Table 9. Where speech and adjustment are located inside the sector.",
           c("Institutional unit", "Direct own-position speech", "All public voice",
             "Repricing", "Charitable response", "Matched named units"),
           c(" --- ", " ---: ", " ---: ", " ---: ", " ---: ", " ---: "), f9,
           paste0("author's recoding of all 520 posts. Named-unit matches require the same ",
                  "specific unit to speak about its own position before a later repricing report; ",
                  "identifying names remain in the private analysis files. Counts are coverage ",
                  "events, not a census of institutional actions."))

  D("v2_named_units", matchs$named_units)
  D("v2_own_speech_units", matchs$own_speech_units)
  D("v2_repricing_units", matchs$repricing_units)
  D("v2_matched_units", matchs$matched_units)
  D("v2_matched_units_over_year", matchs$matched_units_over_365_days)
  D("v2_median_matched_lag_days", ifelse(is.na(matchs$median_lag_days), "n/a", n_fmt(as.integer(matchs$median_lag_days))))
  D("v2_min_matched_lag_days", ifelse(is.na(matchs$min_lag_days), "n/a", n_fmt(as.integer(matchs$min_lag_days))))
  D("v2_max_matched_lag_days", ifelse(is.na(matchs$max_lag_days), "n/a", n_fmt(as.integer(matchs$max_lag_days))))
  for (i in seq_len(nrow(v2agree))) {
    D(paste0("v2_agree_", v2agree$axis[i]), p_fmt(v2agree$pairwise_agreement[i], 3))
    D(paste0("v2_kappa_", v2agree$axis[i]), p_fmt(v2agree$fleiss_kappa[i], 3))
  }
  D("v2_voice_peak_month", event$voice_peak_month)
  D("v2_repricing_first_month", event$repricing_first_month)
  D("v2_repricing_peak_month", event$repricing_peak_month)
  D("v2_hicp_peak_month", event$hicp_peak_month)
  D("v2_voice_repricing_lag_months", event$voice_to_repricing_months)
  D("v2_hicp_repricing_lag_months", event$hicp_to_repricing_months)
  D("v2_price_gap", p_fmt(event$price_gap_at_repricing_peak, 1))
  D("v2_repricing_peak_share_all", p_fmt(event$repricing_peak_share_all, 1))
  D("v2_repricing_peak_share_2024", p_fmt(event$repricing_peak_share_2024, 1))
}

## -------------------------------------------- other quoted quantities -----

D("span_first", min(ser$month)); D("span_last", max(ser$month))
D("vol_min_monitoring", n_fmt(min(ser[stream == "monitoring"]$n_total)))
D("vol_max_monitoring", n_fmt(max(ser[stream == "monitoring"]$n_total)))
D("hicp_peak", p_fmt(max(hicp$hicp_headline), 1))
D("hicp_peak_month", hicp[which.max(hicp_headline)]$month)
if (!V2) {
  D("conf_rate_monitoring", "0.86"); D("conf_rate_backfill", "0.21")
}
D("n_2024_monitoring_core", sum(core$domestic == 1L & core$year == 2024 & core$stream == "monitoring"))
D("n_2024_backfill_core",   sum(core$domestic == 1L & core$year == 2024 & core$stream == "backfill"))

dv <- rbindlist(DERIVED)
derived_name <- if (V2) "derived_v2.csv" else "derived.csv"
fwrite(dv, file.path(OUT, derived_name))
rule("Derived scalars")
msg("  wrote ", file.path(OUT, derived_name), " with ", nrow(dv), " values")
msg("  every one of these must appear in the manuscript or 10_paper_checks.R fails.")
msg("\ndone.")
