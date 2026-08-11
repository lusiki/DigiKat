#!/usr/bin/env Rscript
# What the 50 read posts imply, measured rather than argued.
#
# Four things are measured here, in this order:
#   1. THE WINDOW. Gate 1 searches the whole FULL_TEXT; gate 2 and every human coder saw only the
#      first 3000 characters. So a post can be admitted on evidence nobody judging it ever saw.
#      Measured on the 50 741-row feed pool and on the read 50.
#   2. PATTERN REPAIRS the errors point at, each measured separately: bozji as a decisive anchor,
#      formulaic bog/bozji, blazen (= blissful), dusa, kaptol (= Zagreb district).
#   3. DENOMINATION. Six of the 50 are religious but not Catholic and gate 2 scores them 0,86-1,00.
#      Measured: can Catholic-specific vocabulary separate them, and what does it cost?
#   4. GATE 2's discrimination on fresh output (AUC on the read 50).
#
# Read-only. Writes only to studies/filter-validation/output/private/.
suppressPackageStartupMessages({library(DBI); library(duckdb); library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"
SEED <- 20260810L; FEED_POOL <- 60000L; CAP <- 3000L
DETERM <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")

# ---- candidate repairs, as text transforms / pattern replacements ------------------------------
# Formulaic uses of Bog that carry no religious content. Croatian speech is full of them.
FORMULA <- paste(c(
  "za ime bo[gž][aej]", "u ime bo[gž]", "hvala bogu", "bogu hvala", "\\bbo[gž]e moj",
  "moj bo[gž]e", "dragi bo[gž]e", "mile bo[gž]e", "ne daj bo[gž]e", "daj bo[gž]e",
  "bog i hrvati", "s bogom", "zbogom", "bog te", "bog zna", "sam bog", "bogu iza nogu",
  "u miru bo[gž]j?[eu]m?", "po[čc]iva[ojl].{0,12}u miru", "bog dao", "kad bog da",
  "mol[eiy].{0,6} boga", "molio boga", "molila boga", "bogom danih?"), collapse = "|")
strip_formula <- function(x) stri_replace_all_regex(x, FORMULA, " ", case_insensitive = TRUE)

# blazeni restricted to what it actually means in Catholic usage: Blessed <Name> / Blazena Djevica.
BLAZ_TIGHT <- "\\bbl\\.\\s|\\bblažen[aeiou][jmz]*\\s+(djevic|[A-ZČĆŽŠĐ])"

hits <- function(txt, terms = v3) digikat_hit_matrix(txt, terms, progress = TRUE)
fires <- function(txt, rx) stri_detect_regex(txt, rx, case_insensitive = TRUE)

# Apply a variant to a hit matrix. Returns logical keep vector.
# drop      = terms removed entirely
# demote    = terms moved decisive -> ambiguous
# override  = named list of logical vectors replacing that term's column
variant <- function(H, drop = character(0), demote = character(0), override = list()) {
  h <- H; tier <- v3$tier; names(tier) <- v3$term
  for (nm in names(override)) h[, which(v3$term == nm)] <- override[[nm]]
  if (length(drop))   h[, v3$term %in% drop] <- FALSE
  if (length(demote)) tier[demote] <- "ambiguous"
  dec <- rowSums(h[, tier == "decisive",  drop = FALSE])
  tot <- rowSums(h)
  dec >= 1L & tot >= 2L
}

## ============================ 1. the population ================================================
CACHE <- file.path(OUT, "repair_pool_cache.rds")
if (file.exists(CACHE)) {
  cat("reusing cached feed pool + hit matrices\n")
  cc <- readRDS(CACHE); g <- cc$g; Hf <- cc$Hf; Hw <- cc$Hw
  n_text <- cc$n_text; n_all <- cc$n_all
} else {
cat("drawing the same feed pool (REPEATABLE seed", SEED, ")...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = DETERM, read_only = TRUE)
g <- dbGetQuery(con, sprintf("
  SELECT CAST(DATE AS VARCHAR) AS date, URL AS url, FULL_TEXT AS text_full
  FROM media_data WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0
  USING SAMPLE reservoir(%d ROWS) REPEATABLE (%d)", FEED_POOL, SEED))
n_text <- dbGetQuery(con, "SELECT COUNT(*) n FROM media_data
                           WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0")$n
n_all  <- dbGetQuery(con, "SELECT COUNT(*) n FROM media_data")$n
dbDisconnect(con, shutdown = TRUE)
cat("pool", nrow(g), "rows | feed rows with text:", format(n_text, big.mark = " "),
    "of", format(n_all, big.mark = " "), "\n")
g$win <- substr(g$text_full, 1, CAP)
g$nchar <- nchar(g$text_full)

cat("\nmatching full text...\n");   Hf <- hits(g$text_full)
cat("matching first 3000 chars...\n"); Hw <- hits(g$win)
saveRDS(list(g = g, Hf = Hf, Hw = Hw, n_text = n_text, n_all = n_all), CACHE)
}
k_full <- variant(Hf); k_win <- variant(Hw)
lost <- k_full & !k_win
cat(sprintf("\ngate 1 on full text     : %d (%.3f%% of rows with text)\n", sum(k_full), 100*mean(k_full)))
cat(sprintf("gate 1 in the window    : %d (%.3f%%)\n", sum(k_win), 100*mean(k_win)))
cat(sprintf("admitted ONLY on evidence beyond char 3000: %d = %.1f%% of gate-1 accepts\n",
            sum(lost), 100*sum(lost)/sum(k_full)))
cat("their length (chars): median", median(g$nchar[lost]), "| vs kept-by-both",
    median(g$nchar[k_win]), "\n")
cat("share of all gate-1 accepts longer than 3000 chars:",
    sprintf("%.1f%%\n", 100*mean(g$nchar[k_full] > CAP)))

## ============================ 2. repairs on the population =====================================
sf <- strip_formula(g$win)
ov <- list(bog   = fires(sf, v3$regex[v3$term == "bog"]),
           božji = fires(sf, v3$regex[v3$term == "božji"]),
           blaženi = fires(g$win, BLAZ_TIGHT))
VAR <- list(
  "v3 as specified (full text)"        = variant(Hf),
  "A window only"                      = variant(Hw),
  "B window + bozji ambiguous"         = variant(Hw, demote = "božji"),
  "C B + formulaic bog/bozji stripped" = variant(Hw, demote = "božji", override = ov[c("bog","božji")]),
  "D C + blazeni tightened"            = variant(Hw, demote = "božji", override = ov),
  "E D + dusa, kaptol dropped"         = variant(Hw, demote = "božji", override = ov,
                                                 drop = c("duša", "kaptol"))
)
pop <- bind_rows(lapply(names(VAR), function(n) data.frame(
  variant = n, kept = sum(VAR[[n]]),
  pct_of_feed = round(100 * mean(VAR[[n]]), 3),
  projected = round(n_text * mean(VAR[[n]])))))
cat("\n=== gate 1 variants on the feed population ===\n"); print(pop, row.names = FALSE)

## ============================ 3. every coded post ==============================================
rd <- function(p, tag) { x <- readRDS(p)
  data.frame(round = tag,
             stratum = if ("stratum" %in% names(x)) as.character(x$stratum) else "OUT",
             label = as.character(x$label),
             title = ifelse(is.na(x$title), "", as.character(x$title)),
             text = substr(as.character(if ("text" %in% names(x)) x$text else x$text_full), 1, CAP),
             stringsAsFactors = FALSE) }
cd <- bind_rows(
  rd(file.path(OUT, "coded.rds"), "r1"),
  rd(file.path(OUT, "holdout_coded.rds"), "r2"),
  rd("data/rebuild/discarded_coded.rds", "r3"),
  rd(file.path(OUT, "pre2024_output_coded.rds"), "r4"))
cd$y <- cd$label == "catholic_clear"
cat("\ncoded posts assembled:", nrow(cd), "| genuine", sum(cd$y), "\n")
print(as.data.frame(table(cd$round, cd$label)))

Hc <- hits(cd$text)
sfc <- strip_formula(cd$text)
ovc <- list(bog   = fires(sfc, v3$regex[v3$term == "bog"]),
            božji = fires(sfc, v3$regex[v3$term == "božji"]),
            blaženi = fires(cd$text, BLAZ_TIGHT))
CVAR <- list(
  "v3 (= A: coded text is already capped)" = variant(Hc),
  "B window + bozji ambiguous"             = variant(Hc, demote = "božji"),
  "C B + formulaic bog/bozji stripped"     = variant(Hc, demote = "božji", override = ovc[c("bog","božji")]),
  "D C + blazeni tightened"                = variant(Hc, demote = "božji", override = ovc),
  "E D + dusa, kaptol dropped"             = variant(Hc, demote = "božji", override = ovc,
                                                    drop = c("duša", "kaptol"))
)
cat("\n=== gate 1 variants on all 1040 coded posts (fitted-pool figures, read as deltas) ===\n")
print(bind_rows(lapply(names(CVAR), function(n) { k <- CVAR[[n]]
  data.frame(variant = n, kept = sum(k), genuine_kept = sum(k & cd$y),
             precision = round(100*sum(k & cd$y)/sum(k), 1),
             recall = round(100*sum(k & cd$y)/sum(cd$y), 1),
             genuine_lost_vs_v3 = sum(CVAR[[1]] & cd$y & !k),
             junk_removed_vs_v3 = sum(CVAR[[1]] & !cd$y & !k)) })), row.names = FALSE)

cat("\n=== the same variants on the 50 read posts (representative of the kept pile) ===\n")
i4 <- cd$round == "r4"
print(bind_rows(lapply(names(CVAR), function(n) { k <- CVAR[[n]][i4]
  data.frame(variant = n, kept = sum(k), genuine = sum(k & cd$y[i4]),
             precision = round(100*sum(k & cd$y[i4])/max(1,sum(k)), 1)) })), row.names = FALSE)

## ============================ 4. denomination ==================================================
# Catholic-specific vocabulary: institutions, offices, sacraments, devotions that only the Catholic
# (and partly Orthodox) church has. Deliberately EXCLUDES the shared Christian core -- Bog, Isus,
# Krist, vjera, molitva, evandelje - which is exactly what fails to discriminate.
CATH <- c("papa","papinstvo","vatikan","vatikanski","sveta stolica","biskup","biskupija",
  "nadbiskup","nadbiskupija","kardinal","zupa","zupnik","kapelan","svecenik","misa","euharistija",
  "sakrament","krizma","ispovijed","krunica","franjevac","franjevci","isusovac","dominikanac",
  "redovnik","redovnica","casna sestra","casne sestre","samostan","katedrala","bazilika","kaptol",
  "hodocasnik","hodocasce","procesija","katolicka crkva","zaredenje","djakon","sveti red",
  "vjeronauk","vjeroucitelj","liturgija","homilija","oltar","relikvija","monsinjor","kapitul",
  "svetkovina","gospa","djevica marija","srce isusovo","pobožnost","klanjanje","krizni put")
CATH <- intersect(c(CATH, "župa","župnik","svećenik","časna sestra","časne sestre","hodočasnik",
  "hodočašće","katolička crkva","zaređenje","đakon","vjeroučitelj","križni put","pobožnost"), v3$term)
OTHER <- paste(c(
  "džamij","imam[ai]?\\b","hafiz","kur'?an","ramazan","medres","džemat","mukabel","muslimansk",
  "islamsk","alahu?\\b","allah","bajram","efendij",
  "pravoslavn","patrijarh","eparhij","protojerej","srpska pravoslavna","mitropolit","ikonostas",
  "pastor[aiu]?\\b","evanđeosk","baptist","adventist","jehovin","pentekost","protestantsk",
  "biblijska škola","kršćanski centar","zajednica vjernika crkve"), collapse = "|")

cath_hit <- rowSums(Hc[, v3$term %in% CATH, drop = FALSE]) > 0
oth_hit  <- fires(cd$text, OTHER)
cat("\n=== does Catholic-specific vocabulary separate the denominations? ===\n")
acc <- CVAR[["E D + dusa, kaptol dropped"]]
tb <- cd[acc, ] |> mutate(cath = cath_hit[acc], oth = oth_hit[acc]) |>
  group_by(label) |> summarise(n = n(), has_catholic_term = sum(cath),
    pct_catholic_term = round(100*mean(cath), 1), has_other_religion_marker = sum(oth),
    .groups = "drop")
print(as.data.frame(tb), row.names = FALSE)

cat("\n=== variant F: require >=1 Catholic-specific term (on top of E) ===\n")
kF <- acc & cath_hit
for (sel in list(all = rep(TRUE, nrow(cd)), r4 = i4)) {
  k <- kF[sel]; y <- cd$y[sel]; k0 <- acc[sel]
  cat(sprintf("  %-4s kept %4d -> %4d | precision %.1f -> %.1f | genuine lost %d of %d\n",
              if (identical(sel, i4)) "r4" else "all", sum(k0), sum(k),
              100*sum(k0&y)/sum(k0), 100*sum(k&y)/max(1,sum(k)), sum(k0&y&!k), sum(k0&y)))
}
cat("\n=== variant G: veto if other-religion markers present and no Catholic term (on top of E) ===\n")
kG <- acc & !(oth_hit & !cath_hit)
for (sel in list(all = rep(TRUE, nrow(cd)), r4 = i4)) {
  k <- kG[sel]; y <- cd$y[sel]; k0 <- acc[sel]
  cat(sprintf("  %-4s kept %4d -> %4d | precision %.1f -> %.1f | genuine lost %d of %d\n",
              if (identical(sel, i4)) "r4" else "all", sum(k0), sum(k),
              100*sum(k0&y)/sum(k0), 100*sum(k&y)/max(1,sum(k)), sum(k0&y&!k), sum(k0&y)))
}

## ============================ 5. gate 2 on fresh output ========================================
r4 <- readRDS(file.path(OUT, "pre2024_output_coded.rds"))
auc <- function(s, y) { r <- rank(s); (sum(r[y]) - sum(y)*(sum(y)+1)/2) / (sum(y)*sum(!y)) }
cat("\n=== gate 2's ability to tell genuine from junk, on the 50 fresh posts ===\n")
cat(sprintf("AUC (catholic_clear vs rest) : %.3f   (0,5 = coin flip)\n", auc(r4$score, r4$clear)))
cat(sprintf("AUC (any religious vs not)   : %.3f\n",
            auc(r4$score, r4$label != "not_religious")))
cat("median score  genuine", round(median(r4$score[r4$clear]), 3),
    "| junk", round(median(r4$score[!r4$clear]), 3), "\n")

## ============================ 6. what the pile looks like ======================================
cat("\n=== honest projection for the pre-2024 rebuild, using measured rates ===\n")
# in-corpus vs new precision, pooling round 2 stratum S2/S3 with round 4's split
s2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
p_in  <- (sum(s2$label[s2$stratum == "S2"] == "catholic_clear") + sum(r4$clear & r4$in_master)) /
         (sum(s2$stratum == "S2") + sum(r4$in_master))
p_new <- (sum(s2$label[s2$stratum == "S3"] == "catholic_clear") + sum(r4$clear & !r4$in_master)) /
         (sum(s2$stratum == "S3") + sum(!r4$in_master))
cat(sprintf("precision, posts already in the corpus : %.1f%% (n = %d)\n", 100*p_in,
            sum(s2$stratum == "S2") + sum(r4$in_master)))
cat(sprintf("precision, material a rebuild would ADD: %.1f%% (n = %d)\n", 100*p_new,
            sum(s2$stratum == "S3") + sum(!r4$in_master)))
share_in <- mean(r4$in_master)
cat(sprintf("of the kept pile, %.1f%% is already in the corpus (from the 1302-post pool)\n",
            100 * readRDS(file.path(OUT, "pre2024_output_sample.rds"))$in_master_rate * 100 / 100))
write.csv(pop, file.path(OUT, "repair_population.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote repair_population.csv\n")
