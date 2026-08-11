#!/usr/bin/env Rscript
# moral-economy — STEP 15: PROPOSED OUTLET LABELS (for PI review; NOT applied to the pipeline).
#
# H4 (doctrine is enclosed in confessional media) is unreportable while 47% of the core set's outlets are
# unlabelled. This proposes labels for the outlets that matter most by volume, and recomputes H4 under them
# so the PI can see what the decision buys before making it.
#
#   Rscript studies/moral-economy/15_propose_source_labels.R
#
# THIS DOES NOT TOUCH resources/dictionaries/source_labels.csv. Changing a tracked dictionary is
# plan-gated (CLAUDE.md), and these labels remain contestable and PI-owned. The output is an unratified
# REVIEW SHEET. Script 17 uses it only in rows explicitly described as proposal-based sensitivity; it is
# not an approved outlet dictionary and must not be presented as one.
#
# CONFIDENCE IS PART OF THE DATA, not a disclaimer:
#   high      institutional identity is unambiguous — a diocese, an order, a national daily, the public
#             broadcaster, the state news agency.
#   medium    the outlet type is clear from its name or market position but I have not verified ownership.
#   uncertain I do not reliably know this outlet. Left UNLABELLED. Do not guess these on my behalf.
#
# THE THIRD CATEGORY MATTERS. Croatian conservative/nationalist portals are religiously inflected without
# being church bodies. Forcing them into "confessional" would inflate H4 by counting political-religious
# media as ecclesial media; forcing them into "secular" would understate how far doctrine travels outside
# church institutions. They go to `other`, which the existing dictionary already uses (32 rows), and the
# paper must report H4 with them excluded AND with them counted as secular, as a sensitivity.
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))
rsp_assert_official_inputs()

OUT <- file.path(ME_PRIVATE, "proposed_source_labels.csv")

p <- function(from, label, confidence, basis, note)
  data.frame(from, label, confidence, basis, note, stringsAsFactors = FALSE)

prop <- rbind(
  # ---- Catholic institutions: dioceses, orders, congregations, parishes -----------------------------
  p("djos.hr",                  "confessional", "high",   "institution", "Đakovačko-osječka nadbiskupija — archdiocese"),
  p("zg-nadbiskupija.hr",       "confessional", "high",   "institution", "Zagrebačka nadbiskupija — archdiocese"),
  p("biskupija-varazdinska.hr", "confessional", "high",   "institution", "Varaždinska biskupija — diocese"),
  p("biskupijakrk.hr",          "confessional", "high",   "institution", "Krčka biskupija — diocese"),
  p("vojni-ordinarijat.hr",     "confessional", "high",   "institution", "Vojni ordinarijat — military ordinariate"),
  p("ofm.hr",                   "confessional", "high",   "institution", "Franciscans (Order of Friars Minor), Croatian province"),
  p("karmel.hr",                "confessional", "high",   "institution", "Carmelites"),
  p("milosrdnice.hr",           "confessional", "high",   "institution", "Sestre milosrdnice — Sisters of Charity"),
  p("redovnistvo.hr",           "confessional", "high",   "institution", "Croatian conference of religious orders"),
  p("zupa-zabok.org",           "confessional", "high",   "institution", "parish website (Zabok)"),
  p("ssmi.hr",                  "confessional", "medium", "institution", "Sestre Služavke Maloga Isusa — religious congregation (abbreviation read from domain)"),

  # ---- Catholic media and publishers ----------------------------------------------------------------
  p("glas-koncila.hr",          "confessional", "high",   "known-outlet", "Glas Koncila — principal Croatian Catholic weekly"),
  p("ks.hr",                    "confessional", "high",   "known-outlet", "Kršćanska sadašnjost — Catholic publishing house"),
  p("unicath.hr",               "confessional", "high",   "known-outlet", "Catholic news portal / Croatian Catholic University orbit"),
  p("radio-medjugorje.com",     "confessional", "high",   "known-outlet", "Medjugorje pilgrimage radio"),
  p("vjeraidjela.com",          "confessional", "high",   "known-outlet", "'Vjera i djela' — Catholic portal"),
  p("hu-benedikt.hr",           "confessional", "high",   "known-outlet", "Hrvatska udruga Benedikt — Catholic association"),
  p("vjeronauk.hr",             "confessional", "high",   "domain-name",  "catechesis / religious-education resource"),
  p("zupcica.hr",               "confessional", "medium", "domain-name",  "parish-oriented site"),
  p("fratellanza.net",          "confessional", "medium", "domain-name",  "'fratellanza' — Catholic fraternity themed"),

  # ---- National / regional general news --------------------------------------------------------------
  p("hrt.hr",             "secular", "high",   "known-outlet", "Hrvatska radiotelevizija — public broadcaster"),
  p("hina.hr",            "secular", "high",   "known-outlet", "HINA — state news agency"),
  p("novilist.hr",        "secular", "high",   "known-outlet", "Novi list — Rijeka daily"),
  p("glas-slavonije.hr",  "secular", "high",   "known-outlet", "Glas Slavonije — Osijek daily"),
  p("glasistre.hr",       "secular", "high",   "known-outlet", "Glas Istre — Pula daily"),
  p("zadarskilist.hr",    "secular", "high",   "known-outlet", "Zadarski list — regional daily"),
  p("nacional.hr",        "secular", "high",   "known-outlet", "Nacional — weekly newsmagazine"),
  p("n1info.hr",          "secular", "high",   "known-outlet", "N1 television"),
  p("n1info.com",         "secular", "high",   "known-outlet", "N1 television (regional domain)"),
  p("poslovni.hr",        "secular", "high",   "known-outlet", "Poslovni dnevnik — business daily"),
  p("autograf.hr",        "secular", "high",   "known-outlet", "Autograf — liberal commentary portal"),
  p("portalnovosti.com",  "secular", "high",   "known-outlet", "Novosti — Serb national minority weekly"),
  p("direktno.hr",        "secular", "medium", "known-outlet", "general news portal"),
  p("dalmacijanews.hr",   "secular", "high",   "known-outlet", "Dalmatian regional news"),
  p("dalmacijadanas.hr",  "secular", "high",   "known-outlet", "Dalmatian regional news"),
  p("prigorski.hr",       "secular", "high",   "known-outlet", "Prigorje regional news"),
  p("dubrovnikinsider.hr","secular", "medium", "known-outlet", "Dubrovnik local news"),
  p("brodportal.hr",      "secular", "medium", "domain-name",  "Slavonski Brod local portal"),
  p("ebrod.net",          "secular", "medium", "domain-name",  "Slavonski Brod local portal"),
  p("sbperiskop.net",     "secular", "medium", "domain-name",  "Slavonski Brod local portal"),
  p("035portal.hr",       "secular", "medium", "domain-name",  "local portal (area code 035, Slavonski Brod)"),
  p("044portal.hr",       "secular", "medium", "domain-name",  "local portal (area code 044, Sisak)"),
  p("zagreb.info",        "secular", "medium", "domain-name",  "Zagreb local news"),
  p("mojzagreb.info",     "secular", "medium", "domain-name",  "Zagreb local news"),
  p("metro-portal.hr",    "secular", "medium", "known-outlet", "general news portal"),
  p("maxportal.hr",       "secular", "medium", "known-outlet", "general news portal"),
  p("klikaj.hr",          "secular", "medium", "known-outlet", "general news portal"),
  p("otvoreno.hr",        "secular", "medium", "known-outlet", "general news portal"),
  p("novine.hr",          "secular", "medium", "known-outlet", "news aggregator/portal"),
  p("crovijesti.com",     "secular", "medium", "known-outlet", "news aggregator"),
  p("glas.hr",            "secular", "medium", "known-outlet", "general news portal"),
  p("hia.com.hr",         "secular", "medium", "known-outlet", "news portal"),
  p("green.hr",           "secular", "medium", "domain-name",  "environmental news — secular NGO/media, not a church body"),
  p("banjalukain.com",    "secular", "medium", "domain-name",  "Banja Luka (BiH) local news"),
  p("ljubuski.net",       "secular", "medium", "domain-name",  "Ljubuški (BiH) local news"),
  p("tomislavnews.com",   "secular", "medium", "domain-name",  "Tomislavgrad (BiH) local news"),

  # ---- Religiously inflected but NOT church bodies — deliberately `other` ------------------------------
  p("hrvatskonebo.org",   "other", "medium", "known-outlet", "conservative/nationalist portal, religiously inflected; not a church body"),
  p("croativ.net",        "other", "medium", "known-outlet", "conservative Croatian portal, religiously inflected; not a church body"),
  p("kamenjar.com",       "other", "medium", "known-outlet", "nationalist portal, religiously inflected; not a church body"),
  p("hkv.hr",             "other", "medium", "known-outlet", "Hrvatsko kulturno vijeće — conservative cultural body, not ecclesial"),
  p("7dnevno.hr",         "other", "medium", "known-outlet", "conservative weekly, religiously inflected"),
  p("hrvatski-fokus.hr",  "other", "medium", "known-outlet", "conservative portal, religiously inflected"),
  p("dragovoljac.com",    "other", "medium", "known-outlet", "veterans'/nationalist portal, religiously inflected"),

  # ---- I do not reliably know these. LEFT UNLABELLED ON PURPOSE. --------------------------------------
  p("smn.hr",             "", "uncertain", "", "not reliably identified — PI to resolve"),
  p("czn.hr",             "", "uncertain", "", "not reliably identified — PI to resolve"),
  p("tabor.hr",           "", "uncertain", "", "ambiguous (Mt Tabor / festival / other) — PI to resolve"),
  p("hteam.org",          "", "uncertain", "", "not reliably identified — PI to resolve"),
  p("mok.hr",             "", "uncertain", "", "not reliably identified — PI to resolve"),
  p("svijetkulture.com",  "", "uncertain", "", "culture portal, affiliation unclear — PI to resolve"),
  p("Zvonimir Despot",    "", "uncertain", "not-an-outlet",
    "this FROM value is a PERSON (journalist), not a publication — the FROM field mixes bylines with outlets; decide how to treat these")
)

stopifnot(!anyDuplicated(prop$from))
write.csv(prop, OUT, row.names = FALSE, fileEncoding = "UTF-8")
cat("Proposed labels:", nrow(prop), "->", OUT, "\n")
print(table(prop$label, prop$confidence))

# ---- what it buys -----------------------------------------------------------------------------------
core <- cst_build_core(verbose = FALSE)
cand <- readRDS(RSP_STAGEA_CANDIDATES); cand$rid <- as.integer(cand$rid)
cd   <- cand[!duplicated(cand$rid), c("rid", "FROM", "label")]
existing <- read.csv(here::here("resources/dictionaries/source_labels.csv"),
                     fileEncoding = "UTF-8", stringsAsFactors = FALSE)

merged <- rbind(existing[nzchar(existing$from), c("from", "label")],
                prop[nzchar(prop$label), c("from", "label")])
merged <- merged[!duplicated(merged$from), ]
lk <- setNames(merged$label, merged$from)

relabel <- function(from) { v <- unname(lk[from]); v[is.na(v)] <- "neoznačeno"; v }
core$label2 <- relabel(core$actor)
cd$label2   <- relabel(cd$FROM)

cat("\n=== core set label coverage ===\n")
cat(sprintf("  before: %.1f%% labelled (confessional/secular)\n",
            100 * mean(core$label %in% c("confessional", "secular"))))
cat(sprintf("  after : %.1f%% labelled, plus %.1f%% 'other'\n",
            100 * mean(core$label2 %in% c("confessional", "secular")),
            100 * mean(core$label2 == "other")))
print(table(core$label2))

bg <- cd[!cd$rid %in% core$rid, ]
h4 <- function(a, b, tag) {
  f <- function(x) { x <- x[x %in% c("confessional", "secular")]
                     c(n = length(x), conf_pct = round(100 * mean(x == "confessional"), 1)) }
  cat("\n", tag, "\n"); print(rbind(core = f(a), background = f(b)))
}
h4(core$label, bg$label, "=== H4 BEFORE (existing labels) ===")
h4(core$label2, bg$label2, "=== H4 AFTER (proposed labels merged) ===")

# sensitivity: count the religiously-inflected `other` portals as secular
as_sec <- function(x) ifelse(x == "other", "secular", x)
h4(as_sec(core$label2), as_sec(bg$label2), "=== H4 SENSITIVITY ('other' counted as secular) ===")
